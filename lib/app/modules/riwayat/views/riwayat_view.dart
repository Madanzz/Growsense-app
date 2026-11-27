import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../widgets/main_layout.dart';
import '../controllers/riwayat_controller.dart';

class RiwayatView extends GetView<RiwayatController> {
  const RiwayatView({super.key});

  String get _translatedPhase {
    if (controller.faseAktif.value == 'semai') return 'seedling'.tr;
    if (controller.faseAktif.value == 'veg_awal') return 'early_veg_full'.tr;
    if (controller.faseAktif.value == 'veg_lanjutan') return 'late_veg_full'.tr;
    return controller.namaFaseAktif.value;
  }

  @override
  Widget build(BuildContext context) {
    final String activeParam = Get.arguments ?? 'Suhu';
    final String localeTag = Get.locale?.toString() ?? 'id_ID';

    return MainLayout(
      activeParameter: activeParam,
      showTabs: true,
      activeTab: 'Riwayat',
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- FILTER SECTION ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'filter_date'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Obx(() => TextButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  DateFormat('dd MMM yyyy', localeTag)
                                      .format(controller.tanggalPilihan.value),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: controller.tanggalPilihan.value,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    controller.tanggalPilihan.value = picked;
                                    controller.muatDataRiwayat();
                                  }
                                },
                              )),
                        ],
                      ),
                      const Divider(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('start_time'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Obx(() => TextButton(
                                    child: Text(
                                      controller.jamMulai.value.format(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () async {
                                      TimeOfDay? t = await showTimePicker(
                                        context: context,
                                        initialTime: controller.jamMulai.value,
                                      );
                                      if (t != null) {
                                        controller.jamMulai.value = t;
                                        controller.muatDataRiwayat();
                                      }
                                    },
                                  )),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('end_time'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Obx(() => TextButton(
                                    child: Text(
                                      controller.jamSelesai.value.format(context),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () async {
                                      TimeOfDay? t = await showTimePicker(
                                        context: context,
                                        initialTime: controller.jamSelesai.value,
                                      );
                                      if (t != null) {
                                        controller.jamSelesai.value = t;
                                        controller.muatDataRiwayat();
                                      }
                                    },
                                  )),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC2D8C0),
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => controller.muatDataRiwayat(),
                            child: Text('search_btn'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                              label: Text('print_pdf'.tr),
                              onPressed: () => controller.prosesEksporData(isExcel: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.table_chart, color: Colors.green),
                              label: Text('export_excel'.tr),
                              onPressed: () => controller.prosesEksporData(isExcel: true),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),

            // --- PHASE & THRESHOLD LEGEND ---
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.green.shade800),
                        const SizedBox(width: 6),
                        Text(
                          "${'phase_label'.tr}: $_translatedPhase (${controller.nutrisiMinAktif.value.toInt()} - ${controller.nutrisiMaxAktif.value.toInt()} PPM)",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  )),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'history_legend_note'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- HISTORY LIST ---
            Obx(() {
              if (controller.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.riwayatData.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text('no_history_data'.tr),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: controller.riwayatData.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  var item = controller.riwayatData[index];

                  double vSuhu = double.tryParse(item['suhu']?.toString() ?? '0') ?? 0.0;
                  double vLembap = double.tryParse(item['kelembapan']?.toString() ?? '0') ?? 0.0;
                  double vPh = double.tryParse(item['ph']?.toString() ?? '0') ?? 0.0;
                  double vNutrisi = double.tryParse(item['nutrisi']?.toString() ?? '0') ?? 0.0;

                  bool isSuhuAbnormal = vSuhu < 16.0 || vSuhu > 28.0;
                  bool isLembapAbnormal = vLembap < 60.0 || vLembap > 75.0;
                  bool isPhAbnormal = vPh < 5.8 || vPh > 6.3;
                  bool isNutrisiAbnormal = controller.isNutrisiAbnormal(vNutrisi);

                  return ListTile(
                    dense: true,
                    title: Text(
                      "${'time_label'.tr}: ${item['waktu'] ?? '-'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "${'temp_title'.tr}: "),
                            TextSpan(
                              text: "${item['suhu']}°C",
                              style: TextStyle(
                                color: isSuhuAbnormal ? Colors.red : Colors.black87,
                                fontWeight: isSuhuAbnormal ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            TextSpan(text: " | ${'humidity_title'.tr}: "),
                            TextSpan(
                              text: "${item['kelembapan']}%",
                              style: TextStyle(
                                color: isLembapAbnormal ? Colors.red : Colors.black87,
                                fontWeight: isLembapAbnormal ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const TextSpan(text: " | pH: "),
                            TextSpan(
                              text: "${item['ph']}",
                              style: TextStyle(
                                color: isPhAbnormal ? Colors.red : Colors.black87,
                                fontWeight: isPhAbnormal ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            TextSpan(text: " | ${'nutrient_title'.tr}: "),
                            TextSpan(
                              text: "${item['nutrisi']} PPM",
                              style: TextStyle(
                                color: isNutrisiAbnormal ? Colors.red : Colors.black87,
                                fontWeight: isNutrisiAbnormal ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}