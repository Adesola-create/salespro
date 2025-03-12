import 'package:flutter/material.dart';
import 'constants.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For jsonDecode
// import 'signup_page.dart';
//import 'forgot_password.dart';

import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // State for password visibility
  String business = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');
    String business1 = prefs.getString('business') ?? '';

    if (userEmail != null && userEmail.isNotEmpty) {
      // If a user is logged in, navigate to the dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
    setState(() {
      business = business1;
    });
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    final Uri url = Uri.parse('https://salespro.livepetal.com/v1/login');

    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'password': password,
        },
        headers: {},
      ).timeout(const Duration(seconds: 60));

      // print(response.body);
      final data = jsonDecode(response.body);
      final user = data['data'];
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          //await prefs.setString('userData', jsonEncode(user));
          await prefs.setString('userId', user['id']);
          await prefs.setString(
              'userName', '${user['firstname']} ${user['lastname']}');
          await prefs.setString('userEmail', user['email']);
          await prefs.setString('userPhone', user['phone']);
          await prefs.setString('apiKey', user['apikey']);
          await prefs.setString('bid', user['bid']);

          await prefs.setString('business', user['business'] ?? '');
          await prefs.setString('services', user['services'] ?? '');
          await prefs.setString('address', user['address'] ?? '');
          await prefs.setInt('editPrice', int.parse(user['editprice']));

          print(jsonEncode(user));
          print(user['apikey']);

          //end of fetching
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showErrorDialog(context, data['message']);
        }
      } else {
        _showErrorDialog(
            context, 'An error occurred. Please try again. ${data['message']}');
      }
    } catch (e) {
      _showErrorDialog(context, 'Please check your connection and try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Failed'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    business,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),

                SizedBox(
                  height: 65,
                ),
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Login to start your session',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText:
                      !_isPasswordVisible, // Toggle password visibility
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                // const SizedBox(height: 6),
                // TextButton(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //           builder: (context) => const ForgotPassword()),
                //     );
                //   },
                //   child: const Text(
                //     "Forgot Password?",
                //     style: TextStyle(color: Colors.black),
                //   ),
                // ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
                // const SizedBox(height: 20),
                // TextButton(
                //   onPressed: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //           builder: (context) => const SignupScreen()),
                //     );
                //   },
                // child: const Text(
                //   "Don't have an account? Sign Up",
                //   style: TextStyle(color: primaryColor),
                // ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
