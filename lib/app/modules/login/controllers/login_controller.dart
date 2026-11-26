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

  void checkSession() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        if (Get.currentRoute == Routes.LOGIN) {
          Get.offAllNamed(Routes.HOME);
        }
      } else {
        if (Get.currentRoute != Routes.LOGIN) {
          Get.offAllNamed(Routes.LOGIN);
        }
      }
    });
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _auth.signOut();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to log out from account',
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

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      Get.snackbar(
        'Warning',
        'Email and Password cannot be empty!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    } else if (email.isEmpty) {
      Get.snackbar(
        'Warning',
        'Email cannot be empty!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    } else if (password.isEmpty) {
      Get.snackbar(
        'Warning',
        'Password cannot be empty!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      var checkUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (checkUser.docs.isEmpty) {
        Get.snackbar(
          'Login Failed',
          'No account is registered with this email.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      String namaUser = "User";
      if (userDoc.exists && userDoc.data() != null) {
        var data = userDoc.data() as Map<String, dynamic>;
        namaUser = data['nama'] ?? "User";
      }

      Get.snackbar(
        'Login Successful',
        'Welcome back, $namaUser!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.offAllNamed(Routes.HOME);

    } on FirebaseAuthException catch (e) {
      String pesanError = 'An error occurred during login.';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesanError = 'The password you entered is incorrect.';
      } else if (e.code == 'user-not-found') {
        pesanError = 'No account is registered with this email.';
      } else if (e.code == 'invalid-email') {
        pesanError = 'Invalid email format.';
      } else if (e.code == 'too-many-requests') {
        pesanError = 'Too many failed attempts. Please try again later.';
      }

      Get.snackbar(
        'Login Failed',
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