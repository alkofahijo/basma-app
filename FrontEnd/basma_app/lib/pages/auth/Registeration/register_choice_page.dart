import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:basma_app/widgets/custom_option_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Citizins/register_citizen_page.dart';
import 'initiatives/register_initiative_info_page.dart';

class RegisterChoicePage extends StatelessWidget {
  const RegisterChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: const BasmaAppBar(showBack: true),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06,
          vertical: size.height * 0.04,
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                'نوع الحساب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.090,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
              SizedBox(height: size.height * 0.015),
              Text(
                'اختر نوع الحساب الذي تريد إنشاؤه',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
              SizedBox(height: size.height * 0.08),
              HomeScreenButton(
                icon: Icons.person,
                title: 'مواطن',
                subtitle: 'انت مستخدم عادي',
                onTap: () {
                  Get.to(() => RegisterCitizenPage());
                },
                color: const Color(0xFFCAF2DB),
                iconColor: const Color.fromARGB(255, 19, 106, 32),
              ),
              SizedBox(height: size.height * 0.03),
              HomeScreenButton(
                icon: Icons.business,
                title: 'مبادرة/بلدية',
                subtitle: 'تمثل مبادرة او بلدية',
                onTap: () {
                  Get.to(() => RegisterInitiativeInfoPage());
                },
                color: const Color(0xFFCAE6F2),
                iconColor: const Color.fromARGB(255, 10, 62, 104),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
