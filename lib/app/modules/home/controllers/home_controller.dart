import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../data/models/sensor_model.dart';
import '../../../data/providers/sensor_provider.dart';
import '../../../data/providers/google_drive_provider.dart';

class ChatLogItem {
  final String judul;
  final String deskripsi;
  final String status;
  final String color;
  final String jam;

  ChatLogItem({
    required this.judul,
    required this.deskripsi,
    required this.status,
    required this.color,
    required this.jam,
  });
}

class HomeController extends GetxController {
  final SensorProvider _sensorProvider = SensorProvider();
  final GoogleDriveProvider _driveProvider = GoogleDriveProvider();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  StreamSubscription<SensorModel>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _pengaturanSubscription;

  var isUploadingToDrive = false.obs;

  var lastUpdateTime = "-".obs;
  var suhuValue = "0.0".obs;
  var suhuStatus = "Normal".obs;
  var suhuStatusColor = Colors.green.obs;

  var lembapValue = "0.0".obs;
  var lembapStatus = "Normal".obs;
  var lembapStatusColor = Colors.green.obs;

  var nutrisiValue = "0".obs;
  var nutrisiStatus = "Normal".obs;
  var nutrisiStatusColor = Colors.green.obs;

  var phValue = "0.0".obs;
  var phStatus = "Normal".obs;
  var phStatusColor = Colors.green.obs;

  var faseAktif = 'semai'.obs;
  var namaFaseAktif = 'Seedling'.obs;
  var nutrisiMinAktif = 400.0.obs;
  var nutrisiMaxAktif = 600.0.obs;

  var semaiMin = 400.obs;
  var semaiMax = 600.obs;
  var vegAwalMin = 600.obs;
  var vegAwalMax = 750.obs;
  var vegLanjutanMin = 750.obs;
  var vegLanjutanMax = 1000.obs;

  var suhuMin = 16.0.obs;
  var suhuMax = 28.0.obs;
  var lembapMin = 60.0.obs;
  var lembapMax = 75.0.obs;
  var phMin = 5.8.obs;
  var phMax = 6.3.obs;

  var chatLogs = <ChatLogItem>[].obs;

  String _lastNotifiedSignature = "";

  @override
  void onInit() {
    super.onInit();
    _listenPengaturanFirebase();
    _listenRealtimeSensor();
  }

  @override
  void onClose() {
    _sensorSubscription?.cancel();
    _pengaturanSubscription?.cancel();
    super.onClose();
  }

  void _listenPengaturanFirebase() {
    _pengaturanSubscription?.cancel();
    _pengaturanSubscription = _dbRef.child('pengaturan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;

        if (data['suhuMin'] != null) suhuMin.value = double.parse(data['suhuMin'].toString());
        if (data['suhuMax'] != null) suhuMax.value = double.parse(data['suhuMax'].toString());
        if (data['lembapMin'] != null) lembapMin.value = double.parse(data['lembapMin'].toString());
        if (data['lembapMax'] != null) lembapMax.value = double.parse(data['lembapMax'].toString());
        if (data['phMin'] != null) phMin.value = double.parse(data['phMin'].toString());
        if (data['phMax'] != null) phMax.value = double.parse(data['phMax'].toString());

        if (data['fase'] != null) {
          var fData = data['fase'];
          if (fData['semai'] != null) {
            semaiMin.value = int.tryParse(fData['semai']['nutrisiMin'].toString()) ?? 400;
            semaiMax.value = int.tryParse(fData['semai']['nutrisiMax'].toString()) ?? 600;
          }
          if (fData['veg_awal'] != null) {
            vegAwalMin.value = int.tryParse(fData['veg_awal']['nutrisiMin'].toString()) ?? 600;
            vegAwalMax.value = int.tryParse(fData['veg_awal']['nutrisiMax'].toString()) ?? 750;
          }
          if (fData['veg_lanjutan'] != null) {
            vegLanjutanMin.value = int.tryParse(fData['veg_lanjutan']['nutrisiMin'].toString()) ?? 750;
            vegLanjutanMax.value = int.tryParse(fData['veg_lanjutan']['nutrisiMax'].toString()) ?? 1000;
          }
        }

        String fase = data['faseAktif'] ?? 'semai';
        faseAktif.value = fase;

        if (data['fase'] != null && data['fase'][fase] != null) {
          var detailFase = data['fase'][fase];

          nutrisiMinAktif.value = double.parse((detailFase['nutrisiMin'] ?? 400).toString());
          nutrisiMaxAktif.value = double.parse((detailFase['nutrisiMax'] ?? 600).toString());

          if (fase == 'semai') {
            namaFaseAktif.value = 'Seedling';
          } else if (fase == 'veg_awal') {
            namaFaseAktif.value = 'Early Vegetative';
          } else if (fase == 'veg_lanjutan') {
            namaFaseAktif.value = 'Late Vegetative';
          } else {
            namaFaseAktif.value = detailFase['nama'] ?? fase;
          }
        }

        double cSuhu = double.tryParse(suhuValue.value) ?? 0.0;
        double cLembap = double.tryParse(lembapValue.value) ?? 0.0;
        double cPh = double.tryParse(phValue.value) ?? 0.0;
        int cNutrisi = int.tryParse(nutrisiValue.value) ?? 0;

        _evaluasiStatusSuhu(cSuhu);
        _evaluasiStatusLembap(cLembap);
        _evaluasiStatusPh(cPh);
        _evaluasiStatusNutrisi(cNutrisi);
      }
    }, onError: (error) {
      debugPrint("🚨 Realtime Settings Error: $error");
    });
  }

  Future<void> gantiFase(String faseBaru) async {
    String labelFase = switch (faseBaru) {
      'semai' => 'SEEDLING',
      'veg_awal' => 'EARLY VEGETATIVE',
      'veg_lanjutan' => 'LATE VEGETATIVE',
      _ => faseBaru.replaceAll('_', ' ').toUpperCase(),
    };

    try {
      await _dbRef.child('pengaturan').update({
        'faseAktif': faseBaru,
      });
      Get.snackbar(
        'Success',
        'Nutrient phase updated to $labelFase!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Failed',
        'Failed to change phase: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> updateBatasUmum({
    required double sMin,
    required double sMax,
    required double lMin,
    required double lMax,
    required double pMin,
    required double pMax,
  }) async {
    try {
      await _dbRef.child('pengaturan').update({
        'suhuMin': sMin,
        'suhuMax': sMax,
        'lembapMin': lMin,
        'lembapMax': lMax,
        'phMin': pMin,
        'phMax': pMax,
      });
    } catch (e) {
      debugPrint("Failed to update general thresholds: $e");
    }
  }

  Future<void> updateBatasNutrisiFase({
    required String targetFase,
    required int nMin,
    required int nMax,
  }) async {
    try {
      await _dbRef.child('pengaturan/fase/$targetFase').update({
        'nutrisiMin': nMin,
        'nutrisiMax': nMax,
      });

      if (targetFase == 'semai') {
        semaiMin.value = nMin;
        semaiMax.value = nMax;
      } else if (targetFase == 'veg_awal') {
        vegAwalMin.value = nMin;
        vegAwalMax.value = nMax;
      } else if (targetFase == 'veg_lanjutan') {
        vegLanjutanMin.value = nMin;
        vegLanjutanMax.value = nMax;
      }
    } catch (e) {
      debugPrint("Failed to update phase $targetFase: $e");
    }
  }

  void _listenRealtimeSensor() {
    _sensorSubscription?.cancel();

    _sensorSubscription = _sensorProvider.getRealtimeSensorStream().listen(
      (SensorModel sensor) {
        double suhu = sensor.suhu;
        suhuValue.value = suhu == -99 ? "-99" : suhu.toStringAsFixed(1);
        _evaluasiStatusSuhu(suhu);

        double lembap = sensor.kelembapan;
        lembapValue.value = lembap == -99 ? "-99" : lembap.toStringAsFixed(1);
        _evaluasiStatusLembap(lembap);

        double ph = sensor.ph;
        phValue.value = ph == -99 ? "-99" : ph.toStringAsFixed(1);
        _evaluasiStatusPh(ph);

        int nutrisi = sensor.nutrisi;
        nutrisiValue.value = nutrisi.toString();
        _evaluasiStatusNutrisi(nutrisi);

        lastUpdateTime.value = sensor.waktuLokal;

        _tambahLiveChatLog(sensor.waktuLokal);
        _evaluasiNotifikasiAnomali(sensor.waktuLokal);
      },
      onError: (error) {
        debugPrint("🚨 Realtime Sensor Error: $error");
      },
    );
  }

  void _tambahLiveChatLog(String waktuDataAsli) {
    final info = kesimpulanKondisi;

    String jamData = waktuDataAsli;
    if (waktuDataAsli.contains(" ")) {
      jamData = waktuDataAsli.split(" ").last;
    }

    ChatLogItem pesanBaru = ChatLogItem(
      judul: info["judul"] ?? "System Status",
      deskripsi: info["deskripsi"] ?? "",
      status: info["status"] ?? "NORMAL",
      color: info["color"] ?? "green",
      jam: jamData,
    );

    chatLogs.add(pesanBaru);

    if (chatLogs.length > 5) {
      chatLogs.removeAt(0);
    }
  }

  void _evaluasiNotifikasiAnomali(String waktuData) {
    final info = kesimpulanKondisi;
    String color = info["color"] ?? "green";

    if (color == "red" || color == "orange") {
      String currentSignature = "${info["judul"]}_${info["deskripsi"]}";

      if (_lastNotifiedSignature != currentSignature) {
        _lastNotifiedSignature = currentSignature;

        String judul = info["judul"] ?? "Anomaly Alert";
        String pesan = info["deskripsi"] ?? "Plant parameters exceed normal thresholds.";

        _simpanKeFirebaseLogNotifikasi(judul, pesan, waktuData);
      }
    } else {
      _lastNotifiedSignature = "";
    }
  }

  Future<void> _simpanKeFirebaseLogNotifikasi(String judul, String pesan, String timestamp) async {
    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref('log_notifikasi');
      int nowMs = DateTime.now().millisecondsSinceEpoch;

      await dbRef.push().set({
        'judul': judul,
        'pesan': pesan,
        'timestamp': timestamp,
        'fase': namaFaseAktif.value,
        'waktuMs': nowMs,
      });
      debugPrint("✅ Anomaly successfully recorded to Firebase log_notifikasi!");
    } catch (e) {
      debugPrint("❌ Failed to record log_notifikasi: $e");
    }
  }

  Future<void> sinkronkanKeDriveManual({bool isSilent = false}) async {
    try {
      if (!isSilent) {
        isUploadingToDrive.value = true;
        Get.snackbar(
          "Connecting",
          "Uploading log_growsense_v2.csv to Google Drive...",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade700,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      await _driveProvider.initGoogleDriveOnce();
      await _driveProvider.uploadFileCsvLokal();

      if (!isSilent) {
        Get.snackbar(
          "Success",
          "All CSV history data has been synced to Google Drive!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (!isSilent) {
        Get.snackbar(
          "Sync Failed",
          "An error occurred during upload: $e",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } finally {
      if (!isSilent) isUploadingToDrive.value = false;
    }
  }

  void _evaluasiStatusSuhu(double val) {
    if (val == -99 || val < -50) {
      suhuStatus.value = "OFF / FAULT";
      suhuStatusColor.value = Colors.grey;
    } else if (val < suhuMin.value) {
      suhuStatus.value = "Cold";
      suhuStatusColor.value = Colors.red;
    } else if (val > suhuMax.value) {
      suhuStatus.value = "Hot";
      suhuStatusColor.value = Colors.red;
    } else {
      suhuStatus.value = "Normal";
      suhuStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusLembap(double val) {
    if (val == -99 || val < 0) {
      lembapStatus.value = "OFF / FAULT";
      lembapStatusColor.value = Colors.grey;
    } else if (val < lembapMin.value) {
      lembapStatus.value = "Dry";
      lembapStatusColor.value = Colors.red;
    } else if (val > lembapMax.value) {
      lembapStatus.value = "Humid";
      lembapStatusColor.value = Colors.red;
    } else {
      lembapStatus.value = "Normal";
      lembapStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusPh(double val) {
    if (val == -99 || val < 0) {
      phStatus.value = "OFF / FAULT";
      phStatusColor.value = Colors.grey;
    } else if (val < phMin.value) {
      phStatus.value = "Acidic";
      phStatusColor.value = Colors.red;
    } else if (val > phMax.value) {
      phStatus.value = "Alkaline";
      phStatusColor.value = Colors.red;
    } else {
      phStatus.value = "Normal";
      phStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusNutrisi(int val) {
    if (val == -99 || val < 0) {
      nutrisiStatus.value = "OFF / FAULT";
      nutrisiStatusColor.value = Colors.grey;
    } else if (val < nutrisiMinAktif.value) {
      nutrisiStatus.value = "Low";
      nutrisiStatusColor.value = Colors.red;
    } else if (val > nutrisiMaxAktif.value) {
      nutrisiStatus.value = "High";
      nutrisiStatusColor.value = Colors.red;
    } else {
      nutrisiStatus.value = "Normal";
      nutrisiStatusColor.value = Colors.green;
    }
  }

  Map<String, dynamic> getSuhuInfo() {
    double val = double.tryParse(suhuValue.value) ?? 0;
    if (val == -99 || val < -50) {
      return {
        "status": "OFF / FAULT",
        "color": Colors.grey,
        "dampak": "Temperature sensor disconnected.",
        "penanganan": "Check wiring or temperature sensor."
      };
    } else if (val < suhuMin.value) {
      return {
        "status": "COLD",
        "color": Colors.red,
        "dampak": "Temp below target (< ${suhuMin.value}°C). Slow growth.",
        "penanganan": "Turn on heater / adjust room temperature."
      };
    } else if (val > suhuMax.value) {
      return {
        "status": "HOT",
        "color": Colors.red,
        "dampak": "Temp above target (> ${suhuMax.value}°C). Heat stress.",
        "penanganan": "Turn on cooling fan."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Optimal & healthy growth (${suhuMin.value} - ${suhuMax.value}°C).",
        "penanganan": "Maintain current condition."
      };
    }
  }

  Map<String, dynamic> getLembapInfo() {
    double val = double.tryParse(lembapValue.value) ?? 0;
    if (val == -99 || val < 0) {
      return {
        "status": "OFF / FAULT",
        "color": Colors.grey,
        "dampak": "Humidity sensor disrupted.",
        "penanganan": "Check humidity sensor connection."
      };
    } else if (val < lembapMin.value) {
      return {
        "status": "DRY",
        "color": Colors.red,
        "dampak": "Humidity below target (< ${lembapMin.value}%). Leaves drying.",
        "penanganan": "Turn on humidifier."
      };
    } else if (val > lembapMax.value) {
      return {
        "status": "HUMID",
        "color": Colors.red,
        "dampak": "Humidity above target (> ${lembapMax.value}%). Prone to fungus.",
        "penanganan": "Turn on exhaust fan / ventilation."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Balanced transpiration (${lembapMin.value} - ${lembapMax.value}%).",
        "penanganan": "Maintain condition."
      };
    }
  }

  Map<String, dynamic> getNutrisiInfo() {
    double val = double.tryParse(nutrisiValue.value) ?? 0;
    int minBatas = nutrisiMinAktif.value.toInt();
    int maxBatas = nutrisiMaxAktif.value.toInt();

    if (val == -99 || val < 0) {
      return {
        "status": "OFF / FAULT",
        "color": Colors.grey,
        "dampak": "Nutrient/TDS sensor disconnected.",
        "penanganan": "Clean or calibrate TDS probe."
      };
    } else if (val < minBatas) {
      return {
        "status": "LOW",
        "color": Colors.red,
        "dampak": "Nutrient below ${namaFaseAktif.value} target (< $minBatas ppm). Stunted leaves.",
        "penanganan": "Add concentrated AB Mix."
      };
    } else if (val > maxBatas) {
      return {
        "status": "HIGH",
        "color": Colors.red,
        "dampak": "Nutrient exceeds ${namaFaseAktif.value} target (> $maxBatas ppm). Root burn.",
        "penanganan": "Add fresh water to reservoir."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Ideal nutrition for ${namaFaseAktif.value} ($minBatas - $maxBatas ppm).",
        "penanganan": "Maintain nutrient level."
      };
    }
  }

  Map<String, dynamic> getPhInfo() {
    double val = double.tryParse(phValue.value) ?? 0;
    if (val == -99 || val < 0) {
      return {
        "status": "OFF / FAULT",
        "color": Colors.grey,
        "dampak": "pH sensor malfunction.",
        "penanganan": "Recalibrate pH probe."
      };
    } else if (val < phMin.value) {
      return {
        "status": "ACIDIC",
        "color": Colors.red,
        "dampak": "pH below target (< ${phMin.value}). Root damage.",
        "penanganan": "Add pH Up solution."
      };
    } else if (val > phMax.value) {
      return {
        "status": "ALKALINE",
        "color": Colors.red,
        "dampak": "pH above target (> ${phMax.value}). Poor nutrient uptake.",
        "penanganan": "Add pH Down solution."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Maximum nutrient absorption (${phMin.value} - ${phMax.value}).",
        "penanganan": "Maintain pH level."
      };
    }
  }

  Map<String, String> get kesimpulanKondisi {
    String sStatus = suhuStatus.value.toUpperCase();
    String lStatus = lembapStatus.value.toUpperCase();
    String nStatus = nutrisiStatus.value.toUpperCase();
    String pStatus = phStatus.value.toUpperCase();

    List<String> sensorOffline = [];
    if (sStatus.contains('OFF') || sStatus.contains('FAULT')) sensorOffline.add("Temperature");
    if (lStatus.contains('OFF') || lStatus.contains('FAULT')) sensorOffline.add("Humidity");
    if (nStatus.contains('OFF') || nStatus.contains('FAULT')) sensorOffline.add("Nutrient");
    if (pStatus.contains('OFF') || pStatus.contains('FAULT')) sensorOffline.add("Water pH");

    if (sensorOffline.isNotEmpty) {
      String daftarOffline = sensorOffline.join(", ");
      return {
        "judul": "Warning: Sensor Disconnected!",
        "deskripsi": "$daftarOffline sensor detected offline / disconnected. Please check module cable connections immediately.",
        "status": "OFFLINE",
        "color": "red"
      };
    }

    if (sStatus == 'NORMAL' && lStatus == 'NORMAL' && nStatus == 'NORMAL' && pStatus == 'NORMAL') {
      return {
        "judul": "Optimal Plant Condition",
        "deskripsi": "All parameters are ideal for the ${namaFaseAktif.value} phase. Plants are growing healthily.",
        "status": "HEALTHY",
        "color": "green"
      };
    }

    List<String> masalahList = [];
    if (sStatus == 'HOT' || sStatus == 'HIGH') masalahList.add("temperature is too hot");
    if (sStatus == 'COLD' || sStatus == 'LOW') masalahList.add("temperature is too cold");
    if (lStatus == 'HUMID' || lStatus == 'HIGH') masalahList.add("humidity is too high");
    if (lStatus == 'DRY' || lStatus == 'LOW') masalahList.add("humidity is too dry");
    if (nStatus == 'HIGH') masalahList.add("excessive nutrient concentration (${namaFaseAktif.value} phase)");
    if (nStatus == 'LOW') masalahList.add("nutrient deficiency (${namaFaseAktif.value} phase)");
    if (pStatus == 'ALKALINE' || pStatus == 'HIGH') masalahList.add("water pH is too alkaline");
    if (pStatus == 'ACIDIC' || pStatus == 'LOW') masalahList.add("water pH is too acidic");

    if (masalahList.isNotEmpty) {
      String gabunganMasalah = masalahList.join(", ");
      bool kritis = masalahList.length >= 3;

      return {
        "judul": kritis ? "Critical Plant Condition!" : "Plant Condition Needs Attention",
        "deskripsi": "Plants are experiencing issues because $gabunganMasalah. Please adjust parameters immediately.",
        "status": kritis ? "DANGER" : "WARNING",
        "color": kritis ? "red" : "orange"
      };
    }

    return {
      "judul": "Normal Status",
      "deskripsi": "System is actively monitoring plant conditions.",
      "status": "NORMAL",
      "color": "green"
    };
  }
}