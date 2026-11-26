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
                _buildRangeSelector(),
                const SizedBox(height: 12),
                _buildDatePicker(context),
                const SizedBox(height: 12),
                _ZoomableCombinedChart(controller: controller),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRangeSelector() {
    List<String> ranges = ['1 Day', '7 Days', '15 Days', '1 Month'];
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
            bool isBulanMode = controller.selectedRange.value == '1 Month';
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
              bool isBulanMode = controller.selectedRange.value == '1 Month';

              if (isBulanMode) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    DateTime tempDate = controller.selectedDate.value;
                    return AlertDialog(
                      title: const Text("Select Month & Year", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  title: Text("Select Month - ${dateTime.year}"),
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
}

class _ZoomableCombinedChart extends StatefulWidget {
  final GrafikController controller;

  const _ZoomableCombinedChart({required this.controller});

  @override
  State<_ZoomableCombinedChart> createState() => _ZoomableCombinedChartState();
}

class _ZoomableCombinedChartState extends State<_ZoomableCombinedChart> {
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale + 0.5).clamp(1.0, 4.0);
      _transformController.value = Matrix4.identity()
        ..scaleByDouble(_currentScale, _currentScale, 1.0, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - 0.5).clamp(1.0, 4.0);
      if (_currentScale == 1.0) {
        _transformController.value = Matrix4.identity();
      } else {
        _transformController.value = Matrix4.identity()
          ..scaleByDouble(_currentScale, _currentScale, 1.0, 1.0);
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() => Text(
                  "Parameter Trend (${controller.selectedRange.value})",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                )),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildZoomButton(
                      icon: Icons.zoom_out_rounded,
                      onTap: _currentScale > 1.0 ? _zoomOut : null,
                    ),
                    InkWell(
                      onTap: _currentScale > 1.0 ? _resetZoom : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                        child: Text(
                          "${_currentScale.toStringAsFixed(1)}x",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _currentScale > 1.0 ? const Color(0xFF2E7D32) : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    _buildZoomButton(
                      icon: Icons.zoom_in_rounded,
                      onTap: _currentScale < 4.0 ? _zoomIn : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentScale > 1.0)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Drag chart with 1 finger • Tap scale value to reset",
                style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontStyle: FontStyle.italic),
              ),
            ),
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
            if (range == '1 Day') maxPoints = 24;
            if (range == '7 Days') maxPoints = 7;
            if (range == '15 Days') maxPoints = 15;
            if (range == '1 Month') {
              maxPoints = DateTime(controller.selectedDate.value.year, controller.selectedDate.value.month + 1, 0).day;
            }

            List<LineChartBarData> activeLineBars = [];
            List<double> allActiveValues = [];

            if (showSuhu) {
              activeLineBars.add(_buildRawLineBarData(controller.suhuSpots, GrafikView.colorSuhu, maxPoints));
              allActiveValues.addAll(controller.suhuSpots.where((v) => v > 0));
            }
            if (showLembap) {
              activeLineBars.add(_buildRawLineBarData(controller.lembapSpots, GrafikView.colorLembap, maxPoints));
              allActiveValues.addAll(controller.lembapSpots.where((v) => v > 0));
            }
            if (showNutrisi) {
              List<double> scaledNutrisi = controller.nutrisiSpots.map((v) => v / 100.0).toList();
              activeLineBars.add(_buildRawLineBarData(scaledNutrisi, GrafikView.colorNutrisi, maxPoints));
              allActiveValues.addAll(scaledNutrisi.where((v) => v > 0));
            }
            if (showPh) {
              activeLineBars.add(_buildRawLineBarData(controller.phSpots, GrafikView.colorPh, maxPoints));
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
                      ? const Center(child: Text("All lines are hidden.", style: TextStyle(color: Colors.grey)))
                      : ClipRect(
                          child: InteractiveViewer(
                            transformationController: _transformController,
                            minScale: 1.0,
                            maxScale: 4.0,
                            panEnabled: _currentScale > 1.0,
                            scaleEnabled: false,
                            onInteractionEnd: (_) {
                              setState(() {
                                _currentScale = _transformController.value.getMaxScaleOnAxis();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                              child: LineChart(
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

                                          if (range == '1 Day') {
                                            shouldShowLabel = (spotIdx == 1 || spotIdx == 6 || spotIdx == 12 || spotIdx == 18 || spotIdx == 24);
                                          } else if (range == '7 Days') {
                                            shouldShowLabel = (spotIdx == 1 || spotIdx == 3 || spotIdx == 5 || spotIdx == 7);
                                          } else if (range == '15 Days') {
                                            shouldShowLabel = (spotIdx == 1 || spotIdx == 3 || spotIdx == 6 || spotIdx == 9 || spotIdx == 12 || spotIdx == 15);
                                          } else {
                                            shouldShowLabel = (spotIdx == 1 || spotIdx == 5 || spotIdx == 10 || spotIdx == 15 || spotIdx == 20 || spotIdx == 25 || spotIdx == 30);
                                          }

                                          if (shouldShowLabel) {
                                            String txt = range == '1 Month' ? "$spotIdx" : (controller.dateLabelsX[spotIdx] ?? "$spotIdx");
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
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    handleBuiltInTouches: false,
                                    touchSpotThreshold: 20,
                                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                                      if (event is FlTapUpEvent &&
                                          touchResponse != null &&
                                          touchResponse.lineBarSpots != null &&
                                          touchResponse.lineBarSpots!.isNotEmpty) {
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
                          ),
                        ),
                ),

                Obx(() {
                  double? selectedPoint = controller.selectedHour.value;
                  if (selectedPoint == null) return const SizedBox.shrink();

                  int pIdx = selectedPoint.toInt();
                  String titleLabel = range == '1 Month'
                      ? "Day $pIdx ${DateFormat('MMMM yyyy').format(controller.selectedDate.value)}"
                      : (controller.dateLabelsX[pIdx] ?? "Point $pIdx");

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

                        if (showSuhu) _buildDetailRow("Temperature", "${vSuhu.toStringAsFixed(1)} °C", GrafikView.colorSuhu),
                        if (showLembap) _buildDetailRow("Humidity", "${vLembap.toStringAsFixed(1)} %", GrafikView.colorLembap),
                        if (showNutrisi)
                          _buildDetailRow(
                            "Nutrient",
                            "${vNutrisi.toStringAsFixed(1)} PPM (${(vNutrisi / 100).toStringAsFixed(2)} ×10²)",
                            GrafikView.colorNutrisi,
                          ),
                        if (showPh) _buildDetailRow("Water pH", vPh.toStringAsFixed(1), GrafikView.colorPh),
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

  Widget _buildZoomButton({required IconData icon, required VoidCallback? onTap}) {
    bool isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled ? const Color(0xFF2E7D32) : Colors.grey.shade400,
        ),
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

  LineChartBarData _buildRawLineBarData(List<double> listData, Color color, int maxPoints) {
    List<FlSpot> spots = [];
    for (int p = 1; p <= maxPoints; p++) {
      double val = (p <= listData.length) ? listData[p - 1] : 0.0;
      spots.add(FlSpot(p.toDouble(), val));
    }

    return LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          bool isSelected = widget.controller.selectedHour.value == spot.x;

          return FlDotCirclePainter(
            radius: isSelected ? 6.0 : 3.5,
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
          _buildInteractiveChipItem("Temperature (°C)", 'Suhu', GrafikView.colorSuhu),
          _buildInteractiveChipItem("Humidity (%)", 'Kelembapan', GrafikView.colorLembap),
          _buildInteractiveChipItem("Nutrient (×10² PPM)", 'Nutrisi', GrafikView.colorNutrisi),
          _buildInteractiveChipItem("Water pH", 'pH Air', GrafikView.colorPh),
        ],
      );
    });
  }

  Widget _buildInteractiveChipItem(String label, String paramKey, Color color) {
    final controller = widget.controller;
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