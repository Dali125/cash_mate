import 'package:flutter/material.dart';
import 'package:concentric_transition/concentric_transition.dart';

class WelcomeScreens extends StatefulWidget {
  const WelcomeScreens({super.key});

  @override
  State<WelcomeScreens> createState() => _WelcomeScreensState();
}

class _WelcomeScreensState extends State<WelcomeScreens> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      

      body:  OnboardingExample(),
    );
  }
}



final pages = [
  const PageData(
    image_url : "assets/screen_1.png",
    icon: Icons.bubble_chart,
    title: "Welcome to \nCashMate",
    body: 'Track sales, manage stock, and grow your business—all in one easy-to-use app.',
    bgColor: Color(0xFF0043D0),
    textColor: Colors.white,
  ),
  const PageData(
      image_url : "assets/screen_2.png",
    icon: Icons.format_size,
    title: "Track sales, manage stock, and grow your business.",
    textColor: Colors.white,
    bgColor: Color(0xFFFDBFDD),
  ),
  const PageData(
      image_url : "assets/screen_3.png",
    icon: Icons.hdr_weak,
    title: "Send receipts via SMS or email. \nSave time, money, and the environment.",
    bgColor: Color(0xFFFFFFFF),
  ),
   const PageData(
      image_url : "assets/screen_3.png",
    icon: Icons.hdr_weak,
    title: "Send receipts via SMS or email. \nSave time, money, and the environment.",
    bgColor: Color.fromARGB(255, 144, 255, 140),
  ),
];

class OnboardingExample extends StatelessWidget {
  const OnboardingExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ConcentricPageView(
        colors: pages.map((p) => p.bgColor).toList(),
        radius: screenWidth * 0.1,
        // curve: Curves.ease,
        nextButtonBuilder: (context) => Padding(
          padding: const EdgeInsets.only(left: 3, top: 3), // visual center
          child: Icon(
            Icons.navigate_next,
            size: screenWidth * 0.08,
          ),
        ),
         itemCount: pages.length,
         onFinish: () {
           Navigator.pushNamed(context, '/');
         },
        // duration: const Duration(milliseconds: 1500),
        // opacityFactor: 2.0,
        // scaleFactor: 0.2,
        // verticalPosition: 0.7,
        // direction: Axis.vertical,
        // itemCount: pages.length,
        // physics: NeverScrollableScrollPhysics(),
        itemBuilder: (index) {
          final page = pages[index % pages.length];
          return SafeArea(
            child: _Page(page: page),
          );
        },
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

  const _Page({Key? key, required this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    space(double p) => SizedBox(height: screenHeight * p / 100);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          space(4),
          _Text(
            page: page,
            style: TextStyle(
              fontSize: screenHeight * 0.04,
            ),
          ),
           space(6),
         
       
          _Image(
            page: page,
            size: 300,
            iconSize: 170,
          ),
          space(4),
          
        
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
        // .withBlue(page.bgColor.blue - 40)
        .withGreen(page.bgColor.green + 20)
        .withRed(page.bgColor.red - 100)
        .withAlpha(90);

    final icon1Color =
        page.bgColor.withBlue(page.bgColor.blue - 10).withGreen(220);
    final icon2Color = page.bgColor.withGreen(66).withRed(77);
    final icon3Color = page.bgColor.withRed(111).withGreen(220);

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
         
         
        
          Image.asset( page.image_url!),
        
        ],
      ),
    );
  }
}