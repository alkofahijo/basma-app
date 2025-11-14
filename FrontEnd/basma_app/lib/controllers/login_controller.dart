// lib/controllers/login_controller.dart (الموقع حسب مشروعك)
import 'package:basma_app/pages/home_page.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;
  var obscurePassword = true.obs;
  var errorMessage = ''.obs;

  Future<void> login() async {
    if (email.isEmpty || password.isEmpty) {
      errorMessage.value = 'الرجاء تعبئة جميع الحقول';
      return;
    }
    try {
      isLoading.value = true;
      await ApiService.login(email.value.trim(), password.value);
      final sp = await SharedPreferences.getInstance();
      print("TOKEN = ${sp.getString("token")}");

      // ✅ امسح كل المسارات السابقة وروّح لـ HomePage
      Get.offAll(() => const HomePage());
    } catch (e) {
      errorMessage.value = 'خطأ في اسم المستخدم أو كلمة المرور.';
    } finally {
      isLoading.value = false;
    }
  }

  bool get isFormValid => email.isNotEmpty && password.isNotEmpty;

  void togglePassword() {
    obscurePassword.value = !obscurePassword.value;
  }
}
