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

  // 🔴 REAKTIF UNTUK FASE NUTRISI AKTIF 🔴
  var faseAktif = 'semai'.obs;
  var namaFaseAktif = 'Semai'.obs;
  var nutrisiMinAktif = 400.0.obs;
  var nutrisiMaxAktif = 600.0.obs;

  // 🔴 REAKTIF UNTUK BATAS PPM MASING-MASING FASE (DROPDOWN DINAMIS) 🔴
  var semaiMin = 400.obs;
  var semaiMax = 600.obs;
  var vegAwalMin = 600.obs;
  var vegAwalMax = 750.obs;
  var vegLanjutanMin = 750.obs;
  var vegLanjutanMax = 1000.obs;

  // 🔴 REAKTIF UNTUK BATAS AMBANG SENSOR UMUM (SUHU, LEMBAP, PH) 🔴
  var suhuMin = 16.0.obs;
  var suhuMax = 28.0.obs;
  var lembapMin = 60.0.obs;
  var lembapMax = 75.0.obs;
  var phMin = 5.8.obs;
  var phMax = 6.3.obs;

  var chatLogs = <ChatLogItem>[].obs;

  // Penanda untuk mencegah spaming pencatatan log anomali yang sama
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

  // 🔴 MENDENGARKAN NODE PENGATURAN & FASE DARI FIREBASE 🔴
  void _listenPengaturanFirebase() {
    _pengaturanSubscription?.cancel();
    _pengaturanSubscription = _dbRef.child('pengaturan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;

        // 1. Ambil batas umum (Suhu, Lembap, pH) dari Firebase
        if (data['suhuMin'] != null) suhuMin.value = double.parse(data['suhuMin'].toString());
        if (data['suhuMax'] != null) suhuMax.value = double.parse(data['suhuMax'].toString());
        if (data['lembapMin'] != null) lembapMin.value = double.parse(data['lembapMin'].toString());
        if (data['lembapMax'] != null) lembapMax.value = double.parse(data['lembapMax'].toString());
        if (data['phMin'] != null) phMin.value = double.parse(data['phMin'].toString());
        if (data['phMax'] != null) phMax.value = double.parse(data['phMax'].toString());

        // 2. Ambil batas per fase untuk memperbarui teks Dropdown secara dinamis
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

        // 3. Ambil nama key fase yang aktif (default: semai)
        String fase = data['faseAktif'] ?? 'semai';
        faseAktif.value = fase;

        // 4. Ambil detail batas nutrisi sesuai fase aktif
        if (data['fase'] != null && data['fase'][fase] != null) {
          var detailFase = data['fase'][fase];

          nutrisiMinAktif.value = double.parse((detailFase['nutrisiMin'] ?? 400).toString());
          nutrisiMaxAktif.value = double.parse((detailFase['nutrisiMax'] ?? 600).toString());

          if (fase == 'semai') {
            namaFaseAktif.value = 'Semai';
          } else if (fase == 'veg_awal') {
            namaFaseAktif.value = 'Vegetatif Awal';
          } else if (fase == 'veg_lanjutan') {
            namaFaseAktif.value = 'Vegetatif Lanjutan';
          } else {
            namaFaseAktif.value = detailFase['nama'] ?? fase;
          }
        }

        // Evaluasi ulang seluruh status sensor terkini saat ambang batas diperbarui
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
      debugPrint("🚨 Error Realtime Pengaturan: $error");
    });
  }

  // 🔴 FUNGSI MENGUBAH FASE NUTRISI DARI APP 🔴
  Future<void> gantiFase(String faseBaru) async {
    try {
      await _dbRef.child('pengaturan').update({
        'faseAktif': faseBaru,
      });
      Get.snackbar(
        'Berhasil',
        'Fase nutrisi berhasil diubah ke ${faseBaru.replaceAll('_', ' ').toUpperCase()}!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal mengubah fase: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  // 🔴 UPDATE BATAS UMUM (TANPA SNACKBAR BIKIN CONFLICT) 🔴
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
      debugPrint("Gagal update batas umum: $e");
    }
  }

  // 🔴 UPDATE NUTRISI FASE (TANPA SNACKBAR BIKIN CONFLICT) 🔴
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

      // Update nilai reaktif lokal langsung
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
      debugPrint("Gagal update fase $targetFase: $e");
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
        debugPrint("🚨 Error Realtime Sensor: $error");
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
      judul: info["judul"] ?? "Status Sistem",
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

  // 🔥 FUNGSI EVALUASI ANOMALI & CATAT LOG KE FIREBASE
  void _evaluasiNotifikasiAnomali(String waktuData) {
    final info = kesimpulanKondisi;
    String color = info["color"] ?? "green";

    if (color == "red" || color == "orange") {
      String currentSignature = "${info["judul"]}_${info["deskripsi"]}";

      if (_lastNotifiedSignature != currentSignature) {
        _lastNotifiedSignature = currentSignature;

        String judul = info["judul"] ?? "Peringatan Anomali";
        String pesan = info["deskripsi"] ?? "Parameter tanaman melebihi batas normal.";

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
      debugPrint("✅ Sukses mencatat anomali ke log_notifikasi Firebase!");
    } catch (e) {
      debugPrint("❌ Gagal mencatat log_notifikasi: $e");
    }
  }

  Future<void> sinkronkanKeDriveManual({bool isSilent = false}) async {
    try {
      if (!isSilent) {
        isUploadingToDrive.value = true;
        Get.snackbar(
          "Menghubungkan",
          "Mengunggah file log_growsense_v2.csv ke Google Drive...",
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
          "Berhasil",
          "Seluruh data riwayat CSV berhasil disinkronkan ke Google Drive!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (!isSilent) {
        Get.snackbar(
          "Gagal Sinkronisasi",
          "Terjadi kesalahan saat unggah: $e",
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
      suhuStatus.value = "OFF / RUSAK";
      suhuStatusColor.value = Colors.grey;
    } else if (val < suhuMin.value) {
      suhuStatus.value = "Dingin";
      suhuStatusColor.value = Colors.red;
    } else if (val > suhuMax.value) {
      suhuStatus.value = "Panas";
      suhuStatusColor.value = Colors.red;
    } else {
      suhuStatus.value = "Normal";
      suhuStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusLembap(double val) {
    if (val == -99 || val < 0) {
      lembapStatus.value = "OFF / RUSAK";
      lembapStatusColor.value = Colors.grey;
    } else if (val < lembapMin.value) {
      lembapStatus.value = "Kering";
      lembapStatusColor.value = Colors.red;
    } else if (val > lembapMax.value) {
      lembapStatus.value = "Lembap";
      lembapStatusColor.value = Colors.red;
    } else {
      lembapStatus.value = "Normal";
      lembapStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusPh(double val) {
    if (val == -99 || val < 0) {
      phStatus.value = "OFF / RUSAK";
      phStatusColor.value = Colors.grey;
    } else if (val < phMin.value) {
      phStatus.value = "Asam";
      phStatusColor.value = Colors.red;
    } else if (val > phMax.value) {
      phStatus.value = "Basa";
      phStatusColor.value = Colors.red;
    } else {
      phStatus.value = "Normal";
      phStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusNutrisi(int val) {
    if (val == -99 || val < 0) {
      nutrisiStatus.value = "OFF / RUSAK";
      nutrisiStatusColor.value = Colors.grey;
    } else if (val < nutrisiMinAktif.value) {
      nutrisiStatus.value = "Rendah";
      nutrisiStatusColor.value = Colors.red;
    } else if (val > nutrisiMaxAktif.value) {
      nutrisiStatus.value = "Tinggi";
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
        "status": "OFF / RUSAK",
        "color": Colors.grey,
        "dampak": "Sensor suhu tidak terhubung.",
        "penanganan": "Periksa kabel atau sensor suhu."
      };
    } else if (val < suhuMin.value) {
      return {
        "status": "DINGIN",
        "color": Colors.red,
        "dampak": "Suhu di bawah target (< ${suhuMin.value}°C). Tumbuh lambat.",
        "penanganan": "Gunakan heater / atur suhu ruangan."
      };
    } else if (val > suhuMax.value) {
      return {
        "status": "PANAS",
        "color": Colors.red,
        "dampak": "Suhu di atas target (> ${suhuMax.value}°C). Stres panas.",
        "penanganan": "Nyalakan kipas."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Pertumbuhan optimal & sehat (${suhuMin.value} - ${suhuMax.value}°C).",
        "penanganan": "Pertahankan kondisi saat ini."
      };
    }
  }

  Map<String, dynamic> getLembapInfo() {
    double val = double.tryParse(lembapValue.value) ?? 0;
    if (val == -99 || val < 0) {
      return {
        "status": "OFF / RUSAK",
        "color": Colors.grey,
        "dampak": "Sensor kelembapan terganggu.",
        "penanganan": "Periksa koneksi sensor kelembapan."
      };
    } else if (val < lembapMin.value) {
      return {
        "status": "KERING",
        "color": Colors.red,
        "dampak": "Kelembapan di bawah target (< ${lembapMin.value}%). Daun mengering.",
        "penanganan": "Nyalakan humidifier."
      };
    } else if (val > lembapMax.value) {
      return {
        "status": "LEMBAP",
        "color": Colors.red,
        "dampak": "Kelembapan di atas target (> ${lembapMax.value}%). Rentan jamur.",
        "penanganan": "Nyalakan exhaust fan / ventilasi."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Transpirasi seimbang (${lembapMin.value} - ${lembapMax.value}%).",
        "penanganan": "Pertahankan kondisi."
      };
    }
  }

  Map<String, dynamic> getNutrisiInfo() {
    double val = double.tryParse(nutrisiValue.value) ?? 0;
    int minBatas = nutrisiMinAktif.value.toInt();
    int maxBatas = nutrisiMaxAktif.value.toInt();

    if (val == -99 || val < 0) {
      return {
        "status": "OFF / RUSAK",
        "color": Colors.grey,
        "dampak": "Sensor nutrisi/TDS terputus.",
        "penanganan": "Bersihkan atau kalibrasi probe TDS."
      };
    } else if (val < minBatas) {
      return {
        "status": "RENDAH",
        "color": Colors.red,
        "dampak": "Nutrisi di bawah target ${namaFaseAktif.value} (< $minBatas ppm). Daun kerdil.",
        "penanganan": "Tambahkan pekat AB Mix."
      };
    } else if (val > maxBatas) {
      return {
        "status": "TINGGI",
        "color": Colors.red,
        "dampak": "Nutrisi melebihi target ${namaFaseAktif.value} (> $maxBatas ppm). Akar terbakar.",
        "penanganan": "Tambahkan air baku ke tandon."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Asupan gizi ideal untuk ${namaFaseAktif.value} ($minBatas - $maxBatas ppm).",
        "penanganan": "Pertahankan nutrisi."
      };
    }
  }

  Map<String, dynamic> getPhInfo() {
    double val = double.tryParse(phValue.value) ?? 0;
    if (val == -99 || val < 0) {
      return {
        "status": "OFF / RUSAK",
        "color": Colors.grey,
        "dampak": "Sensor pH bermasalah.",
        "penanganan": "Kalibrasi ulang probe pH."
      };
    } else if (val < phMin.value) {
      return {
        "status": "ASAM",
        "color": Colors.red,
        "dampak": "pH di bawah target (< ${phMin.value}). Akar rusak.",
        "penanganan": "Tambahkan cairan pH Up."
      };
    } else if (val > phMax.value) {
      return {
        "status": "BASA",
        "color": Colors.red,
        "dampak": "pH di atas target (> ${phMax.value}). Nutrisi tak terserap.",
        "penanganan": "Tambahkan cairan pH Down."
      };
    } else {
      return {
        "status": "NORMAL",
        "color": Colors.green,
        "dampak": "Serapan nutrisi maksimal (${phMin.value} - ${phMax.value}).",
        "penanganan": "Pertahankan pH."
      };
    }
  }

  Map<String, String> get kesimpulanKondisi {
    String sStatus = suhuStatus.value.toUpperCase();
    String lStatus = lembapStatus.value.toUpperCase();
    String nStatus = nutrisiStatus.value.toUpperCase();
    String pStatus = phStatus.value.toUpperCase();

    List<String> sensorOffline = [];
    if (sStatus.contains('OFF') || sStatus.contains('RUSAK')) sensorOffline.add("Suhu");
    if (lStatus.contains('OFF') || lStatus.contains('RUSAK')) sensorOffline.add("Kelembapan");
    if (nStatus.contains('OFF') || nStatus.contains('RUSAK')) sensorOffline.add("Nutrisi");
    if (pStatus.contains('OFF') || pStatus.contains('RUSAK')) sensorOffline.add("pH Air");

    if (sensorOffline.isNotEmpty) {
      String daftarOffline = sensorOffline.join(", ");
      return {
        "judul": "Peringatan: Sensor Terputus!",
        "deskripsi": "Sensor $daftarOffline terdeteksi offline / tidak terhubung. Segera periksa koneksi kabel modul.",
        "status": "OFFLINE",
        "color": "red"
      };
    }

    if (sStatus == 'NORMAL' && lStatus == 'NORMAL' && nStatus == 'NORMAL' && pStatus == 'NORMAL') {
      return {
        "judul": "Kondisi Tanaman Optimal",
        "deskripsi": "Semua parameter ideal untuk fase ${namaFaseAktif.value}. Tanaman tumbuh dengan sehat.",
        "status": "SEHAT",
        "color": "green"
      };
    }

    List<String> masalahList = [];
    if (sStatus == 'PANAS' || sStatus == 'TINGGI') masalahList.add("suhu terlalu panas");
    if (sStatus == 'DINGIN' || sStatus == 'RENDAH') masalahList.add("suhu terlalu dingin");
    if (lStatus == 'LEMBAP' || lStatus == 'SANGAT LEMBAP' || lStatus == 'TINGGI') masalahList.add("kelembapan terlalu tinggi");
    if (lStatus == 'KERING' || lStatus == 'RENDAH') masalahList.add("kelembapan terlalu kering");
    if (nStatus == 'TINGGI') masalahList.add("pekat nutrisi berlebihan (fase ${namaFaseAktif.value})");
    if (nStatus == 'RENDAH') masalahList.add("kekurangan nutrisi (fase ${namaFaseAktif.value})");
    if (pStatus == 'BASA' || pStatus == 'TINGGI') masalahList.add("pH air terlalu basa");
    if (pStatus == 'ASAM' || pStatus == 'RENDAH') masalahList.add("pH air terlalu asam");

    if (masalahList.isNotEmpty) {
      String gabunganMasalah = masalahList.join(", ");
      bool kritis = masalahList.length >= 3;

      return {
        "judul": kritis ? "Kondisi Tanaman Kritis!" : "Kondisi Tanaman Perlu Perhatian",
        "deskripsi": "Tanaman mengalami kendala karena $gabunganMasalah. Segera lakukan penyesuaian parameter.",
        "status": kritis ? "BAHAYA" : "PERHATIAN",
        "color": kritis ? "red" : "orange"
      };
    }

    return {
      "judul": "Status Normal",
      "deskripsi": "Sistem memantau kondisi tanaman secara penuh.",
      "status": "NORMAL",
      "color": "green"
    };
  }
}