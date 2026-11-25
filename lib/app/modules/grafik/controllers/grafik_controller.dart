import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class AnomaliModel {
  final String parameter;
  final String waktu;
  final double nilai;
  final String keterangan;

  AnomaliModel({
    required this.parameter,
    required this.waktu,
    required this.nilai,
    required this.keterangan,
  });
}

class DetailMenitModel {
  final String waktu;
  final double nilai;
  final bool isAbnormal;
  final String? keterangan;

  DetailMenitModel({
    required this.waktu,
    required this.nilai,
    required this.isAbnormal,
    this.keterangan,
  });
}

class HourlyData {
  final int hour;
  final double avgValue;
  final bool hasAbnormal;
  final List<DetailMenitModel> rincianMenit;
  final DateTime? fullTimestamp;

  HourlyData({
    required this.hour,
    required this.avgValue,
    required this.hasAbnormal,
    required this.rincianMenit,
    this.fullTimestamp,
  });
}

class ContinuousSpotData {
  final double xIndex; 
  final double value;
  final DateTime timestamp;
  final String dateKey; 

  ContinuousSpotData({
    required this.xIndex,
    required this.value,
    required this.timestamp,
    required this.dateKey,
  });
}

class GrafikController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var isLoading = true.obs;

  // FILTER PERIODE TREN (1 Hari, 7 Hari, 15 Hari, 1 Bulan)
  var selectedRange = '1 Bulan'.obs; 

  // TOGGLE VISIBILITY PARAMETER
  var paramVisibility = <String, bool>{
    'Suhu': true,
    'Kelembapan': true,
    'Nutrisi': true,
    'pH Air': true,
  }.obs;

  void toggleParamVisibility(String paramKey) {
    bool current = paramVisibility[paramKey] ?? true;
    paramVisibility[paramKey] = !current;
  }

  void changeRange(String range) {
    selectedRange.value = range;
    selectedHour.value = null; // Reset detail popup saat ganti mode
    fetchAllGrafikData(selectedDate.value);
  }

  // Threshold
  final double suhuMin = 16.0, suhuMax = 28.0;
  final double lembapMin = 60.0, lembapMax = 75.0;
  final double phMin = 5.8, phMax = 6.3;
  final double nutrisiMin = 1000.0, nutrisiMax = 1500.0;

  var listAnomali = <AnomaliModel>[].obs;

  // Data 1 Hari Utama & Komparasi (Kompatibilitas)
  var suhuHourly = <HourlyData>[].obs;
  var lembapHourly = <HourlyData>[].obs;
  var phHourly = <HourlyData>[].obs;
  var nutrisiHourly = <HourlyData>[].obs;

  var suhuCompareMap = <String, List<HourlyData>>{}.obs;
  var lembapCompareMap = <String, List<HourlyData>>{}.obs;
  var phCompareMap = <String, List<HourlyData>>{}.obs;
  var nutrisiCompareMap = <String, List<HourlyData>>{}.obs;

  var suhuContinuous = <ContinuousSpotData>[].obs;
  var lembapContinuous = <ContinuousSpotData>[].obs;
  var phContinuous = <ContinuousSpotData>[].obs;
  var nutrisiContinuous = <ContinuousSpotData>[].obs;

  var continuousDateLabels = <Map<String, dynamic>>[].obs;

  // VARIABEL DATA SPOTS UNTUK GRAFIK VIEW
  var suhuSpots = <double>[].obs;
  var lembapSpots = <double>[].obs;
  var phSpots = <double>[].obs;
  var nutrisiSpots = <double>[].obs;
  var dateLabelsX = <int, String>{}.obs;

  var selectedHour = Rxn<double>();

  StreamSubscription<DatabaseEvent>? _grafikSubscription;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://growsense-83ff2-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void onInit() {
    super.onInit();
    fetchAllGrafikData(selectedDate.value);
  }

  void gantiTanggal(DateTime tanggalBaru) {
    selectedDate.value = tanggalBaru;
    selectedHour.value = null;
    fetchAllGrafikData(tanggalBaru);
  }

  bool _nilaiValid(String dbKey, double nilai) {
    switch (dbKey) {
      case 'suhu': return nilai > -10 && nilai < 60;
      case 'kelembapan': return nilai >= 0 && nilai <= 100;
      case 'ph': return nilai >= 0 && nilai <= 14;
      case 'nutrisi': return nilai >= 0 && nilai <= 5000;
      default: return true;
    }
  }

  Map<String, String>? _evaluasiParameter(String jenis, double val) {
    switch (jenis) {
      case 'suhu':
        if (val < suhuMin) return {"status": "DINGIN (< $suhuMin °C)"};
        if (val > suhuMax) return {"status": "PANAS (> $suhuMax °C)"};
        break;
      case 'kelembapan':
        if (val < lembapMin) return {"status": "KERING (< $lembapMin %)"};
        if (val > lembapMax) return {"status": "LEMBAP (> $lembapMax %)"};
        break;
      case 'ph':
        if (val < phMin) return {"status": "ASAM (< $phMin)"};
        if (val > phMax) return {"status": "BASA (> $phMax)"};
        break;
      case 'nutrisi':
        if (val < nutrisiMin) return {"status": "RENDAH (< $nutrisiMin PPM)"};
        if (val > nutrisiMax) return {"status": "TINGGI (> $nutrisiMax PPM)"};
        break;
    }
    return null;
  }

  void fetchAllGrafikData(DateTime targetDate) {
    isLoading.value = true;
    _grafikSubscription?.cancel();

    _grafikSubscription = _dbRef.child("riwayat_sensor").onValue.listen((event) {
      try {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          _clearAllData();
          isLoading.value = false;
          return;
        }

        final dataMentah = event.snapshot.value;
        List<AnomaliModel> tempAnomali = [];

        int totalPoint = 30;
        if (selectedRange.value == '1 Hari') totalPoint = 24;
        if (selectedRange.value == '7 Hari') totalPoint = 7;
        if (selectedRange.value == '15 Hari') totalPoint = 15;
        if (selectedRange.value == '1 Bulan') {
          // Jumlah hari persis dalam bulan kalender terpilih (28, 29, 30, atau 31 hari)
          totalPoint = DateTime(targetDate.year, targetDate.month + 1, 0).day;
        }

        Map<int, List<double>> mSuhu = {for (var i = 1; i <= totalPoint; i++) i: []};
        Map<int, List<double>> mLembap = {for (var i = 1; i <= totalPoint; i++) i: []};
        Map<int, List<double>> mPh = {for (var i = 1; i <= totalPoint; i++) i: []};
        Map<int, List<double>> mNutrisi = {for (var i = 1; i <= totalPoint; i++) i: []};
        Map<int, String> tempLabels = {};

        // INISIALISASI LABEL SUMBU X
        if (selectedRange.value == '1 Hari') {
          for (int h = 0; h < 24; h++) {
            tempLabels[h + 1] = '${h.toString().padLeft(2, '0')}:00';
          }
        } else if (selectedRange.value == '1 Bulan') {
          // Label murni nomor tanggal kalender (Tgl 1 - Tgl 30/31)
          for (int d = 1; d <= totalPoint; d++) {
            tempLabels[d] = "Tgl $d";
          }
        } else { // 7 Hari atau 15 Hari Mundur dari Tanggal Pilihan
          for (int i = 0; i < totalPoint; i++) {
            DateTime d = targetDate.subtract(Duration(days: (totalPoint - 1) - i));
            tempLabels[i + 1] = DateFormat('dd/MM').format(d);
          }
        }
        dateLabelsX.assignAll(tempLabels);

        if (dataMentah is Map) {
          dataMentah.forEach((key, value) {
            if (value is Map) {
              DateTime? recordTime;
              var timeVal = value['timestamp_server'] ?? value['timestamp_esp32'] ?? value['timestamp'];

              if (timeVal != null) {
                int? epoch = switch (timeVal) {
                  int v => v,
                  double v => v.toInt(),
                  String v => int.tryParse(v) ?? double.tryParse(v)?.toInt(),
                  _ => null,
                };

                if (epoch != null) {
                  recordTime = epoch.toString().length == 10
                      ? DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true).toLocal()
                      : DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true).toLocal();
                }
              }

              if (recordTime == null && value['waktu_lokal'] != null) {
                try {
                  recordTime = DateTime.parse(value['waktu_lokal'].toString());
                } catch (_) {}
              }

              if (recordTime != null) {
                int targetIndex = -1;

                if (selectedRange.value == '1 Hari') {
                  if (recordTime.year == targetDate.year &&
                      recordTime.month == targetDate.month &&
                      recordTime.day == targetDate.day) {
                    targetIndex = recordTime.hour + 1; // Slot Jam 00:00 - 23:00 (1 - 24)
                  }
                } else if (selectedRange.value == '1 Bulan') {
                  // 🔥 MURNI FILTER PER BULAN KALENDER (1 s.d. Tanggal Terakhir Bulan)
                  if (recordTime.year == targetDate.year && recordTime.month == targetDate.month) {
                    targetIndex = recordTime.day; // Slot Tanggal Asli (1 - 31)
                  }
                } else { // 7 Hari atau 15 Hari
                  for (int i = 0; i < totalPoint; i++) {
                    DateTime dayCheck = targetDate.subtract(Duration(days: (totalPoint - 1) - i));
                    if (recordTime.year == dayCheck.year &&
                        recordTime.month == dayCheck.month &&
                        recordTime.day == dayCheck.day) {
                      targetIndex = i + 1;
                      break;
                    }
                  }
                }

                if (targetIndex >= 1 && targetIndex <= totalPoint) {
                  String jamFormat = DateFormat('HH:mm').format(recordTime);

                  if (value['suhu'] != null) {
                    double n = double.tryParse(value['suhu'].toString()) ?? 0.0;
                    if (_nilaiValid('suhu', n)) {
                      mSuhu[targetIndex]?.add(n);
                      var eval = _evaluasiParameter('suhu', n);
                      if (eval != null) _addAnomali(tempAnomali, 'Suhu', jamFormat, n, eval['status']!);
                    }
                  }

                  if (value['kelembapan'] != null) {
                    double n = double.tryParse(value['kelembapan'].toString()) ?? 0.0;
                    if (_nilaiValid('kelembapan', n)) {
                      mLembap[targetIndex]?.add(n);
                      var eval = _evaluasiParameter('kelembapan', n);
                      if (eval != null) _addAnomali(tempAnomali, 'Kelembapan', jamFormat, n, eval['status']!);
                    }
                  }

                  if (value['ph'] != null) {
                    double n = double.tryParse(value['ph'].toString()) ?? 0.0;
                    if (_nilaiValid('ph', n)) {
                      mPh[targetIndex]?.add(n);
                      var eval = _evaluasiParameter('ph', n);
                      if (eval != null) _addAnomali(tempAnomali, 'pH Air', jamFormat, n, eval['status']!);
                    }
                  }

                  if (value['nutrisi'] != null) {
                    double n = double.tryParse(value['nutrisi'].toString()) ?? 0.0;
                    if (_nilaiValid('nutrisi', n)) {
                      mNutrisi[targetIndex]?.add(n);
                      var eval = _evaluasiParameter('nutrisi', n);
                      if (eval != null) _addAnomali(tempAnomali, 'Nutrisi', jamFormat, n, eval['status']!);
                    }
                  }
                }
              }
            }
          });
        }

        suhuSpots.assignAll(_hitungAvg(mSuhu, totalPoint));
        lembapSpots.assignAll(_hitungAvg(mLembap, totalPoint));
        phSpots.assignAll(_hitungAvg(mPh, totalPoint));
        nutrisiSpots.assignAll(_hitungAvg(mNutrisi, totalPoint));

        listAnomali.assignAll(tempAnomali);
        isLoading.value = false;
      } catch (e) {
        developer.log("Error Grafik", name: "GrafikController", error: e);
        isLoading.value = false;
      }
    });
  }

  List<double> _hitungAvg(Map<int, List<double>> mapData, int total) {
    List<double> res = List.filled(total, 0.0);
    for (int i = 1; i <= total; i++) {
      List<double>? list = mapData[i];
      if (list != null && list.isNotEmpty) {
        double avg = list.reduce((a, b) => a + b) / list.length;
        res[i - 1] = double.parse(avg.toStringAsFixed(1));
      }
    }
    return res;
  }

  void _addAnomali(List<AnomaliModel> list, String param, String jam, double val, String ket) {
    list.add(AnomaliModel(parameter: param, waktu: jam, nilai: val, keterangan: ket));
  }

  List<double> get suhu30Days => suhuSpots;
  List<double> get lembap30Days => lembapSpots;
  List<double> get ph30Days => phSpots;
  List<double> get nutrisi30Days => nutrisiSpots;

  void _clearAllData() {
    listAnomali.clear();
    suhuHourly.clear();
    lembapHourly.clear();
    phHourly.clear();
    nutrisiHourly.clear();

    suhuCompareMap.clear();
    lembapCompareMap.clear();
    phCompareMap.clear();
    nutrisiCompareMap.clear();

    suhuContinuous.clear();
    lembapContinuous.clear();
    phContinuous.clear();
    nutrisiContinuous.clear();
    continuousDateLabels.clear();

    suhuSpots.clear();
    lembapSpots.clear();
    phSpots.clear();
    nutrisiSpots.clear();
    dateLabelsX.clear();
  }

  @override
  void onClose() {
    _grafikSubscription?.cancel();
    super.onClose();
  }
}