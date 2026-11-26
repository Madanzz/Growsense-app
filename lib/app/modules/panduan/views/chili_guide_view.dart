import 'package:flutter/material.dart';
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
            // WHITE HEADER BANNER
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
                  const Text(
                    "Chili Cultivation Guide",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Sensor parameter targets, growth phases, & troubleshooting.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // INTERNAL NAVIGATION TAB BAR
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
                tabs: const [
                  Tab(text: "Sensor Targets"),
                  Tab(text: "Growth Phases"),
                  Tab(text: "Troubleshooting"),
                ],
              ),
            ),

            // TAB CONTENT
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

  // TAB 1: SENSOR TARGETS
  Widget _buildTabTargetSensor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: "Water & Ambient Temperature",
            imagePath: 'assets/images/thermometer.png',
            child: const Column(
              children: [
                _MetricRow(label: "Daily Ideal", value: "24°C - 28°C"),
                _MetricRow(label: "Maximum Limit", value: "32°C (Flower drop)"),
                _MetricRow(label: "Minimum Limit", value: "20°C (Slow growth)"),
              ],
            ),
          ),
          _buildInfoCard(
            title: "Air Humidity (RH)",
            imagePath: 'assets/images/humidity.png',
            child: const Column(
              children: [
                _MetricRow(label: "Vegetative (Early)", value: "60% - 70%"),
                _MetricRow(label: "Generative (Fruiting)", value: "50% - 60%"),
                _MetricRow(label: "Note", value: ">70% Prone to fungus"),
              ],
            ),
          ),
          _buildInfoCard(
            title: "Nutrient Level (PPM)",
            imagePath: 'assets/images/nutrition.png',
            child: const Column(
              children: [
                _MetricRow(label: "Seedling", value: "300 - 500 ppm"),
                _MetricRow(label: "Vegetative Phase", value: "800 - 1,200 ppm"),
                _MetricRow(label: "Flowering Phase", value: "1,500 - 2,100 ppm"),
              ],
            ),
          ),
          _buildInfoCard(
            title: "Acidity Level (pH)",
            imagePath: 'assets/images/ph.png',
            child: const Column(
              children: [
                _MetricRow(label: "Optimal pH", value: "5.8 - 6.5"),
                _MetricRow(label: "Acidic Limit", value: "< 5.5 (Calcium uptake disrupted)"),
                _MetricRow(label: "Alkaline Limit", value: "> 6.8 (Iron precipitation)"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: GROWTH PHASES
  Widget _buildTabFaseTumbuh() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _StepCard(
            step: "Phase 1",
            title: "Seeding (Days 1 - 14)",
            desc: "Keep rockwool medium moist. Maintain high humidity and provide diluted nutrients (300-500 ppm) once true leaves appear.",
            badgeColor: Colors.blue,
          ),
          _StepCard(
            step: "Phase 2",
            title: "Vegetative / Growth (Days 15 - 45)",
            desc: "Target nutrients at 800 - 1,200 ppm. Prune lateral suckers in leaf axils to strengthen the main stem.",
            badgeColor: Colors.green,
          ),
          _StepCard(
            step: "Phase 3",
            title: "Generative & Fruiting (Days 46 - 80+)",
            desc: "Increase nutrients to 1,500 - 2,100 ppm (High Potassium). Maintain pH at 6.0 - 6.5 to prevent flower drop.",
            badgeColor: Colors.orange,
          ),
          _StepCard(
            step: "Phase 4",
            title: "Harvest (Days 80+)",
            desc: "Chilies are ready to harvest when evenly red. Pick with the stem intact during morning or late afternoon.",
            badgeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  // TAB 3: TROUBLESHOOTING
  Widget _buildTabSolusiMasalah() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _ProblemCard(
            problem: "Frequent Chili Flower Drop",
            cause: "Excessive heat (>32°C), Potassium/Calcium deficiency, or overly acidic/alkaline pH.",
            solution: "Maintain pH at 6.0 - 6.5, spray foliar calcium, and use shade nets during intense sunlight.",
          ),
          _ProblemCard(
            problem: "Curled / Rolled Leaves",
            cause: "Thrips or aphid pest infestation, or excessively low air humidity.",
            solution: "Spray organic pesticide (neem oil or diluted dish soap solution) in the late afternoon.",
          ),
          _ProblemCard(
            problem: "Blossom End Rot",
            cause: "Calcium (Ca) deficiency or obstructed water pump circulation.",
            solution: "Adjust water pH to the ideal range (5.8 - 6.5) and ensure smooth water circulation.",
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
          Text("Cause: $cause", style: const TextStyle(fontSize: 11, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3EA),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              "Solution: $solution",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2E4F32)),
            ),
          ),
        ],
      ),
    );
  }
}