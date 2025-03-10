import 'package:flutter/material.dart';
import 'package:velora/presentation/screens/0Auth/login.dart';
import 'package:velora/presentation/widgets/reusable_wdgts.dart';
import 'package:velora/core/configs/theme/app_colors.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "PLAN",
      subtitle: "your route, ride\nschedule, and your\nbike buddies.",
      image: "assets/images/image1.png",
      buttonText: "Next",
    ),
    OnboardingContent(
      title: "TRACK",
      subtitle: "the weather and\ntraffic along your\nroute.",
      image: "assets/images/image2.png",
      buttonText: "Next",
    ),
    OnboardingContent(
      title: "SHARE",
      subtitle: "the experience and\nyour journey with\nVELORA",
      image: "assets/images/image3.png",
      buttonText: "Get Started",
    ),
  ];

  void _onButtonPressed() {
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _contents.length,
            itemBuilder: (context, index) {
              final content = _contents[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 0),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                    ),
                    const SizedBox(height: 0),
                    CustomTitleText(text: content.title),
                    const SizedBox(height: 0),
                    CustomSubtitleText(text: content.subtitle),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          content.image,
                          height: 400,
                          width: 400,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _contents.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Center(
              child: CustomButton(
                text: _contents[_currentPage].buttonText,
                onPressed: _onButtonPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String image;
  final String buttonText;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.buttonText,
  });
}
