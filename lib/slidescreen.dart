import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome_screen.dart';
//import 'constants.dart';

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
      "title": "Exam preparations made easy",
      "subtitle": "Highly organized approach for getting set for exams",
      "backgroundImage": "assets/images/burger.jpg",
    },
    {
      "title": "Detailed performance statistics",
      "subtitle": "Helps you understand your strengths and weaknesses",
      "backgroundImage": "assets/images/salad.jpg",
    },
    {
      "title": "Real-time Exam prep tracking",
      "subtitle": "Know how close you are to your desired grades",
      "backgroundImage": "assets/images/pizza.jpg",
    },
    {
      "title": "Well trained & specialized AI Tutors",
      "subtitle": "AI Tutor with accurate answers to general & complex questions",
      "backgroundImage": "assets/images/chicken.jpg",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set status bar icons to white
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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
                  Container(
                    color: Colors.purple,
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
                        horizontal: 20, vertical: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          slides[index]['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
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
                            fontSize: 32,
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
                            side: const BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            backgroundColor: Colors.purple,
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
