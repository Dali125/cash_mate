import 'package:cash_app/db/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:concentric_transition/concentric_transition.dart';

class WelcomeScreens extends StatelessWidget {
  const WelcomeScreens({super.key});
  @override
  Widget build(BuildContext context) {
    return const OnboardingExample();
  }
}

final pages = [
  const PageData(
    image_url: "assets/screen_1.png",
    icon: Icons.bubble_chart,
    title: "Welcome to \nCashMate",
    body:
        'Track sales, manage stock, and grow your business—all in one easy-to-use app.',
    bgColor: Color(0xFF0043D0),
    textColor: Colors.white,
  ),
  const PageData(
    image_url: "assets/screen_2.png",
    icon: Icons.format_size,
    title: "Inventory & Sales",
    body:
        'Effortlessly record sales and monitor inventory levels in real time.',
    textColor: Colors.white,
    bgColor: Color(0xFFFDBFDD),
  ),
  const PageData(
    image_url: "assets/screen_3.png",
    icon: Icons.hdr_weak,
    title: "Smart Insights",
    body: 'Analyze performance with simple charts to grow faster.',
    bgColor: Color(0xFFFFFFFF),
  ),
  const PageData(
    image_url: "assets/screen_3.png",
    icon: Icons.receipt_long,
    title: "Digital Receipts",
    body: 'Send receipts via SMS or email. Save time, money & the environment.',
    bgColor: Color.fromARGB(255, 144, 255, 140),
  ),
];

class OnboardingExample extends StatelessWidget {
  const OnboardingExample({Key? key}) : super(key: key);

  void _finish(BuildContext context) async {
    final db = Get.find<Config>();
    await db.updateNumberOfLogins();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          ConcentricPageView(
            colors: pages.map((p) => p.bgColor).toList(),
            radius: screenWidth * 0.1,
            nextButtonBuilder: (context) => Padding(
              padding: const EdgeInsets.only(left: 3, top: 3), // visual center
              child: Icon(
                Icons.navigate_next,
                size: screenWidth * 0.08,
              ),
            ),
            itemCount: pages.length,
            onFinish: () => _finish(context),
            itemBuilder: (index) {
              final page = pages[index % pages.length];
              final isLast = index == pages.length - 1;
              return SafeArea(
                child: _Page(
                    page: page,
                    isLast: isLast,
                    onFinish: () => _finish(context)),
              );
            },
          ),
          Positioned(
            top: 12,
            right: 8,
            child: SafeArea(
              child: TextButton(
                onPressed: () => _finish(context),
                child: const Text('Skip'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageData {
  final String? image_url;
  final String? title;
  final IconData? icon;
  final String? body;
  final Color bgColor;
  final Color textColor;

  const PageData({
    this.image_url,
    this.title,
    this.icon,
    this.body,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}

class _Page extends StatelessWidget {
  final PageData page;
  final bool isLast;
  final VoidCallback onFinish;

  const _Page(
      {Key? key,
      required this.page,
      required this.isLast,
      required this.onFinish})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    space(double p) => SizedBox(height: screenHeight * p / 100);
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          space(2),
          _Text(
            page: page,
            style: TextStyle(
              fontSize: screenHeight * 0.04,
            ),
          ),
          space(2),
          if (page.body != null)
            Text(
              page.body!,
              style: TextStyle(
                color: page.textColor.withOpacity(0.9),
                fontSize: 16,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          space(6),
          _Image(
            page: page,
            size: 300,
            iconSize: 170,
          ),
          const Spacer(),
          if (isLast)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: page.textColor.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                  foregroundColor: page.textColor.computeLuminance() > 0.5
                      ? Colors.white
                      : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onFinish,
                child: const Text('Get Started'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    Key? key,
    required this.page,
    this.style,
  }) : super(key: key);

  final PageData page;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      page.title ?? '',
      style: TextStyle(
        color: page.textColor,
        fontWeight: FontWeight.w600,
        fontFamily: 'Helvetica',
        letterSpacing: 0.0,
        fontSize: 18,
        height: 1.2,
      ).merge(style),
      textAlign: TextAlign.center,
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({
    Key? key,
    required this.page,
    required this.size,
    required this.iconSize,
  }) : super(key: key);

  final PageData page;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bgColor = page.bgColor
        .withGreen(page.bgColor.green + 20)
        .withRed(page.bgColor.red - 100)
        .withAlpha(90);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(60.0)),
        color: bgColor,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Image.asset(page.image_url ?? ''),
        ],
      ),
    );
  }
}
