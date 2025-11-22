import 'package:basma_app/pages/on_start/landing_page.dart';
import 'package:basma_app/widgets/basma_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:basma_app/theme/app_colors.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/on-boarding-1.png",
      "title": "الإبلاغ عن التشوّهات البصرية باستخدام الذكاء الاصطناعي بدقة",
      "subtitle": "التقط الصورة وحدّد الموقع خلال لحظات.",
    },
    {
      "image": "assets/images/on-boarding-2.png",
      "title": "متابعة فورية وإجراءات سريعة",
      "subtitle": "الجهات المختصة تتعامل مع بلاغك بكل كفاءة.",
    },
    {
      "image": "assets/images/on-boarding-3.png",
      "title": "نحو بيئة أجمل ومستدامة",
      "subtitle": "مشاركتك تصنع فرقًا في تحسين بلدنا.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      appBar: const BasmaAppBar(),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: size.height * 0.04,
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        onboardingData[index]["image"]!,
                        height: size.height * 0.35,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: size.height * 0.05),
                      Text(
                        onboardingData[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: size.height * 0.015),
                      Text(
                        onboardingData[index]["subtitle"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.04),
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: onboardingData.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: kPrimaryColor,
                    dotColor: Colors.grey,
                    dotHeight: 8,
                    dotWidth: 8,
                    spacing: 8,
                  ),
                ),
                SizedBox(height: size.height * 0.13),
                SizedBox(
                  width: size.width * 0.8,
                  height: size.height * 0.06,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      if (currentPage == onboardingData.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LandingPage(),
                          ),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      }
                    },
                    child: Text(
                      currentPage == onboardingData.length - 1
                          ? 'ابدأ'
                          : 'التالي',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
