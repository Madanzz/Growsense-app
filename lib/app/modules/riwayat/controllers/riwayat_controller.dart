import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../../data/providers/sensor_provider.dart';

class RiwayatController extends GetxController {
  final SensorProvider _sensorProvider = SensorProvider();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _pengaturanSubscription;

  final RxString activeParameter = 'Suhu'.obs;

  // Penyimpanan sementara di RAM agar pindah tab instan tanpa loading ulang
  static List _cachedRiwayatData = [];
  static DateTime? _cachedTanggal;
  static TimeOfDay? _cachedJamMulai;
  static TimeOfDay? _cachedJamSelesai;
  static bool _hasInitialCache = false;

  // Helper jam mulai bawaan: 2 jam terakhir di hari yang sama
  static TimeOfDay _defaultJamMulai() {
    final now = DateTime.now();
    if (now.hour < 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: now.hour - 2, minute: now.minute);
  }

  // State Filter Waktu
  final Rx<DateTime> tanggalPilihan = DateTime.now().obs;
  final Rx<TimeOfDay> jamMulai = _defaultJamMulai().obs;
  final Rx<TimeOfDay> jamSelesai = TimeOfDay.now().obs;

  // Data, Pagination Layar & Loading State
  final RxList riwayatData = [].obs;
  final RxInt jumlahTampil = 100.obs;
  final RxBool isLoading = false.obs;

  // State Dinamis Fase Nutrisi dari Firebase
  final RxString faseAktif = 'semai'.obs;
  final RxString namaFaseAktif = 'Semai'.obs;
  final RxDouble nutrisiMinAktif = 400.0.obs;
  final RxDouble nutrisiMaxAktif = 600.0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      activeParameter.value = Get.arguments.toString();
    }
    _listenPengaturanFirebase();

    // Jika sudah pernah memuat data sebelumnya, langsung tampilkan dari RAM tanpa loading ulang
    if (_hasInitialCache) {
      if (_cachedTanggal != null) tanggalPilihan.value = _cachedTanggal!;
      if (_cachedJamMulai != null) jamMulai.value = _cachedJamMulai!;
      if (_cachedJamSelesai != null) jamSelesai.value = _cachedJamSelesai!;
      riwayatData.assignAll(_cachedRiwayatData);
    } else {
      muatDataRiwayat();
    }
  }

  @override
  void onClose() {
    _pengaturanSubscription?.cancel();
    super.onClose();
  }

  // Tambah jumlah baris yang ditampilkan di layar jika data lebih dari 100
  void tampilkanLebihBanyak() {
    jumlahTampil.value += 100;
  }

  // Listen Firebase untuk rentang nutrisi aktif
  void _listenPengaturanFirebase() {
    _pengaturanSubscription?.cancel();
    _pengaturanSubscription = _dbRef.child('pengaturan').onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;

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

        riwayatData.refresh();
      }
    }, onError: (error) {
      debugPrint("🚨 Error Realtime Pengaturan di Riwayat: $error");
    });
  }

  // --- 1. MEMUAT DATA BERDASARKAN FILTER TANGGAL & JAM ---
  Future<void> muatDataRiwayat() async {
    isLoading.value = true;
    jumlahTampil.value = 100; // Reset tampilan layar ke 100 baris pertama agar ringan
    try {
      DateTime dtMulai = DateTime(
        tanggalPilihan.value.year,
        tanggalPilihan.value.month,
        tanggalPilihan.value.day,
        jamMulai.value.hour,
        jamMulai.value.minute,
        0,
      );
      DateTime dtSelesai = DateTime(
        tanggalPilihan.value.year,
        tanggalPilihan.value.month,
        tanggalPilihan.value.day,
        jamSelesai.value.hour,
        jamSelesai.value.minute,
        59,
      );

      if (dtSelesai.isBefore(dtMulai)) {
        dtSelesai = dtSelesai.add(const Duration(days: 1));
      }

      var result = await _sensorProvider.getRiwayatFiltered(dtMulai, dtSelesai);
      riwayatData.assignAll(result);

      // Simpan hasil ke RAM
      _cachedRiwayatData = List.from(result);
      _cachedTanggal = tanggalPilihan.value;
      _cachedJamMulai = jamMulai.value;
      _cachedJamSelesai = jamSelesai.value;
      _hasInitialCache = true;
    } catch (e) {
      debugPrint("Error saat memuat data riwayat: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Bantuan Pengecekan Anomali Nutrisi Dinamis
  bool isNutrisiAbnormal(double vNutrisi) {
    if (vNutrisi == -99 || vNutrisi < 0) return true;
    return vNutrisi < nutrisiMinAktif.value || vNutrisi > nutrisiMaxAktif.value;
  }

  // Siapkan data primitif bersih sebelum dikirim ke background thread (Isolate)
  List _siapkanDataUntukIsolate(List dataLog) {
    return dataLog.map((item) {
      double vSuhu = double.tryParse(item['suhu']?.toString() ?? '0') ?? 0.0;
      double vLembap = double.tryParse(item['kelembapan']?.toString() ?? '0') ?? 0.0;
      double vPh = double.tryParse(item['ph']?.toString() ?? '0') ?? 0.0;
      double vNutrisi = double.tryParse(item['nutrisi']?.toString() ?? '0') ?? 0.0;

      return {
        'waktu': item['waktu']?.toString() ?? '-',
        'timestamp_epoch': item['timestamp_epoch']?.toString() ?? '-',
        'suhu': item['suhu']?.toString() ?? '-',
        'kelembapan': item['kelembapan']?.toString() ?? '-',
        'nutrisi': item['nutrisi']?.toString() ?? '-',
        'ph': item['ph']?.toString() ?? '-',
        'isSuhuAbnormal': vSuhu < 16.0 || vSuhu > 28.0,
        'isLembapAbnormal': vLembap < 60.0 || vLembap > 75.0,
        'isPhAbnormal': vPh < 5.8 || vPh > 6.3,
        'isNutrisiAbnormal': isNutrisiAbnormal(vNutrisi),
      };
    }).toList();
  }

  // --- 2. PROSES EKSPOR DATA (PDF / EXCEL) ---
  Future<void> prosesEksporData({required bool isExcel}) async {
    DateTime dtMulai = DateTime(
      tanggalPilihan.value.year,
      tanggalPilihan.value.month,
      tanggalPilihan.value.day,
      jamMulai.value.hour,
      jamMulai.value.minute,
      0,
    );
    DateTime dtSelesai = DateTime(
      tanggalPilihan.value.year,
      tanggalPilihan.value.month,
      tanggalPilihan.value.day,
      jamSelesai.value.hour,
      jamSelesai.value.minute,
      59,
    );

    if (dtSelesai.isBefore(dtMulai)) {
      dtSelesai = dtSelesai.add(const Duration(days: 1));
    }

    Duration selisihWaktu = dtSelesai.difference(dtMulai);
    if (selisihWaktu.inHours > 24) {
      Get.snackbar(
        "Gagal Ekspor",
        "Rentang waktu dipilih ${selisihWaktu.inHours} jam. Maksimal penarikan data adalah 24 jam!",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (riwayatData.isEmpty) {
      Get.snackbar(
        "Data Kosong",
        "Tidak ada data riwayat yang dapat diekspor pada rentang jam pilihan Anda.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      if (isExcel) {
        await _generateExcel(activeParameter.value, riwayatData);
      } else {
        await _generatePdf(activeParameter.value, riwayatData);
      }
    } catch (e) {
      Get.snackbar(
        "Error Ekspor",
        "Gagal membuat file: $e",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
    } finally {
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  // --- GENERATE EXCEL + TAMPILKAN PRATINJAU DI DALAM APLIKASI ---
  Future<void> _generateExcel(String parameter, List dataLog) async {
    DateTime waktuEkspor = DateTime.now();
    String waktuEksporRapi = DateFormat('dd MMMM yyyy, HH:mm:ss').format(waktuEkspor);
    final preparedData = _siapkanDataUntukIsolate(dataLog);

    final payload = {
      'waktuEksporRapi': waktuEksporRapi,
      'namaFase': namaFaseAktif.value,
      'nutrisiMin': nutrisiMinAktif.value.toInt(),
      'nutrisiMax': nutrisiMaxAktif.value.toInt(),
      'dataLog': preparedData,
    };

    final List<int>? fileBytes = await compute(_buildExcelIsolate, payload);
    if (fileBytes == null) throw Exception("Gagal membuat file Excel");

    String timestampFile = DateFormat('yyyyMMdd_HHmmss').format(waktuEkspor);

    if (Get.isDialogOpen ?? false) Get.back();

    _tampilkanPreviewExcel(
      dataLog: preparedData,
      fileBytes: fileBytes,
      fileName: "GrowSense_LogHP_$timestampFile.xlsx",
      waktuEksporRapi: waktuEksporRapi,
    );
  }

  // --- TAMPILAN PRATINJAU EXCEL DI DALAM APLIKASI ---
  void _tampilkanPreviewExcel({
    required List dataLog,
    required List<int> fileBytes,
    required String fileName,
    required String waktuEksporRapi,
  }) {
    Get.to(
      () => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E6B3E),
          foregroundColor: Colors.white,
          title: const Text("Pratinjau Data Excel", style: TextStyle(fontSize: 16)),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.download, color: Colors.white, size: 20),
              label: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                try {
                  Directory targetDir = Directory('/storage/emulated/0/Download');
                  if (!await targetDir.exists()) {
                    targetDir = await getApplicationDocumentsDirectory();
                  }
                  String fullPath = "${targetDir.path}/$fileName";
                  File(fullPath)
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(fileBytes);

                  Get.snackbar(
                    "Berhasil Disimpan",
                    "File tersimpan di folder Download: $fileName",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                } catch (e) {
                  Get.snackbar(
                    "Gagal Menyimpan",
                    "Terjadi kendala saat menyimpan file: $e",
                    backgroundColor: Colors.redAccent,
                    colorText: Colors.white,
                  );
                }
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Fase: ${namaFaseAktif.value} (${nutrisiMinAktif.value.toInt()} - ${nutrisiMaxAktif.value.toInt()} PPM)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Total: ${dataLog.length} baris | Diekspor: $waktuEksporRapi",
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 650,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: const Row(
                          children: [
                            SizedBox(width: 40, child: Text("No", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 155, child: Text("Waktu (WIB)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 95, child: Text("Suhu (°C)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 105, child: Text("Lembap (%)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 115, child: Text("Nutrisi (PPM)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 90, child: Text("pH Air", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: dataLog.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = dataLog[index];
                            final bool abSuhu = item['isSuhuAbnormal'] ?? false;
                            final bool abLembap = item['isLembapAbnormal'] ?? false;
                            final bool abNutrisi = item['isNutrisiAbnormal'] ?? false;
                            final bool abPh = item['isPhAbnormal'] ?? false;

                            return Container(
                              color: index.isEven ? Colors.white : Colors.grey.shade50,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Row(
                                children: [
                                  SizedBox(width: 40, child: Text("${index + 1}", style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                                  SizedBox(width: 155, child: Text("${item['waktu']}", style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                                  SizedBox(
                                    width: 95,
                                    child: Text(
                                      "${item['suhu']}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: abSuhu ? Colors.red : Colors.black87, fontWeight: abSuhu ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 105,
                                    child: Text(
                                      "${item['kelembapan']}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: abLembap ? Colors.red : Colors.black87, fontWeight: abLembap ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 115,
                                    child: Text(
                                      "${item['nutrisi']}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: abNutrisi ? Colors.red : Colors.black87, fontWeight: abNutrisi ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      "${item['ph']}",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: abPh ? Colors.red : Colors.black87, fontWeight: abPh ? FontWeight.bold : FontWeight.normal),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GENERATE PDF (DI JALUR LATAR BELAKANG) ---
  Future<void> _generatePdf(String parameter, List dataLog) async {
    DateTime waktuEkspor = DateTime.now();
    String waktuEksporRapi = DateFormat('dd MMMM yyyy, HH:mm:ss').format(waktuEkspor);

    final payload = {
      'waktuEksporRapi': waktuEksporRapi,
      'namaFase': namaFaseAktif.value,
      'nutrisiMin': nutrisiMinAktif.value.toInt(),
      'nutrisiMax': nutrisiMaxAktif.value.toInt(),
      'dataLog': _siapkanDataUntukIsolate(dataLog),
    };

    final Uint8List pdfBytes = await compute(_buildPdfIsolate, payload);

    String timestampFile = DateFormat('yyyyMMdd_HHmmss').format(waktuEkspor);

    if (Get.isDialogOpen ?? false) Get.back();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: "GrowSense_Report_$timestampFile",
    );
  }
}

// ============================================================================
// FUNGSI TOP-LEVEL DI LUAR CLASS UNTUK PROSES BACKGROUND (ISOLATE)
// ============================================================================

Future<List<int>?> _buildExcelIsolate(Map<String, dynamic> payload) async {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Laporan Penerimaan HP'];

  final String waktuEksporRapi = payload['waktuEksporRapi'];
  final String namaFase = payload['namaFase'];
  final int nutrisiMin = payload['nutrisiMin'];
  final int nutrisiMax = payload['nutrisiMax'];
  final List dataLog = payload['dataLog'];

  sheetObject.appendRow([TextCellValue('GROWSENSE - LOG PENERIMAAN APLIKASI HP')]);
  sheetObject.appendRow([TextCellValue('Diekspor pada: $waktuEksporRapi')]);
  sheetObject.appendRow([TextCellValue('Fase Aktif: $namaFase (Target Nutrisi: $nutrisiMin - $nutrisiMax PPM)')]);
  sheetObject.appendRow([TextCellValue('Keterangan: Teks Merah = Nilai di luar ambang batas ideal')]);
  sheetObject.appendRow([TextCellValue('')]);

  sheetObject.appendRow([
    TextCellValue('No'),
    TextCellValue('Waktu Diterima HP (WIB)'),
    TextCellValue('Timestamp (ms)'),
    TextCellValue('Suhu (°C)'),
    TextCellValue('Kelembapan (%)'),
    TextCellValue('Nutrisi (PPM)'),
    TextCellValue('pH Air'),
  ]);

  CellStyle redTextStyle = CellStyle(
    fontColorHex: ExcelColor.red50,
    bold: true,
  );

  int no = 1;
  for (var item in dataLog) {
    bool isSuhuAbnormal = item['isSuhuAbnormal'] ?? false;
    bool isLembapAbnormal = item['isLembapAbnormal'] ?? false;
    bool isPhAbnormal = item['isPhAbnormal'] ?? false;
    bool isNutrisiAbnormalVal = item['isNutrisiAbnormal'] ?? false;

    int rowIdx = sheetObject.maxRows;

    sheetObject.appendRow([
      IntCellValue(no++),
      TextCellValue(item['waktu']),
      TextCellValue(item['timestamp_epoch']),
      TextCellValue(item['suhu']),
      TextCellValue(item['kelembapan']),
      TextCellValue(item['nutrisi']),
      TextCellValue(item['ph']),
    ]);

    if (isSuhuAbnormal) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).cellStyle = redTextStyle;
    }
    if (isLembapAbnormal) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).cellStyle = redTextStyle;
    }
    if (isNutrisiAbnormalVal) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).cellStyle = redTextStyle;
    }
    if (isPhAbnormal) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).cellStyle = redTextStyle;
    }
  }

  return excel.save();
}

Future<Uint8List> _buildPdfIsolate(Map<String, dynamic> payload) async {
  final pdf = pw.Document();

  final String waktuEksporRapi = payload['waktuEksporRapi'];
  final String namaFase = payload['namaFase'];
  final int nutrisiMin = payload['nutrisiMin'];
  final int nutrisiMax = payload['nutrisiMax'];
  final List dataLog = payload['dataLog'];

  final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5);
  const normalCellStyle = pw.TextStyle(fontSize: 8.5, color: PdfColors.black);
  final abnormalCellStyle = pw.TextStyle(
    fontSize: 8.5,
    color: PdfColors.red900,
    fontWeight: pw.FontWeight.bold,
  );

  pw.Widget headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        child: pw.Text(text, style: headerStyle, textAlign: pw.TextAlign.center),
      );

  pw.Widget dataCell(String text, {bool isAbnormal = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 3),
        child: pw.Text(
          text,
          style: isAbnormal ? abnormalCellStyle : normalCellStyle,
          textAlign: pw.TextAlign.center,
        ),
      );

  const int barisPerTabel = 35;
  final List<pw.Widget> potonganTabel = [];

  for (int i = 0; i < dataLog.length; i += barisPerTabel) {
    final int batasAkhir =
        (i + barisPerTabel < dataLog.length) ? i + barisPerTabel : dataLog.length;
    final subData = dataLog.sublist(i, batasAkhir);

    potonganTabel.add(
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        columnWidths: const {
          0: pw.FixedColumnWidth(34),
          1: pw.FixedColumnWidth(140),
          2: pw.FixedColumnWidth(72),
          3: pw.FixedColumnWidth(78),
          4: pw.FixedColumnWidth(62),
          5: pw.FixedColumnWidth(90),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              headerCell('No'),
              headerCell('Waktu Pengukuran'),
              headerCell('Suhu (°C)'),
              headerCell('Lembap (%)'),
              headerCell('pH Air'),
              headerCell('Nutrisi (PPM)'),
            ],
          ),
          ...List.generate(subData.length, (j) {
            final int nomorUrut = i + j + 1;
            final item = subData[j];

            return pw.TableRow(
              children: [
                dataCell(nomorUrut.toString()),
                dataCell(item['waktu']),
                dataCell(item['suhu'], isAbnormal: item['isSuhuAbnormal'] ?? false),
                dataCell(item['kelembapan'], isAbnormal: item['isLembapAbnormal'] ?? false),
                dataCell(item['ph'], isAbnormal: item['isPhAbnormal'] ?? false),
                dataCell(item['nutrisi'], isAbnormal: item['isNutrisiAbnormal'] ?? false),
              ],
            );
          }),
        ],
      ),
    );

    if (batasAkhir < dataLog.length) {
      potonganTabel.add(pw.NewPage());
    }
    potonganTabel.add(pw.SizedBox(height: 6));
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      maxPages: 500,
      build: (pw.Context context) {
        return [
          pw.Text("GROWSENSE SMART GREENHOUSE",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text("Laporan Riwayat Rangkuman Data Sensor (Total: ${dataLog.length} data)",
              style: const pw.TextStyle(fontSize: 10.5)),
          pw.Text("Diekspor pada: $waktuEksporRapi",
              style: pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 4),
          pw.Text(
            "Fase Aktif: $namaFase (Target Nutrisi: $nutrisiMin - $nutrisiMax PPM)",
            style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "Keterangan: Teks berwarna merah tebal menandakan nilai di luar ambang batas ideal.",
            style: pw.TextStyle(
              fontSize: 8.5,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 6),
          ...potonganTabel,
        ];
      },
    ),
  );

  return pdf.save();
}