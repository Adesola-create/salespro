import 'package:flutter/material.dart'; 
import 'constants.dart';
import 'new_password.dart'; // Import your NewPasswordScreen file if it's in another file



class ResetCodeScreen extends StatefulWidget {
  final String email;
  final int generatedCode; // The code passed from the ForgotPassword screen

  const ResetCodeScreen({super.key, required this.email, required this.generatedCode});

  @override
  _ResetCodeScreenState createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  final _digitControllers = List.generate(4, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Add a listener for paste handling on the first input
    _digitControllers[0].addListener(_handlePaste);
  }

  @override
  void dispose() {
    // Clean up controllers
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handlePaste() {
    final pastedText = _digitControllers[0].text;
    if (pastedText.length == 4) {
      for (int i = 0; i < 4; i++) {
        _digitControllers[i].text = pastedText[i];
        if (i < 3) FocusScope.of(context).nextFocus(); // Move focus forward
      }
    }
  }

  void _verifyCode() {
    final enteredCode = _digitControllers.map((controller) => controller.text).join();
    if (int.tryParse(enteredCode) == widget.generatedCode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewPasswordScreen(email: widget.email),
        ),
      );
    } else {
      _showErrorDialog('Incorrect code. Please try again.');
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
            const SizedBox(height: 100),
            const Text(
              'Verify Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
            ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter the 4-digit code sent to your email',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _digitControllers[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '', // hides the counter below each input
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 3) {
                        FocusScope.of(context).nextFocus(); // Move focus forward
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus(); // Move focus backward on delete
                      }
                    },
                  ),
                );
              }),
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
                onPressed: _verifyCode,
                child: const Text(
                  'Verify Code',
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
