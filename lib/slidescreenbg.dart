import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class SlideScreen extends StatefulWidget {
  const SlideScreen({super.key});

  @override
  _SlideScreenState createState() => _SlideScreenState();
}

class _SlideScreenState extends State<SlideScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> slides = [
  {
    "title": "Master New Words Daily",
    "subtitle": "Build your vocabulary with daily word practice and insights",
    "backgroundImage": "assets/images/shawarma.jpg"
  },
  {
    "title": "Ace the Spelling Bee",
    "subtitle": "Strengthen your spelling skills and boost your confidence",
    "backgroundImage": "assets/images/pizza.jpg"
  },
  {
    "title": "Track Your Vocabulary Growth",
    "subtitle": "Monitor your progress with detailed learning insights",
    "backgroundImage": "assets/images/chicken.jpg"
  },
  {
    "title": "Engaging Word Quizzes",
    "subtitle": "Challenge yourself with exciting quizzes for all grades",
    "backgroundImage": "assets/images/burger.jpg"
  }
  ];

    @override
  void initState() {
    super.initState();
    // Set status bar icons to white
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _checkLoginStatus();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goToNextSlide() {
    if (_currentIndex < slides.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _navigateToSignUp();
    }
  }

  void _goToPreviousSlide() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _navigateToSignUp() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const WelcomeScreen()));
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    // Wait for 5 seconds (or the duration of the animation)
    //await Future.delayed(const Duration(seconds: 5));

    if (userEmail != null && userEmail.isNotEmpty) {
      // If a user is logged in, navigate to the dashboard
     // await Future.delayed(const Duration(seconds: 3));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
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
            onPageChanged: _onPageChanged,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(slides[index]['backgroundImage']!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: Colors.black54, // semi-transparent overlay
                  ),
                  Positioned(
                    top: 50,
                    right: 20,
                    child: GestureDetector(
                      onTap: _navigateToSignUp,
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          slides[index]['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          slides[index]['subtitle']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 28,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                  if (index == slides.length - 1)
                    Positioned(
                      bottom: 90,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _navigateToSignUp,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 84),
                            side: const BorderSide(color: primaryColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            "Get Started",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  IconButton(
                    onPressed: _goToPreviousSlide,
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Row(
                  children: List.generate(
                    slides.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.jumpToPage(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_currentIndex < slides.length - 1)
                  IconButton(
                    onPressed: _goToNextSlide,
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.2),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
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
