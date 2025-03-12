import 'package:flutter/material.dart';

import 'constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'home_page.dart';
// import 'constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _typingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    _navigateToIntro();
  }

  

  Future<void> _navigateToIntro() async {
    await Future.delayed(const Duration(seconds:6));
    Navigator.pushReplacementNamed(
        context, '/login'); // Updated to navigate to IntroScreen
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: primaryColor, // Change this to your primary color
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo at the top
              // Image.asset(
              //   'assets/images/burger.jpg',
              //   height: 160, // Adjust the size of the logo as needed
              // ),
              // const SizedBox(height: 2), // Add spacing between the logo and the text
              // Animated text
              AnimatedBuilder(
                animation: _typingAnimation,
                builder: (context, child) {
                  return Text(
                    'Salespro'.substring(
                        0, (_typingAnimation.value * 'SalesPro'.length).ceil()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
