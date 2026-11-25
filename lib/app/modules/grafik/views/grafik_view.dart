import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../widgets/main_layout.dart';
import '../controllers/grafik_controller.dart';

class GrafikView extends GetView<GrafikController> {
  const GrafikView({super.key});

  static const Color colorSuhu = Color(0xFFD97706);
  static const Color colorLembap = Color(0xFF1D4ED8);
  static const Color colorNutrisi = Color(0xFF6D28D9);
  static const Color colorPh = Color(0xFF15803D);

  @override
  Widget build(BuildContext context) {
    final String activeParam = Get.arguments ?? 'Suhu';

    return MainLayout(
      activeParameter: activeParam,
      showTabs: true,
      activeTab: 'Grafik',
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.fetchAllGrafikData(controller.selectedDate.value),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. SELECTOR PERIODE TREN
                _buildRangeSelector(),
                const SizedBox(height: 12),

                // 2. DATE PICKER DINAMIS
                _buildDatePicker(context),
                const SizedBox(height: 12),

                // 4. GRAFIK DENGAN DYNAMIC SCALING & CARDS
                _buildCombinedChart(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRangeSelector() {
    List<String> ranges = ['1 Hari', '7 Hari', '15 Hari', '1 Bulan'];
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: ranges.map((r) {
          bool isSelected = controller.selectedRange.value == r;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: InkWell(
                onTap: () => controller.changeRange(r),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.black12),
                  ),
                  child: Center(
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            bool isBulanMode = controller.selectedRange.value == '1 Bulan';
            String formattedDate = isBulanMode
                ? DateFormat('MMMM yyyy').format(controller.selectedDate.value).toUpperCase()
                : DateFormat('dd MMMM yyyy').format(controller.selectedDate.value).toUpperCase();

            return Text(
              formattedDate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            );
          }),
          InkWell(
            onTap: () async {
              bool isBulanMode = controller.selectedRange.value == '1 Bulan';

              if (isBulanMode) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    DateTime tempDate = controller.selectedDate.value;
                    return AlertDialog(
                      title: const Text("Pilih Bulan & Tahun", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      content: SizedBox(
                        height: 250,
                        width: 300,
                        child: YearPicker(
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          selectedDate: tempDate,
                          onChanged: (DateTime dateTime) {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) {
                                return SimpleDialog(
                                  title: Text("Pilih Bulan - ${dateTime.year}"),
                                  children: List.generate(12, (index) {
                                    String monthName = DateFormat('MMMM').format(DateTime(2024, index + 1));
                                    return SimpleDialogOption(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        controller.gantiTanggal(DateTime(dateTime.year, index + 1, 1));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Text(monthName, style: const TextStyle(fontSize: 15)),
                                      ),
                                    );
                                  }),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              } else {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: controller.selectedDate.value,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) controller.gantiTanggal(picked);
              }
            },
            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF4CAF50)),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
            "Tren Parameter (${controller.selectedRange.value})",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          )),
          const SizedBox(height: 12),

          _buildLegendChips(),
          const SizedBox(height: 20),

          Obx(() {
            bool showSuhu = controller.paramVisibility['Suhu'] ?? true;
            bool showLembap = controller.paramVisibility['Kelembapan'] ?? true;
            bool showNutrisi = controller.paramVisibility['Nutrisi'] ?? true;
            bool showPh = controller.paramVisibility['pH Air'] ?? true;

            String range = controller.selectedRange.value;
            int maxPoints = 30;
            if (range == '1 Hari') maxPoints = 24;
            if (range == '7 Hari') maxPoints = 7;
            if (range == '15 Hari') maxPoints = 15;
            if (range == '1 Bulan') {
              maxPoints = DateTime(controller.selectedDate.value.year, controller.selectedDate.value.month + 1, 0).day;
            }

            List<LineChartBarData> activeLineBars = [];
            List<double> allActiveValues = [];

            if (showSuhu) {
              activeLineBars.add(_buildRawLineBarData(controller.suhuSpots, colorSuhu, maxPoints));
              allActiveValues.addAll(controller.suhuSpots.where((v) => v > 0));
            }
            if (showLembap) {
              activeLineBars.add(_buildRawLineBarData(controller.lembapSpots, colorLembap, maxPoints));
              allActiveValues.addAll(controller.lembapSpots.where((v) => v > 0));
            }
            if (showNutrisi) {
              activeLineBars.add(_buildRawLineBarData(controller.nutrisiSpots, colorNutrisi, maxPoints));
              allActiveValues.addAll(controller.nutrisiSpots.where((v) => v > 0));
            }
            if (showPh) {
              activeLineBars.add(_buildRawLineBarData(controller.phSpots, colorPh, maxPoints));
              allActiveValues.addAll(controller.phSpots.where((v) => v > 0));
            }

            double calculatedMaxY = 100.0;
            if (allActiveValues.isNotEmpty) {
              double maxVal = allActiveValues.reduce((a, b) => a > b ? a : b);
              calculatedMaxY = maxVal * 1.15;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 260,
                  child: activeLineBars.isEmpty
                      ? const Center(child: Text("Semua garis disembunyikan.", style: TextStyle(color: Colors.grey)))
                      : LineChart(
                          LineChartData(
                            minX: 1,
                            maxX: maxPoints.toDouble(),
                            minY: 0,
                            maxY: calculatedMaxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                bottom: BorderSide(color: Colors.black26),
                                left: BorderSide(color: Colors.black26),
                              ),
                            ),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  interval: calculatedMaxY / 5,
                                  getTitlesWidget: (val, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: Text(
                                        val >= 100 ? "${val.toInt()}" : val.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: 24,
                                  getTitlesWidget: (val, meta) {
                                    int spotIdx = val.toInt();
                                    bool shouldShowLabel = false;

                                    if (range == '1 Hari') {
                                      shouldShowLabel = (spotIdx == 1 || spotIdx == 6 || spotIdx == 12 || spotIdx == 18 || spotIdx == 24);
                                    } else if (range == '7 Hari') {
                                      shouldShowLabel = (spotIdx == 1 || spotIdx == 3 || spotIdx == 5 || spotIdx == 7);
                                    } else if (range == '15 Hari') {
                                      shouldShowLabel = (spotIdx == 1 || spotIdx == 3 || spotIdx == 6 || spotIdx == 9 || spotIdx == 12 || spotIdx == 15);
                                    } else {
                                      shouldShowLabel = (spotIdx == 1 || spotIdx == 5 || spotIdx == 10 || spotIdx == 15 || spotIdx == 20 || spotIdx == 25 || spotIdx == 30);
                                    }

                                    if (shouldShowLabel) {
                                      String txt = range == '1 Bulan' ? "$spotIdx" : (controller.dateLabelsX[spotIdx] ?? "$spotIdx");
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          txt,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            // 🔥 PENYESUAIAN AREA SENTUH & TOUCH THRESHOLD
                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: false,
                              touchSpotThreshold: 20, // 👈 Memperluas radius toleransi sentuhan jari hingga 20px
                              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                if (event is FlTapUpEvent &&
                                    touchResponse != null &&
                                    touchResponse.lineBarSpots != null &&
                                    touchResponse.lineBarSpots!.isNotEmpty) {
                                  
                                  // Mengambil titik X dan membulatkannya ke index tanggal/jam terdekat
                                  final touchedSpot = touchResponse.lineBarSpots!.first;
                                  double selectedPoint = touchedSpot.x.roundToDouble();

                                  if (controller.selectedHour.value == selectedPoint) {
                                    controller.selectedHour.value = null;
                                  } else {
                                    controller.selectedHour.value = selectedPoint;
                                  }
                                }
                              },
                              touchTooltipData: LineTouchTooltipData(getTooltipItems: (_) => []),
                            ),
                            lineBarsData: activeLineBars,
                          ),
                        ),
                ),

                // CARD HITAM RINCIAN PERSENSOR ON-TAP
                Obx(() {
                  double? selectedPoint = controller.selectedHour.value;
                  if (selectedPoint == null) return const SizedBox.shrink();

                  int pIdx = selectedPoint.toInt();
                  String titleLabel = range == '1 Bulan'
                      ? "Tanggal $pIdx ${DateFormat('MMMM yyyy').format(controller.selectedDate.value)}"
                      : (controller.dateLabelsX[pIdx] ?? "Titik $pIdx");

                  double vSuhu = (pIdx <= controller.suhuSpots.length) ? controller.suhuSpots[pIdx - 1] : 0.0;
                  double vLembap = (pIdx <= controller.lembapSpots.length) ? controller.lembapSpots[pIdx - 1] : 0.0;
                  double vNutrisi = (pIdx <= controller.nutrisiSpots.length) ? controller.nutrisiSpots[pIdx - 1] : 0.0;
                  double vPh = (pIdx <= controller.phSpots.length) ? controller.phSpots[pIdx - 1] : 0.0;

                  return Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2022),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Detail ($titleLabel)",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            InkWell(
                              onTap: () => controller.selectedHour.value = null,
                              child: const Icon(Icons.close, color: Colors.white70, size: 18),
                            )
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 12),

                        if (showSuhu) _buildDetailRow("Suhu", "${vSuhu.toStringAsFixed(1)} °C", colorSuhu),
                        if (showLembap) _buildDetailRow("Kelembapan", "${vLembap.toStringAsFixed(1)} %", colorLembap),
                        if (showNutrisi) _buildDetailRow("Nutrisi", "${vNutrisi.toStringAsFixed(1)} PPM", colorNutrisi),
                        if (showPh) _buildDetailRow("pH Air", vPh.toStringAsFixed(1), colorPh),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // 🔥 TITIK LEBIH MUDAH TERDAPAT VISUAL HIGHLIGHT JIKA DITEKAN
  LineChartBarData _buildRawLineBarData(List<double> listData, Color color, int maxPoints) {
    List<FlSpot> spots = [];
    for (int p = 1; p <= maxPoints; p++) {
      double val = (p <= listData.length) ? listData[p - 1] : 0.0;
      spots.add(FlSpot(p.toDouble(), val));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          bool isSelected = controller.selectedHour.value == spot.x;

          return FlDotCirclePainter(
            radius: isSelected ? 6.0 : 3.5, // 👈 Membesar jika dipilih
            color: isSelected ? Colors.yellowAccent : color,
            strokeWidth: isSelected ? 2.5 : 1.0,
            strokeColor: isSelected ? Colors.black : Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildLegendChips() {
    return Obx(() {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildInteractiveChipItem("Suhu (°C)", 'Suhu', colorSuhu),
          _buildInteractiveChipItem("Kelembapan (%)", 'Kelembapan', colorLembap),
          _buildInteractiveChipItem("Nutrisi (PPM)", 'Nutrisi', colorNutrisi),
          _buildInteractiveChipItem("pH Air", 'pH Air', colorPh),
        ],
      );
    });
  }

  Widget _buildInteractiveChipItem(String label, String paramKey, Color color) {
    bool isVisible = controller.paramVisibility[paramKey] ?? true;

    return InkWell(
      onTap: () => controller.toggleParamVisibility(paramKey),
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isVisible ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isVisible ? color : Colors.grey.shade400, width: isVisible ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: isVisible ? color : Colors.grey.shade400, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isVisible ? color : Colors.grey.shade500,
                decoration: isVisible ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
      ),
    );
  }
}