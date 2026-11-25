import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controller Form
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observable Variables
  var isLoading = false.obs;
  var isObscurePassword = true.obs;
  var isObscureConfirmPassword = true.obs;

  void toggleObscurePassword() {
    isObscurePassword.value = !isObscurePassword.value;
  }

  void toggleObscureConfirmPassword() {
    isObscureConfirmPassword.value = !isObscureConfirmPassword.value;
  }

  // --- FUNGSI REGISTRASI ---
  Future<void> register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    // 1. Validasi Field Kosong
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Semua bidang data harus diisi!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 2. Validasi Konfirmasi Password
    if (password != confirmPassword) {
      Get.snackbar(
        'Peringatan',
        'Konfirmasi password tidak cocok dengan password!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    // 3. Validasi Panjang Password Minimal 6 Karakter
    if (password.length < 6) {
      Get.snackbar(
        'Peringatan',
        'Password minimal harus 6 karakter!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // 4. Buat Akun Baru di Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Update Display Name di Firebase Auth Profile
        await user.updateDisplayName(name);

        // 5. Simpan Data Profil Pengguna ke Firestore Database
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'nama': name,
          'email': email,
          'role': 'user',
          'created_at': FieldValue.serverTimestamp(),
        });

        Get.snackbar(
          'Registrasi Berhasil',
          'Akun berhasil dibuat. Selamat datang, $name!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Langsung masuk ke Halaman Utama
        Get.offAllNamed(Routes.HOME);
      }
    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan saat pendaftaran.';

      if (e.code == 'email-already-in-use') {
        pesanError = 'Email ini sudah terdaftar. Silakan gunakan email lain atau login.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        pesanError = 'Password terlalu lemah. Gunakan kombinasi huruf dan angka.';
      }

      Get.snackbar(
        'Gagal Registrasi',
        pesanError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}