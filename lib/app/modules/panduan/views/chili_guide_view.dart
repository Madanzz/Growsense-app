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
      showTabs: false, // Mematikan tab Nilai | Riwayat | Grafik di halaman Panduan
      body: Container(
        color: const Color(0xFFEFF3EA),
        child: Column(
          children: [
            // ⚪ BANNER HEADER PUTIH (TANPA LOGO)
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
                    "Panduan Budidaya Cabai",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Target parameter sensor, fase tumbuh, & penanganan masalah.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // TAB BAR NAVIGASI INTERNAL
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
                  Tab(text: "Target Sensor"),
                  Tab(text: "Fase Tumbuh"),
                  Tab(text: "Troubleshooting"),
                ],
              ),
            ),

            // ISI TAB
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

  // TAB 1: TARGET SENSOR (PAKAI GAMBAR LOGO DARI ASSETS/IMAGES/)
  Widget _buildTabTargetSensor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: "Suhu Air & Lingkungan",
            imagePath: 'assets/images/thermometer.png',
            child: const Column(
              children: [
                _MetricRow(label: "Ideal Harian", value: "24°C - 28°C"),
                _MetricRow(label: "Batas Maksimal", value: "32°C (Bunga rontok)"),
                _MetricRow(label: "Batas Minimal", value: "20°C (Tumbuh lambat)"),
              ],
            ),
          ),
          _buildInfoCard(
            title: "Kelembapan Udara (RH)",
            imagePath: 'assets/images/humidity.png',
            child: const Column(
              children: [
                _MetricRow(label: "Vegetatif (Awal)", value: "60% - 70%"),
                _MetricRow(label: "Generatif (Buah)", value: "50% - 60%"),
                _MetricRow(label: "Catatan", value: ">70% Rawan jamur"),
              ],
            ),
          ),
          _buildInfoCard(
            title: "Kadar Nutrisi (PPM)",
            imagePath: 'assets/images/nutrition.png',
            child: const Column(
              children: [
                _MetricRow(label: "Semaian / Bibit", value: "300 - 500 ppm"),
                _MetricRow(label: "Fase Vegetatif", value: "800 - 1.200 ppm"),
                _MetricRow(label: "Fase Pembungaan", value: "1.500 - 2.100 ppm"),
              ],
            ),
          ),
          _buildInfoCard(
            title: "Derajat Keasaman (pH)",
            imagePath: 'assets/images/ph.png',
            child: const Column(
              children: [
                _MetricRow(label: "pH Optimal", value: "5.8 - 6.5"),
                _MetricRow(label: "Batas Asam", value: "< 5.5 (Serapan Kalsium terganggu)"),
                _MetricRow(label: "Batas Basa", value: "> 6.8 (Unsur Zat Besi terendap)"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: FASE TUMBUH
  Widget _buildTabFaseTumbuh() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _StepCard(
            step: "Fase 1",
            title: "Penyemaian (Hari 1 - 14)",
            desc: "Media rockwool basah. Jaga kelembapan tinggi dan beri nutrisi tipis (300-500 ppm) setelah daun sejati muncul.",
            badgeColor: Colors.blue,
          ),
          _StepCard(
            step: "Fase 2",
            title: "Vegetatif / Pertumbuhan (Hari 15 - 45)",
            desc: "Target nutrisi 800 - 1.200 ppm. Lakukan perempelan tunas air di ketiak daun agar batang utama kokoh.",
            badgeColor: Colors.green,
          ),
          _StepCard(
            step: "Fase 3",
            title: "Generatif & Pembuahan (Hari 46 - 80+)",
            desc: "Tingkatkan nutrisi hingga 1.500 - 2.100 ppm (Tinggi Kalium). Jaga pH di 6.0 - 6.5 agar bunga tidak rontok.",
            badgeColor: Colors.orange,
          ),
          _StepCard(
            step: "Fase 4",
            title: "Panen (Hari 80+)",
            desc: "Cabai siap dipanen saat berwarna merah merata. Petik bersama tangkainya pada pagi/sore hari.",
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
            problem: "Bunga Cabai Sering Rontok",
            cause: "Suhu terlalu panas (>32°C), kekurangan Kalium/Kalsium, atau pH terlampau asam/basa.",
            solution: "Jaga pH 6.0 - 6.5, semprot kalsium foliar, dan gunakan paranet jika terik.",
          ),
          _ProblemCard(
            problem: "Daun Keriting / Menggulung",
            cause: "Serangan hama thrips/kutu daun, atau kelembapan udara terlalu rendah.",
            solution: "Semprot pestisida nabati (minyak mimba/air sabun cuci piring tipis) sore hari.",
          ),
          _ProblemCard(
            problem: "Busuk Ujung Buah (Blossom End Rot)",
            cause: "Defisiensi Kalsium (Ca) atau sirkulasi pompa air terhambat.",
            solution: "Koreksi pH air ke batas ideal (5.8 - 6.5) & pastikan sirkulasi air lancar.",
          ),
        ],
      ),
    );
  }

  // WIDGET CARD MENGGUNAKAN IMAGE PATH ASSETS
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

// COMPONENT HELPER WIDGETS
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
          Text("Penyebab: $cause", style: const TextStyle(fontSize: 11, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3EA),
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              "Solusi: $solution",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2E4F32)),
            ),
          ),
        ],
      ),
    );
  }
}