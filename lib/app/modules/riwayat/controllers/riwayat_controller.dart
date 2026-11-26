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

  static List _cachedRiwayatData = [];
  static DateTime? _cachedTanggal;
  static TimeOfDay? _cachedJamMulai;
  static TimeOfDay? _cachedJamSelesai;
  static bool _hasInitialCache = false;

  static TimeOfDay _defaultJamMulai() {
    final now = DateTime.now();
    if (now.hour < 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    return TimeOfDay(hour: now.hour - 2, minute: now.minute);
  }

  final Rx<DateTime> tanggalPilihan = DateTime.now().obs;
  final Rx<TimeOfDay> jamMulai = _defaultJamMulai().obs;
  final Rx<TimeOfDay> jamSelesai = TimeOfDay.now().obs;

  final RxList riwayatData = [].obs;
  final RxInt jumlahTampil = 100.obs;
  final RxBool isLoading = false.obs;

  final RxString faseAktif = 'semai'.obs;
  final RxString namaFaseAktif = 'Seedling'.obs;
  final RxDouble nutrisiMinAktif = 400.0.obs;
  final RxDouble nutrisiMaxAktif = 600.0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      activeParameter.value = Get.arguments.toString();
    }
    _listenPengaturanFirebase();

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

  void tampilkanLebihBanyak() {
    jumlahTampil.value += 100;
  }

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
            namaFaseAktif.value = 'Seedling';
          } else if (fase == 'veg_awal') {
            namaFaseAktif.value = 'Early Vegetative';
          } else if (fase == 'veg_lanjutan') {
            namaFaseAktif.value = 'Late Vegetative';
          } else {
            namaFaseAktif.value = detailFase['nama'] ?? fase;
          }
        }

        riwayatData.refresh();
      }
    }, onError: (error) {
      debugPrint("🚨 Realtime Settings Error in History: $error");
    });
  }

  Future<void> muatDataRiwayat() async {
    isLoading.value = true;
    jumlahTampil.value = 100;
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

      _cachedRiwayatData = List.from(result);
      _cachedTanggal = tanggalPilihan.value;
      _cachedJamMulai = jamMulai.value;
      _cachedJamSelesai = jamSelesai.value;
      _hasInitialCache = true;
    } catch (e) {
      debugPrint("Error loading history data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool isNutrisiAbnormal(double vNutrisi) {
    if (vNutrisi == -99 || vNutrisi < 0) return true;
    return vNutrisi < nutrisiMinAktif.value || vNutrisi > nutrisiMaxAktif.value;
  }

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
        "Export Failed",
        "Selected time range is ${selisihWaktu.inHours} hours. Maximum data export limit is 24 hours!",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (riwayatData.isEmpty) {
      Get.snackbar(
        "Empty Data",
        "No history data available to export within your selected time range.",
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
        "Export Error",
        "Failed to generate file: $e",
        backgroundColor: Colors.black,
        colorText: Colors.white,
      );
    } finally {
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

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
    if (fileBytes == null) throw Exception("Failed to generate Excel file");

    String timestampFile = DateFormat('yyyyMMdd_HHmmss').format(waktuEkspor);

    if (Get.isDialogOpen ?? false) Get.back();

    _tampilkanPreviewExcel(
      dataLog: preparedData,
      fileBytes: fileBytes,
      fileName: "GrowSense_PhoneLog_$timestampFile.xlsx",
      waktuEksporRapi: waktuEksporRapi,
    );
  }

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
          title: const Text("Excel Data Preview", style: TextStyle(fontSize: 16)),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.download, color: Colors.white, size: 20),
              label: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    "Saved Successfully",
                    "File saved in Download folder: $fileName",
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 4),
                  );
                } catch (e) {
                  Get.snackbar(
                    "Save Failed",
                    "An error occurred while saving file: $e",
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
                    "Phase: ${namaFaseAktif.value} (${nutrisiMinAktif.value.toInt()} - ${nutrisiMaxAktif.value.toInt()} PPM)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Total: ${dataLog.length} rows | Exported: $waktuEksporRapi",
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
                            SizedBox(width: 155, child: Text("Time (WIB)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 95, child: Text("Temp (°C)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 105, child: Text("Humidity (%)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 115, child: Text("Nutrient (PPM)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                            SizedBox(width: 90, child: Text("Water pH", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
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
// TOP-LEVEL FUNCTIONS FOR BACKGROUND PROCESSING (ISOLATE)
// ============================================================================

Future<List<int>?> _buildExcelIsolate(Map<String, dynamic> payload) async {
  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Phone Reception Log'];

  final String waktuEksporRapi = payload['waktuEksporRapi'];
  final String namaFase = payload['namaFase'];
  final int nutrisiMin = payload['nutrisiMin'];
  final int nutrisiMax = payload['nutrisiMax'];
  final List dataLog = payload['dataLog'];

  sheetObject.appendRow([TextCellValue('GROWSENSE - MOBILE APP RECEPTION LOG')]);
  sheetObject.appendRow([TextCellValue('Exported on: $waktuEksporRapi')]);
  sheetObject.appendRow([TextCellValue('Active Phase: $namaFase (Target Nutrient: $nutrisiMin - $nutrisiMax PPM)')]);
  sheetObject.appendRow([TextCellValue('Note: Red text indicates values outside the ideal threshold')]);
  sheetObject.appendRow([TextCellValue('')]);

  sheetObject.appendRow([
    TextCellValue('No'),
    TextCellValue('Received Time (WIB)'),
    TextCellValue('Timestamp (ms)'),
    TextCellValue('Temperature (°C)'),
    TextCellValue('Humidity (%)'),
    TextCellValue('Nutrient (PPM)'),
    TextCellValue('Water pH'),
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
              headerCell('Measurement Time'),
              headerCell('Temp (°C)'),
              headerCell('Humidity (%)'),
              headerCell('Water pH'),
              headerCell('Nutrient (PPM)'),
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
          pw.Text("Sensor Data History Summary Report (Total: ${dataLog.length} records)",
              style: const pw.TextStyle(fontSize: 10.5)),
          pw.Text("Exported on: $waktuEksporRapi",
              style: pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey700,
                  fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 4),
          pw.Text(
            "Active Phase: $namaFase (Target Nutrient: $nutrisiMin - $nutrisiMax PPM)",
            style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green900),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "Note: Bold red text indicates values outside the ideal threshold.",
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