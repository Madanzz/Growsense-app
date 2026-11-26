import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/main_layout.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeParameter: 'Home',
      showTabs: true,
      activeTab: 'Nilai',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. LAST UPDATE BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Obx(
                () => Text(
                  "Last Update : ${controller.lastUpdateTime.value}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 1.5 COMPACT PHASE SELECTOR WIDGET
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Phase: ",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.faseAktif.value,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.green.shade800,
                          size: 18,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'semai',
                            child: Text('Seedling (${controller.semaiMin.value}-${controller.semaiMax.value} ppm)'),
                          ),
                          DropdownMenuItem(
                            value: 'veg_awal',
                            child: Text('Early Veg (${controller.vegAwalMin.value}-${controller.vegAwalMax.value} ppm)'),
                          ),
                          DropdownMenuItem(
                            value: 'veg_lanjutan',
                            child: Text('Late Veg (${controller.vegLanjutanMin.value}-${controller.vegLanjutanMax.value} ppm)'),
                          ),
                        ],
                        onChanged: (String? faseBaru) {
                          if (faseBaru != null && faseBaru != controller.faseAktif.value) {
                            controller.gantiFase(faseBaru);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 2. 2x2 SENSOR GRID
            Obx(() {
              final suhu = controller.getSuhuInfo();
              final lembap = controller.getLembapInfo();
              final nutrisi = controller.getNutrisiInfo();
              final ph = controller.getPhInfo();

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.98,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSensorCard(
                    imagePath: 'assets/images/thermometer.png',
                    title: "Temperature",
                    valObs: controller.suhuValue,
                    status: suhu["status"] ?? controller.suhuStatus.value,
                    statusColor: suhu["color"] ?? controller.suhuStatusColor.value,
                    dampak: suhu["dampak"],
                    penanganan: suhu["penanganan"],
                    unit: "°C",
                    cardThemeColor: const Color(0xFFD97706),
                  ),
                  _buildSensorCard(
                    imagePath: 'assets/images/humidity.png',
                    title: "Humidity",
                    valObs: controller.lembapValue,
                    status: lembap["status"] ?? controller.lembapStatus.value,
                    statusColor: lembap["color"] ?? controller.lembapStatusColor.value,
                    dampak: lembap["dampak"],
                    penanganan: lembap["penanganan"],
                    unit: "%",
                    cardThemeColor: const Color(0xFF1D4ED8),
                  ),
                  _buildSensorCard(
                    imagePath: 'assets/images/nutrition.png',
                    title: "Nutrient",
                    valObs: controller.nutrisiValue,
                    status: nutrisi["status"] ?? controller.nutrisiStatus.value,
                    statusColor: nutrisi["color"] ?? controller.nutrisiStatusColor.value,
                    dampak: nutrisi["dampak"],
                    penanganan: nutrisi["penanganan"],
                    unit: " ppm",
                    cardThemeColor: const Color(0xFF6D28D9),
                  ),
                  _buildSensorCard(
                    imagePath: 'assets/images/ph.png',
                    title: "Water pH",
                    valObs: controller.phValue,
                    status: ph["status"] ?? controller.phStatus.value,
                    statusColor: ph["color"] ?? controller.phStatusColor.value,
                    dampak: ph["dampak"],
                    penanganan: ph["penanganan"],
                    unit: "",
                    cardThemeColor: const Color(0xFF15803D),
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),

            // 3. OVERALL STATUS (LIVE STATUS FEED)
            Obx(() {
              if (controller.chatLogs.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "GrowSense Assistant • Live Status Feed",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${controller.chatLogs.length}/5 logs",
                          style: const TextStyle(fontSize: 9, color: Colors.black38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.chatLogs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = controller.chatLogs[index];

                        Color themeColor = const Color(0xFF2E7D32);
                        Color bubbleBgColor = const Color(0xFFE8F5E9);

                        if (item.color == "orange") {
                          themeColor = Colors.orange.shade900;
                          bubbleBgColor = const Color(0xFFFFF3E0);
                        } else if (item.color == "red") {
                          themeColor = Colors.red.shade900;
                          bubbleBgColor = const Color(0xFFFFEBEE);
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: themeColor,
                              child: Icon(
                                item.color == "red"
                                    ? Icons.warning_amber_rounded
                                    : Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: bubbleBgColor,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(6),
                                    bottomLeft: Radius.circular(6),
                                    bottomRight: Radius.circular(6),
                                  ),
                                  border: Border.all(
                                    color: themeColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.judul,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: themeColor,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          item.jam,
                                          style: const TextStyle(
                                            fontSize: 8,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.deskripsi,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    IconData? icon,
    String? imagePath,
    required String title,
    required dynamic valObs,
    required String status,
    required Color statusColor,
    String? dampak,
    String? penanganan,
    required String unit,
    required Color cardThemeColor,
  }) {
    final bool isNormal = status.toLowerCase() == 'normal';

    return Container(
      decoration: BoxDecoration(
        color: cardThemeColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (imagePath != null && imagePath.isNotEmpty)
                  Image.asset(
                    imagePath,
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  )
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 20)
                else
                  const SizedBox.shrink(),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(
              () => Text(
                "${valObs.value}$unit",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),

            Text(
              "Impact: ${dampak ?? '-'}",
              style: const TextStyle(
                fontSize: 9.5,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Action: ${penanganan ?? '-'}",
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: isNormal ? Colors.greenAccent.shade100 : Colors.yellowAccent,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}