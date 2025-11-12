import 'package:basma_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
      "title": "أبلغ عن التلوث البصري بسهولة",
      "subtitle": "التقط وأرسل الموقع في ثوانٍ.",
    },
    {
      "image": "assets/images/on-boarding-2.png",
      "title": "فرق الصيانة سريعة الاستجابة",
      "subtitle": "نعمل معًا لتحسين مدينتنا للجميع.",
    },
    {
      "image": "assets/images/on-boarding-3.png",
      "title": "مدينة أنظف وأكثر خضرة",
      "subtitle": "نبني غدًا مستدامًا.",
    },
  ];

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
      body: SafeArea(
        child: Column(
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
                        // SizedBox(height: size.height * 0.05),
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
                            fontSize: size.width * 0.06,
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

            // Bottom section
            Padding(
              padding: EdgeInsets.only(bottom: size.height * 0.04),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: onboardingData.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Color(0xFF008000),
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
                        backgroundColor: const Color(0xFF008000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        if (currentPage == onboardingData.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
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
      ),
    );
  }
}
