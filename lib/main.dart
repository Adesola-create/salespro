import 'package:flutter/material.dart';
//import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';
//import 'business_info.dart';
import 'signup_page.dart';
import 'splash_screen.dart'; 
import 'login_page.dart'; 
import 'home_page.dart'; 
import 'forgot_password.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures async initialization is handled
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS System',
      home: const LoginScreen(),
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(), 
        '/home': (context) => const HomePage(),
        '/forgot_password': (context) => const ForgotPassword(),
        '/signup': (context) => const SignupScreen(), 
      //  '/setup': (context) => const SetupAccountScreen(), 
      },
    );
  }
}