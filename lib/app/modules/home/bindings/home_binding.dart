import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true memastikan data chatLogs & listener stream Firebase
    // TETAP AKTIF dan TIDAK DIHAPUS dari RAM saat kamu berpindah ke halaman lain!
    Get.lazyPut<HomeController>(
      () => HomeController(),
      fenix: true,
    );
  }
}