// lib/pages/on_start/forgot_credentials_help_page.dart

import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotCredentialsHelpPage extends StatelessWidget {
  const ForgotCredentialsHelpPage({super.key});

  static const String _phoneDisplay = '0782558012';
  static final Uri _whatsAppUri = Uri.parse('https://wa.me/962782558012');

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      if (await canLaunchUrl(_whatsAppUri)) {
        await launchUrl(_whatsAppUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // ❌ بدون const لتجنب خطأ const
            content: const Text('تعذّر فتح تطبيق واتساب، حاول لاحقاً.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: BasmaAppBar(showBack: true, onBack: () => Get.back()),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المساعدة في استعادة الحساب',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              const Text(
                'إذا نسيت اسم المستخدم أو كلمة المرور، أو إذا كان هناك حساب غير صحيح مربوط برقم هاتفك، يرجى اتباع الخطوات التالية.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              SizedBox(height: size.height * 0.03),

              // ===== بطاقة الشرح الرئيسية =====
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: kPrimaryColor,
                            child: Icon(
                              Icons.lock_reset,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'كيف نستعيد حسابك بأمان؟',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'نحن لا نوفّر حاليًا خيار استعادة كلمة المرور من داخل التطبيق مباشرة، وذلك حفاظًا على أمان حسابك. بدلاً من ذلك، يمكنك استعادة الوصول لحسابك عن طريق التواصل معنا عبر واتساب:',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // رقم الواتساب
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_outlined, // ✅ بدل Icons.whatsapp
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'تواصل معنا واتساب على الرقم:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _phoneDisplay,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 24),

                      const Text(
                        'عند التواصل معنا، يرجى الالتزام بما يلي:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const _BulletPoint(
                        text:
                            'يجب أن يكون التواصل من نفس رقم الهاتف المربوط بالحساب داخل التطبيق.',
                      ),
                      const _BulletPoint(
                        text:
                            'إرفاق صورة واضحة عن الهوية الشخصية (الوجه والاسم ورقم الهوية ظاهرين بوضوح).',
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        'ما الذي سنقوم به بعد ذلك؟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        '١) في حال نسيان اسم المستخدم أو كلمة المرور:\n'
                        '• نتحقق من تطابق رقم الهاتف مع بيانات الحساب.\n'
                        '• بعد التأكد من الهوية، نقوم بإعادة تعيين اسم المستخدم وكلمة المرور.\n'
                        '• نرسل لك بيانات الدخول الجديدة عبر نفس رقم الواتساب الذي تواصلت منه.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        '٢) في حال قام شخص آخر بإنشاء حساب مستخدم برقم هاتفك دون إذنك:\n'
                        '• نتحقق من الهوية باستخدام صورة الهوية الشخصية.\n'
                        '• نقوم بحذف الحساب المربوط برقم هاتفك بشكل نهائي.\n'
                        '• بعد الحذف، يمكنك إنشاء حساب جديد برقمك من داخل التطبيق.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'نقوم بهذه الخطوات لضمان حماية بياناتك ومنع أي استخدام غير مصرح به لرقم هاتفك أو حسابك داخل تطبيق بصمة.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.03),

              // زر فتح واتساب
              Center(
                child: SizedBox(
                  width: size.width * 0.7,
                  height: size.height * 0.055,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(context),
                    icon: const Icon(
                      Icons.chat_outlined, // ✅ بدل Icons.whatsapp
                    ),
                    label: const Text(
                      'فتح واتساب والتواصل معنا',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
