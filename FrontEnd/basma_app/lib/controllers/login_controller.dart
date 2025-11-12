import 'package:basma_app/pages/report/select_location_page.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';

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
      Get.to(() => const SelectLocationPage());
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
