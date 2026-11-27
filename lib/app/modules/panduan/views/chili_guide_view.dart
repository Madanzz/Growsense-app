import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/main_layout.dart';

class ChiliGuideView extends StatefulWidget {
  const ChiliGuideView({super.key});

  @override
  State<ChiliGuideView> createState() => _ChiliGuideViewState();
}

class _ChiliGuideViewState extends State<ChiliGuideView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      activeParameter: 'Panduan',
      showTabs: false,
      body: Container(
        color: const Color(0xFFEFF3EA),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                boxShadow: [
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
                  Text(
                    'guide_title'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'guide_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => setState(() {}),
                indicator: BoxDecoration(
                  color: const Color(0xFFD6E2D0),
                  borderRadius: BorderRadius.circular(1),
                ),
                labelColor: const Color(0xFF2E4F32),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                tabs: [
                  Tab(text: 'tab_sensor_target'.tr),
                  Tab(text: 'tab_growth_phase'.tr),
                  Tab(text: 'tab_troubleshooting'.tr),
                ],
              ),
            ),

            Builder(
              builder: (context) {
                switch (_tabController.index) {
                  case 0:
                    return _buildTabTargetSensor();
                  case 1:
                    return _buildTabFaseTumbuh();
                  case 2:
                    return _buildTabSolusiMasalah();
                  default:
                    return _buildTabTargetSensor();
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabTargetSensor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'guide_temp_title'.tr,
            imagePath: 'assets/images/thermometer.png',
            child: Column(
              children: [
                _MetricRow(label: 'guide_temp_ideal_lbl'.tr, value: "24°C - 28°C"),
                _MetricRow(label: 'guide_temp_max_lbl'.tr, value: 'guide_temp_max_val'.tr),
                _MetricRow(label: 'guide_temp_min_lbl'.tr, value: 'guide_temp_min_val'.tr),
              ],
            ),
          ),
          _buildInfoCard(
            title: 'guide_hum_title'.tr,
            imagePath: 'assets/images/humidity.png',
            child: Column(
              children: [
                _MetricRow(label: 'guide_hum_veg_lbl'.tr, value: "60% - 70%"),
                _MetricRow(label: 'guide_hum_gen_lbl'.tr, value: "50% - 60%"),
                _MetricRow(label: 'guide_hum_note_lbl'.tr, value: 'guide_hum_note_val'.tr),
              ],
            ),
          ),
          _buildInfoCard(
            title: 'guide_nut_title'.tr,
            imagePath: 'assets/images/nutrition.png',
            child: Column(
              children: [
                _MetricRow(label: 'guide_nut_seed_lbl'.tr, value: "300 - 500 ppm"),
                _MetricRow(label: 'guide_nut_veg_lbl'.tr, value: "800 - 1.200 ppm"),
                _MetricRow(label: 'guide_nut_flow_lbl'.tr, value: "1.500 - 2.100 ppm"),
              ],
            ),
          ),
          _buildInfoCard(
            title: 'guide_ph_title'.tr,
            imagePath: 'assets/images/ph.png',
            child: Column(
              children: [
                _MetricRow(label: 'guide_ph_opt_lbl'.tr, value: "5.8 - 6.5"),
                _MetricRow(label: 'guide_ph_acid_lbl'.tr, value: 'guide_ph_acid_val'.tr),
                _MetricRow(label: 'guide_ph_alk_lbl'.tr, value: 'guide_ph_alk_val'.tr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabFaseTumbuh() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StepCard(
            step: 'step_1'.tr,
            title: 'step_1_title'.tr,
            desc: 'step_1_desc'.tr,
            badgeColor: Colors.blue,
          ),
          _StepCard(
            step: 'step_2'.tr,
            title: 'step_2_title'.tr,
            desc: 'step_2_desc'.tr,
            badgeColor: Colors.green,
          ),
          _StepCard(
            step: 'step_3'.tr,
            title: 'step_3_title'.tr,
            desc: 'step_3_desc'.tr,
            badgeColor: Colors.orange,
          ),
          _StepCard(
            step: 'step_4'.tr,
            title: 'step_4_title'.tr,
            desc: 'step_4_desc'.tr,
            badgeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSolusiMasalah() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProblemCard(
            problem: 'prob_1'.tr,
            cause: 'prob_1_cause'.tr,
            solution: 'prob_1_sol'.tr,
          ),
          _ProblemCard(
            problem: 'prob_2'.tr,
            cause: 'prob_2_cause'.tr,
            solution: 'prob_2_sol'.tr,
          ),
          _ProblemCard(
            problem: 'prob_3'.tr,
            cause: 'prob_3_cause'.tr,
            solution: 'prob_3_sol'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String imagePath,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                imagePath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.sensors, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(height: 18),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final String desc;
  final Color badgeColor;

  const _StepCard({
    required this.step,
    required this.title,
    required this.desc,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              step,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3)),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  final String problem;
  final String cause;
  final String solution;

  const _ProblemCard({
    required this.problem,
    required this.cause,
    required this.solution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(1),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problem,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text("${'cause_prefix'.tr}: $cause", style: const TextStyle(fontSize: 11, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3EA),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              "${'action_prefix'.tr}: $solution",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2E4F32)),
            ),
          ),
        ],
      ),
    );
  }
}