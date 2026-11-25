import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var isObscure = true.obs;

  @override
  void onReady() {
    super.onReady();
    checkSession();
  }

  // --- FUNGSI AUTO LOGIN ---
  void checkSession() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Jika user ADA dan route saat ini masih di halaman Login, pindah ke Home
        if (Get.currentRoute == Routes.LOGIN) {
          Get.offAllNamed(Routes.HOME);
        }
      } else {
        // Jika user NULL dan route saat ini bukan di halaman Login, paksa ke Login
        if (Get.currentRoute != Routes.LOGIN) {
          Get.offAllNamed(Routes.LOGIN);
        }
      }
    });
  }

  // --- FUNGSI LOGOUT ---
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _auth.signOut();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal keluar dari akun',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleObscure() {
    isObscure.value = !isObscure.value;
  }

 // --- FUNGSI UTAMA LOGIN ---
  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // 🔴 1. VALIDASI INPUT KOSONG SECARA SPESIFIK
    if (email.isEmpty && password.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Email dan Password tidak boleh kosong!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    } else if (email.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Email tidak boleh kosong!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    } else if (password.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Password tidak boleh kosong!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      // 🔍 2. CEK EMAIL TERLEBIH DAHULU DI FIRESTORE
      var checkUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (checkUser.docs.isEmpty) {
        Get.snackbar(
          'Gagal Login',
          'Akun dengan email ini belum terdaftar.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // 🔐 3. JIKA EMAIL TERDAFTAR, LANJUTKAN PROSES AUTENTIKASI
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      String namaUser = "Pengguna";
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        namaUser = data['nama'] ?? "Pengguna";
      }

      Get.snackbar(
        'Login Berhasil',
        'Selamat datang kembali, $namaUser!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.HOME);

    } on FirebaseAuthException catch (e) {
      String pesanError = 'Terjadi kesalahan saat login.';

      
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesanError = 'Password yang Anda masukkan salah.';
      } else if (e.code == 'user-not-found') {
        pesanError = 'Akun dengan email ini belum terdaftar.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Format email tidak valid.';
      } else if (e.code == 'too-many-requests') {
        pesanError = 'Terdapat terlalu banyak percobaan gagal. Coba lagi nanti.';
      }

      Get.snackbar(
        'Gagal Login',
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
}