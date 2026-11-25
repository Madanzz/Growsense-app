import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:growsense_1_0/app/modules/panduan/views/chili_guide_view.dart';
import 'package:growsense_1_0/app/modules/login/controllers/login_controller.dart';
import 'package:growsense_1_0/app/modules/home/controllers/home_controller.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String? activeParameter;
  final bool showTabs;
  final String activeTab;

  const MainLayout({
    super.key,
    required this.body,
    this.activeParameter,
    this.showTabs = true,
    this.activeTab = 'Nilai',
  });

  int _getCurrentIndex() {
    switch (activeParameter) {
      case 'Home':
        return 0;
      case 'Panduan':
        return 1;
      default:
        return 0;
    }
  }

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      } else if (user.email != null && user.email!.contains('@')) {
        String nameFromEmail = user.email!.split('@').first;
        return nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1);
      }
    }
    return "Pengguna";
  }

      // 🔴 DIALOG EDIT AMBANG BATAS PARAMETER & FASE (FIX PENYIMPANAN FASE) 🔴
  void _showDialogEditAmbangBatas(BuildContext context, HomeController homeController) {
    // Controller input teks untuk ambang batas umum
    final suhuMinC = TextEditingController(text: homeController.suhuMin.value.toString());
    final suhuMaxC = TextEditingController(text: homeController.suhuMax.value.toString());
    final lembapMinC = TextEditingController(text: homeController.lembapMin.value.toString());
    final lembapMaxC = TextEditingController(text: homeController.lembapMax.value.toString());
    final phMinC = TextEditingController(text: homeController.phMin.value.toString());
    final phMaxC = TextEditingController(text: homeController.phMax.value.toString());

    // Controller input teks untuk nutrisi per fase (diberi nilai default awal agar tidak terbaca 0)
    final semaiMinC = TextEditingController(text: homeController.semaiMin.value > 0 ? homeController.semaiMin.value.toString() : "400");
    final semaiMaxC = TextEditingController(text: homeController.semaiMax.value > 0 ? homeController.semaiMax.value.toString() : "600");
    final vegAwalMinC = TextEditingController(text: homeController.vegAwalMin.value > 0 ? homeController.vegAwalMin.value.toString() : "600");
    final vegAwalMaxC = TextEditingController(text: homeController.vegAwalMax.value > 0 ? homeController.vegAwalMax.value.toString() : "750");
    final vegLanjutanMinC = TextEditingController(text: homeController.vegLanjutanMin.value > 0 ? homeController.vegLanjutanMin.value.toString() : "750");
    final vegLanjutanMaxC = TextEditingController(text: homeController.vegLanjutanMax.value > 0 ? homeController.vegLanjutanMax.value.toString() : "1000");

    // Ambil data nutrisi fase terkini langsung dari Firebase saat dialog dibuka
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('pengaturan/fase');
    dbRef.get().then((snapshot) {
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        if (data['semai'] != null) {
          semaiMinC.text = (data['semai']['nutrisiMin'] ?? 400).toString();
          semaiMaxC.text = (data['semai']['nutrisiMax'] ?? 600).toString();
        }
        if (data['veg_awal'] != null) {
          vegAwalMinC.text = (data['veg_awal']['nutrisiMin'] ?? 600).toString();
          vegAwalMaxC.text = (data['veg_awal']['nutrisiMax'] ?? 750).toString();
        }
        if (data['veg_lanjutan'] != null) {
          vegLanjutanMinC.text = (data['veg_lanjutan']['nutrisiMin'] ?? 750).toString();
          vegLanjutanMaxC.text = (data['veg_lanjutan']['nutrisiMax'] ?? 1000).toString();
        }
      }
    });

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text(
                          "Edit Ambang Batas",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 6),

                // 🌡️ 1. SUHU
                const Text("Suhu (°C):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildInputField(suhuMinC, "Min (°C)")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField(suhuMaxC, "Max (°C)")),
                  ],
                ),
                const SizedBox(height: 12),

                // 💧 2. KELEMBAPAN
                const Text("Kelembapan (%):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildInputField(lembapMinC, "Min (%)")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField(lembapMaxC, "Max (%)")),
                  ],
                ),
                const SizedBox(height: 12),

                // 🧪 3. PH AIR
                const Text("pH Air:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildInputField(phMinC, "Min pH")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField(phMaxC, "Max pH")),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 6),

                // 🌱 4. NUTRISI PER FASE
                const Text("Target Nutrisi Fase (PPM):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20))),
                const SizedBox(height: 8),

                // Fase Semai
                const Text("Fase Semai:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildInputField(semaiMinC, "Min (PPM)")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField(semaiMaxC, "Max (PPM)")),
                  ],
                ),
                const SizedBox(height: 8),

                // Fase Veg Awal
                const Text("Fase Vegetatif Awal:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildInputField(vegAwalMinC, "Min (PPM)")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField(vegAwalMaxC, "Max (PPM)")),
                  ],
                ),
                const SizedBox(height: 8),

                // Fase Veg Lanjutan
                const Text("Fase Vegetatif Lanjutan:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildInputField(vegLanjutanMinC, "Min (PPM)")),
                    const SizedBox(width: 8),
                    Expanded(child: _buildInputField(vegLanjutanMaxC, "Max (PPM)")),
                  ],
                ),
                const SizedBox(height: 18),

                // 🟢 TOMBOL SIMPAN
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      // 1. VALIDASI BLACK-BOX: CEK APAKAH ADA KOLOM YANG KOSONG
                      if (suhuMinC.text.trim().isEmpty || suhuMaxC.text.trim().isEmpty ||
                          lembapMinC.text.trim().isEmpty || lembapMaxC.text.trim().isEmpty ||
                          phMinC.text.trim().isEmpty || phMaxC.text.trim().isEmpty ||
                          semaiMinC.text.trim().isEmpty || semaiMaxC.text.trim().isEmpty ||
                          vegAwalMinC.text.trim().isEmpty || vegAwalMaxC.text.trim().isEmpty ||
                          vegLanjutanMinC.text.trim().isEmpty || vegLanjutanMaxC.text.trim().isEmpty) {
                        Get.snackbar(
                          'Peringatan Validasi',
                          'Seluruh kolom ambang batas wajib diisi dan tidak boleh kosong!',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return; // Tolak simpan & dialog tetap terbuka
                      }

                      // 2. PARSE INPUT KE NUMERIK
                      double sMin = double.tryParse(suhuMinC.text) ?? 0;
                      double sMax = double.tryParse(suhuMaxC.text) ?? 0;
                      double lMin = double.tryParse(lembapMinC.text) ?? 0;
                      double lMax = double.tryParse(lembapMaxC.text) ?? 0;
                      double pMin = double.tryParse(phMinC.text) ?? 0;
                      double pMax = double.tryParse(phMaxC.text) ?? 0;

                      int semaiMin = (double.tryParse(semaiMinC.text) ?? 0).toInt();
                      int semaiMax = (double.tryParse(semaiMaxC.text) ?? 0).toInt();
                      int vegAwalMin = (double.tryParse(vegAwalMinC.text) ?? 0).toInt();
                      int vegAwalMax = (double.tryParse(vegAwalMaxC.text) ?? 0).toInt();
                      int vegLanjutanMin = (double.tryParse(vegLanjutanMinC.text) ?? 0).toInt();
                      int vegLanjutanMax = (double.tryParse(vegLanjutanMaxC.text) ?? 0).toInt();

                      // 3. VALIDASI BLACK-BOX: NILAI 0 ATAU NEGATIF
                      if (sMin <= 0 || sMax <= 0 || lMin <= 0 || lMax <= 0 || pMin <= 0 || pMax <= 0 ||
                          semaiMin <= 0 || semaiMax <= 0 || vegAwalMin <= 0 || vegAwalMax <= 0 || vegLanjutanMin <= 0 || vegLanjutanMax <= 0) {
                        Get.snackbar(
                          'Peringatan Validasi',
                          'Nilai batas parameter tidak boleh 0 atau bernilai negatif!',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return; // Tolak simpan & dialog tetap terbuka
                      }

                      // 4. VALIDASI BLACK-BOX: MIN >= MAX
                      if (sMin >= sMax || lMin >= lMax || pMin >= pMax ||
                          semaiMin >= semaiMax || vegAwalMin >= vegAwalMax || vegLanjutanMin >= vegLanjutanMax) {
                        Get.snackbar(
                          'Peringatan Validasi',
                          'Nilai batas minimum tidak boleh lebih besar atau sama dengan batas maksimum!',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return; // Tolak simpan & dialog tetap terbuka
                      }

                      // 5. TUTUP DIALOG & SIMPAN KE FIREBASE
                      Navigator.of(context).pop();

                      await homeController.updateBatasUmum(
                        sMin: sMin, sMax: sMax,
                        lMin: lMin, lMax: lMax,
                        pMin: pMin, pMax: pMax,
                      );

                      await homeController.updateBatasNutrisiFase(
                        targetFase: 'semai', nMin: semaiMin, nMax: semaiMax,
                      );

                      await homeController.updateBatasNutrisiFase(
                        targetFase: 'veg_awal', nMin: vegAwalMin, nMax: vegAwalMax,
                      );

                      await homeController.updateBatasNutrisiFase(
                        targetFase: 'veg_lanjutan', nMin: vegLanjutanMin, nMax: vegLanjutanMax,
                      );

                      Get.snackbar(
                        'Berhasil',
                        'Seluruh ambang batas parameter berhasil diperbarui!',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  // ⚙️ BOTTOM SHEET PENGATURAN SYSTEM
  void _showSettingsBottomSheet(BuildContext context) {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Color(0xFF2E7D32), size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Pengaturan Sistem",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // ☁️ ITEM 1: SINKRONISASI DRIVE
            Obx(() {
              bool isUploading = homeController.isUploadingToDrive.value;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                tileColor: const Color(0xFFF0F4F0),
                leading: isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    : const Icon(Icons.cloud_sync_outlined, color: Color(0xFF2E7D32), size: 24),
                title: Text(
                  isUploading ? "Menyinkronkan Data..." : "Sinkronkan Data ke Drive",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Unggah file log_growsense_v2.csv lokal HP ke Google Drive untuk analisis delay data.",
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                onTap: isUploading
                    ? null
                    : () async {
                        Get.back();
                        await homeController.sinkronkanKeDriveManual();
                      },
              );
            }),
            const SizedBox(height: 8),

            // 🎛️ ITEM 2: EDIT AMBANG BATAS PARAMETER & FASE
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              tileColor: const Color(0xFFF0F4F0),
              leading: const Icon(Icons.tune_rounded, color: Color(0xFF2E7D32), size: 24),
              title: const Text(
                "Ubah Ambang Batas Parameter",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                "Atur target Suhu, Kelembapan, pH, dan PPM Nutrisi untuk setiap fase tanaman.",
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              onTap: () {
                Get.back(); // Tutup bottom sheet
                _showDialogEditAmbangBatas(context, homeController); // Buka dialog edit
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // 🔔 BOTTOM SHEET LOG NOTIFIKASI
  void _showNotificationLogBottomSheet(BuildContext context) {
    final DatabaseReference dbRef = FirebaseDatabase.instance.ref('log_notifikasi');

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Color(0xFF2E7D32), size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Log Peringatan Anomali",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const Divider(),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: dbRef.orderByChild('waktuMs').limitToLast(50).onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(
                      child: Text(
                        "Belum ada riwayat peringatan anomali.",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }

                  Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List listLog = [];

                  map.forEach((key, value) {
                    listLog.add({
                      'id': key,
                      'judul': value['judul'] ?? 'Peringatan',
                      'pesan': value['pesan'] ?? '',
                      'timestamp': value['timestamp'] ?? '-',
                      'waktuMs': value['waktuMs'] ?? 0,
                    });
                  });

                  listLog.sort((a, b) => (b['waktuMs'] as int).compareTo(a['waktuMs'] as int));

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: listLog.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      var item = listLog[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                        ),
                        title: Text(
                          item['judul'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              item['pesan'],
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Waktu: ${item['timestamp']}",
                              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3EA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌿 1. TOP APP BAR
              Container(
                height: 62,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      top: -15,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 45,
                      bottom: -25,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -15,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo1.png',
                              height: 24,
                              width: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getUserDisplayName(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          
                          const Spacer(),

                          // ⚙️ IKON PENGATURAN
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            onPressed: () => _showSettingsBottomSheet(context),
                          ),
                          const SizedBox(width: 8),

                          // 🔔 IKON LONCENG NOTIFIKASI
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            onPressed: () => _showNotificationLogBottomSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. SUB-TAB MODEL SHOPEE
              if (showTabs)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildShopeeStyleTab(
                        label: 'Nilai',
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        route: '/home',
                      ),
                      _buildShopeeStyleTab(
                        label: 'Riwayat',
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history_rounded,
                        route: '/riwayat',
                      ),
                      _buildShopeeStyleTab(
                        label: 'Grafik',
                        icon: Icons.show_chart_outlined,
                        activeIcon: Icons.show_chart_rounded,
                        route: '/grafik',
                      ),
                    ],
                  ),
                ),

              // 3. KONTEN UTAMA
              body,
            ],
          ),
        ),
      ),

      // 4. BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _getCurrentIndex(),
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, height: 1.4),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 24),
              activeIcon: Icon(Icons.home_rounded, size: 24),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined, size: 24),
              activeIcon: Icon(Icons.menu_book_rounded, size: 24),
              label: 'Panduan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout_rounded, size: 24),
              label: 'Keluar',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                if (activeParameter != 'Home') {
                  Get.toNamed('/home');
                }
                break;
              case 1:
                if (activeParameter != 'Panduan') {
                  Get.to(() => const ChiliGuideView());
                }
                break;
              case 2:
                Get.defaultDialog(
                  title: "Keluar",
                  titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  middleText: "Apakah Anda yakin ingin keluar dari aplikasi?",
                  middleTextStyle: const TextStyle(fontSize: 13),
                  textCancel: "Batal",
                  textConfirm: "Keluar",
                  confirmTextColor: Colors.white,
                  buttonColor: const Color(0xFFD32F2F),
                  cancelTextColor: Colors.black87,
                  radius: 8,
                  onConfirm: () async {
                    Get.back();

                    final loginController = Get.isRegistered<LoginController>()
                        ? Get.find<LoginController>()
                        : Get.put(LoginController());

                    await loginController.logout();
                  },
                );
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildShopeeStyleTab({
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required String route,
  }) {
    bool isActive = activeTab == label;

    return InkWell(
      onTap: () {
        if (!isActive) {
          Get.toNamed(route, preventDuplicates: false);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive 
                    ? const Color(0xFF2E7D32) 
                    : const Color(0xFFF0F4F0),
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : [],
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : const Color(0xFF2E7D32),
                size: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF2E7D32) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}