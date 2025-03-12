import 'package:flutter/material.dart';


const Color primaryCol = Color.fromARGB(255, 6, 72, 122);
const Color primaryColor = Colors.deepOrange;
final Color primaryColorLight = primaryColor.withOpacity(0.4); // Lighter version

String toTitleCase(String text) {
  if (text.isEmpty) {
    return text;
  }

  return text.split(' ').map((word) {
    if (word.length > 1) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    } else {
      return word.toUpperCase();
    }
  }).join(' ');
}

String getFirstWord(String text) {
  if (text.isEmpty) {
    return '';
  }

  return text.split(' ').first;
}

Route createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Slide in from the right
        const end = Offset.zero; // Slide to the center
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
