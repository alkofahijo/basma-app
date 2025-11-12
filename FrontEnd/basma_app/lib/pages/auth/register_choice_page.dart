import 'package:basma_app/pages/custom_widgets.dart/home_screen_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_citizen_page.dart';
import 'register_initiative_info.dart';

class RegisterChoicePage extends StatelessWidget {
  const RegisterChoicePage({super.key});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEFF1F1),
        title: Image.asset(
          "assets/images/logo-arabic-side.png",
          height: size.height * 0.05,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.06,
          vertical: size.height * 0.04,
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                'Type of Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.090,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),

              SizedBox(height: size.height * 0.015),

              // Subtitle
              Text(
                'Choose the type of account you want to create',
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
                title: 'Citizen',
                subtitle: 'You\'re an individual',
                onTap: () {
                  Get.to(() => RegisterCitizenPage());
                },
                color: Color(0xFFCAF2DB),
                iconColor: const Color.fromARGB(255, 19, 106, 32),
              ),
              SizedBox(height: size.height * 0.03),

              HomeScreenButton(
                icon: Icons.business,
                title: 'Initiative',
                subtitle: 'You represent an organization',
                onTap: () {
                  Get.to(() => RegisterInitiativeInfoPage());
                },
                color: Color(0xFFCAE6F2),
                iconColor: const Color.fromARGB(255, 10, 62, 104),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
