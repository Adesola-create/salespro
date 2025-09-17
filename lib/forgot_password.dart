import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // For generating 4-digit code

import 'constants.dart';
import 'reset_code.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  int _generatedCode = 0;

  Future<void> _sendResetCode() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;

    // Generate a 4-digit code
    _generatedCode =
        Random().nextInt(9000) + 1000; // Generates a code between 1000-9999

    final url = Uri.parse('https://api.braveiq.net/v1/resetpass');

    try {
     // print('Sending POST request...');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json'
            }, // Set headers for JSON
            body: jsonEncode({'email': email, 'code': _generatedCode}),
          )
          .timeout(const Duration(seconds: 15));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['status'] == 'success') {
          // Pass the generated code and email to the reset page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetCodeScreen(
                email: email,
                generatedCode: _generatedCode, // Pass the generated code
              ),
            ),
          );
        } else {
          _showErrorDialog(data['message'] ?? 'Unexpected error occurred.');
        }
      } else {
        _showErrorDialog('${data['message']}');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog('Please check your connection and try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 120),
            const Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enter your email to receive password reset code',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              autofocus: true, // Enable autofocus
              decoration: InputDecoration(
                labelText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18), // Adjust the radius as needed
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _isLoading ? null : _sendResetCode,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send Reset Code',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
