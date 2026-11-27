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
  var namaFaseAktif = 'Semai'.obs;
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

  String get currentPhaseDisplayName {
    if (faseAktif.value == 'semai') return 'seedling'.tr;
    if (faseAktif.value == 'veg_awal') return 'early_veg_full'.tr;
    if (faseAktif.value == 'veg_lanjutan') return 'late_veg_full'.tr;
    return namaFaseAktif.value;
  }

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
            namaFaseAktif.value = 'Semai';
          } else if (fase == 'veg_awal') {
            namaFaseAktif.value = 'Vegetatif Awal';
          } else if (fase == 'veg_lanjutan') {
            namaFaseAktif.value = 'Vegetatif Lanjutan';
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
      debugPrint("🚨 Error Realtime Pengaturan: $error");
    });
  }

  Future<void> gantiFase(String faseBaru) async {
    String labelFase = switch (faseBaru) {
      'semai' => 'seedling'.tr.toUpperCase(),
      'veg_awal' => 'early_veg_full'.tr.toUpperCase(),
      'veg_lanjutan' => 'late_veg_full'.tr.toUpperCase(),
      _ => faseBaru.replaceAll('_', ' ').toUpperCase(),
    };

    try {
      await _dbRef.child('pengaturan').update({
        'faseAktif': faseBaru,
      });
      Get.snackbar(
        'success'.tr,
        'phase_updated'.trParams({'phase': labelFase}),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'failed'.tr,
        'phase_update_failed'.trParams({'err': '$e'}),
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
      debugPrint("Gagal update batas umum: $e");
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
      judul: info["judul"] ?? 'cond_norm_title'.tr,
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

        String judul = info["judul"] ?? 'alert_default'.tr;
        String pesan = info["deskripsi"] ?? "";

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
          'connecting'.tr,
          'uploading_csv'.tr,
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
          'success'.tr,
          'sync_success_msg'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (!isSilent) {
        Get.snackbar(
          'sync_failed'.tr,
          'sync_failed_msg'.trParams({'err': '$e'}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } finally {
      if (!isSilent) isUploadingToDrive.value = false;
    }
  }

  // Simpan kode status internal tetap konsisten agar logic tidak terpengaruh bahasa
  void _evaluasiStatusSuhu(double val) {
    if (val == -99 || val < -50) {
      suhuStatus.value = "OFF";
      suhuStatusColor.value = Colors.grey;
    } else if (val < suhuMin.value) {
      suhuStatus.value = "COLD";
      suhuStatusColor.value = Colors.red;
    } else if (val > suhuMax.value) {
      suhuStatus.value = "HOT";
      suhuStatusColor.value = Colors.red;
    } else {
      suhuStatus.value = "NORMAL";
      suhuStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusLembap(double val) {
    if (val == -99 || val < 0) {
      lembapStatus.value = "OFF";
      lembapStatusColor.value = Colors.grey;
    } else if (val < lembapMin.value) {
      lembapStatus.value = "DRY";
      lembapStatusColor.value = Colors.red;
    } else if (val > lembapMax.value) {
      lembapStatus.value = "HUMID";
      lembapStatusColor.value = Colors.red;
    } else {
      lembapStatus.value = "NORMAL";
      lembapStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusPh(double val) {
    if (val == -99 || val < 0) {
      phStatus.value = "OFF";
      phStatusColor.value = Colors.grey;
    } else if (val < phMin.value) {
      phStatus.value = "ACIDIC";
      phStatusColor.value = Colors.red;
    } else if (val > phMax.value) {
      phStatus.value = "ALKALINE";
      phStatusColor.value = Colors.red;
    } else {
      phStatus.value = "NORMAL";
      phStatusColor.value = Colors.green;
    }
  }

  void _evaluasiStatusNutrisi(int val) {
    if (val == -99 || val < 0) {
      nutrisiStatus.value = "OFF";
      nutrisiStatusColor.value = Colors.grey;
    } else if (val < nutrisiMinAktif.value) {
      nutrisiStatus.value = "LOW";
      nutrisiStatusColor.value = Colors.red;
    } else if (val > nutrisiMaxAktif.value) {
      nutrisiStatus.value = "HIGH";
      nutrisiStatusColor.value = Colors.red;
    } else {
      nutrisiStatus.value = "NORMAL";
      nutrisiStatusColor.value = Colors.green;
    }
  }

  Map<String, dynamic> getSuhuInfo() {
    double val = double.tryParse(suhuValue.value) ?? 0;
    if (val == -99 || val < -50) {
      return {
        "status": 'status_off'.tr,
        "color": Colors.grey,
        "dampak": 'temp_off_impact'.tr,
        "penanganan": 'temp_off_action'.tr,
      };
    } else if (val < suhuMin.value) {
      return {
        "status": 'status_cold'.tr,
        "color": Colors.red,
        "dampak": 'temp_cold_impact'.trParams({'min': '${suhuMin.value}'}),
        "penanganan": 'temp_cold_action'.tr,
      };
    } else if (val > suhuMax.value) {
      return {
        "status": 'status_hot'.tr,
        "color": Colors.red,
        "dampak": 'temp_hot_impact'.trParams({'max': '${suhuMax.value}'}),
        "penanganan": 'temp_hot_action'.tr,
      };
    } else {
      return {
        "status": 'status_normal'.tr,
        "color": Colors.green,
        "dampak": 'temp_norm_impact'.trParams({'min': '${suhuMin.value}', 'max': '${suhuMax.value}'}),
        "penanganan": 'temp_norm_action'.tr,
      };
    }
  }

  Map<String, dynamic> getLembapInfo() {
    double val = double.tryParse(lembapValue.value) ?? 0;
    if (val == -99 || val < 0) {
      return {
        "status": 'status_off'.tr,
        "color": Colors.grey,
        "dampak": 'hum_off_impact'.tr,
        "penanganan": 'hum_off_action'.tr,
      };
    } else if (val < lembapMin.value) {
      return {
        "status": 'status_dry'.tr,
        "color": Colors.red,
        "dampak": 'hum_dry_impact'.trParams({'min': '${lembapMin.value}'}),
        "penanganan": 'hum_dry_action'.tr,
      };
    } else if (val > lembapMax.value) {
      return {
        "status": 'status_humid'.tr,
        "color": Colors.red,
        "dampak": 'hum_humid_impact'.trParams({'max': '${lembapMax.value}'}),
        "penanganan": 'hum_humid_action'.tr,
      };
    } else {
      return {
        "status": 'status_normal'.tr,
        "color": Colors.green,
        "dampak": 'hum_norm_impact'.trParams({'min': '${lembapMin.value}', 'max': '${lembapMax.value}'}),
        "penanganan": 'hum_norm_action'.tr,
      };
    }
  }

  Map<String, dynamic> getNutrisiInfo() {
    double val = double.tryParse(nutrisiValue.value) ?? 0;
    int minBatas = nutrisiMinAktif.value.toInt();
    int maxBatas = nutrisiMaxAktif.value.toInt();
    String faseLabel = currentPhaseDisplayName;

    if (val == -99 || val < 0) {
      return {
        "status": 'status_off'.tr,
        "color": Colors.grey,
        "dampak": 'nut_off_impact'.tr,
        "penanganan": 'nut_off_action'.tr,
      };
    } else if (val < minBatas) {
      return {
        "status": 'status_low'.tr,
        "color": Colors.red,
        "dampak": 'nut_low_impact'.trParams({'phase': faseLabel, 'min': '$minBatas'}),
        "penanganan": 'nut_low_action'.tr,
      };
    } else if (val > maxBatas) {
      return {
        "status": 'status_high'.tr,
        "color": Colors.red,
        "dampak": 'nut_high_impact'.trParams({'phase': faseLabel, 'max': '$maxBatas'}),
        "penanganan": 'nut_high_action'.tr,
      };
    } else {
      return {
        "status": 'status_normal'.tr,
        "color": Colors.green,
        "dampak": 'nut_norm_impact'.trParams({'phase': faseLabel, 'min': '$minBatas', 'max': '$maxBatas'}),
        "penanganan": 'nut_norm_action'.tr,
      };
    }
  }

  Map<String, dynamic> getPhInfo() {
    double val = double.tryParse(phValue.value) ?? 0;
    if (val == -99 || val < 0) {
      return {
        "status": 'status_off'.tr,
        "color": Colors.grey,
        "dampak": 'ph_off_impact'.tr,
        "penanganan": 'ph_off_action'.tr,
      };
    } else if (val < phMin.value) {
      return {
        "status": 'status_acidic'.tr,
        "color": Colors.red,
        "dampak": 'ph_acid_impact'.trParams({'min': '${phMin.value}'}),
        "penanganan": 'ph_acid_action'.tr,
      };
    } else if (val > phMax.value) {
      return {
        "status": 'status_alkaline'.tr,
        "color": Colors.red,
        "dampak": 'ph_alk_impact'.trParams({'max': '${phMax.value}'}),
        "penanganan": 'ph_alk_action'.tr,
      };
    } else {
      return {
        "status": 'status_normal'.tr,
        "color": Colors.green,
        "dampak": 'ph_norm_impact'.trParams({'min': '${phMin.value}', 'max': '${phMax.value}'}),
        "penanganan": 'ph_norm_action'.tr,
      };
    }
  }

  Map<String, String> get kesimpulanKondisi {
    String sStatus = suhuStatus.value;
    String lStatus = lembapStatus.value;
    String nStatus = nutrisiStatus.value;
    String pStatus = phStatus.value;
    String faseLabel = currentPhaseDisplayName;

    List<String> sensorOffline = [];
    if (sStatus == 'OFF') sensorOffline.add('temp_title'.tr);
    if (lStatus == 'OFF') sensorOffline.add('humidity_title'.tr);
    if (nStatus == 'OFF') sensorOffline.add('nutrient_title'.tr);
    if (pStatus == 'OFF') sensorOffline.add('ph_title'.tr);

    if (sensorOffline.isNotEmpty) {
      String daftarOffline = sensorOffline.join(", ");
      return {
        "judul": 'cond_offline_title'.tr,
        "deskripsi": 'cond_offline_desc'.trParams({'sensors': daftarOffline}),
        "status": "OFFLINE",
        "color": "red"
      };
    }

    if (sStatus == 'NORMAL' && lStatus == 'NORMAL' && nStatus == 'NORMAL' && pStatus == 'NORMAL') {
      return {
        "judul": 'cond_opt_title'.tr,
        "deskripsi": 'cond_opt_desc'.trParams({'phase': faseLabel}),
        "status": "OPTIMAL",
        "color": "green"
      };
    }

    List<String> masalahList = [];
    if (sStatus == 'HOT') masalahList.add('issue_hot'.tr);
    if (sStatus == 'COLD') masalahList.add('issue_cold'.tr);
    if (lStatus == 'HUMID') masalahList.add('issue_humid'.tr);
    if (lStatus == 'DRY') masalahList.add('issue_dry'.tr);
    if (nStatus == 'HIGH') masalahList.add('issue_nut_high'.trParams({'phase': faseLabel}));
    if (nStatus == 'LOW') masalahList.add('issue_nut_low'.trParams({'phase': faseLabel}));
    if (pStatus == 'ALKALINE') masalahList.add('issue_ph_alk'.tr);
    if (pStatus == 'ACIDIC') masalahList.add('issue_ph_acid'.tr);

    if (masalahList.isNotEmpty) {
      String gabunganMasalah = masalahList.join(", ");
      bool kritis = masalahList.length >= 3;

      return {
        "judul": kritis ? 'cond_crit_title'.tr : 'cond_warn_title'.tr,
        "deskripsi": 'cond_issue_desc'.trParams({'issues': gabunganMasalah}),
        "status": kritis ? "DANGER" : "WARNING",
        "color": kritis ? "red" : "orange"
      };
    }

    return {
      "judul": 'cond_norm_title'.tr,
      "deskripsi": 'cond_norm_desc'.tr,
      "status": "NORMAL",
      "color": "green"
    };
  }
}