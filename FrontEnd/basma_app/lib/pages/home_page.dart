import 'package:basma_app/pages/custom_widgets.dart/home_screen_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'guest/guest_select_page.dart';
import 'auth/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
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
                'Choose Your Action!',
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
                'Ready to make a difference in your community?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),

              SizedBox(height: size.height * 0.08),

              HomeScreenButton(
                icon: Icons.assignment,
                title: 'Explore Reports',
                subtitle: 'See New Available Reports.',
                onTap: () {
                  Get.to(() => GuestSelectPage());
                },
                color: Color(0xFFCAF2DB),
                iconColor: const Color.fromARGB(255, 19, 106, 32),
              ),
              SizedBox(height: size.height * 0.03),

              HomeScreenButton(
                icon: Icons.camera_alt_outlined,
                title: 'Report or Fix an Issue',
                subtitle: 'report the problem.',
                onTap: () {
                  Get.to(() => LoginPage());
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

/*import 'package:basmeh/view/CustomWidgets/footer_link.dart';
import 'package:basmeh/view/CustomWidgets/all_button.dart';
import 'package:basmeh/view/home_page_for_users.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFEFF1F1),
        title: Image.asset(
          "assets/images/logo.png",
          height: size.height * 0.05,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.04,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'Chose Your Way To Contribute',
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
                        'Together, We make our city more beautiful',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.black,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: size.height * 0.08),

                      // Citizen/User button
                      AllButton(
                        icon: Icons.camera_alt_outlined,
                        title: 'Citizen / User',
                        subtitle: 'I want to report a visual issue',
                        onTap: () {
                          // Navigate to HomePageForUsers
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePageForUsers(),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: size.height * 0.03),

                      AllButton(
                        icon: Icons.apartment_outlined,
                        title: 'Organization / Initiative',
                        subtitle:
                            'I represent a volunteer group or municipality',
                        onTap: () {},
                      ),

                      SizedBox(height: size.height * 0.27),

                      // Footer links
                      Column(
                        children: [
                          Text(
                            'Every report is a footprint towards a more beautiful city',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: size.width * 0.03,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: size.height * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FooterLink(text: 'Privacy Policy', onTap: () {}),
                              const Text('  |  '),
                              FooterLink(text: 'About', onTap: () {}),
                              const Text('  |  '),
                              FooterLink(text: 'Contact us', onTap: () {}),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} */
