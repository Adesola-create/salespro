import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  _DeleteAccountPageState createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _isRequestSubmitted = false; // Track if request is submitted
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
      _isRequestSubmitted = prefs.getBool('isRequestSubmitted') ?? false;
    });
  }

  Future<void> _submitDeleteRequest() async {
    final String reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for deletion.')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.braveiq.net/v1/terminateacc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_ACCESS_TOKEN', // Replace with actual token if needed
        },
        body: '{"userId": "$_userId", "reason": "$reason"}',
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account termination request sent successfully.')),
        );

        // Save the request status to prevent future submissions
        final prefs = await SharedPreferences.getInstance();
        prefs.setBool('isRequestSubmitted', true);

        setState(() {
          _isRequestSubmitted = true; // Update UI
        });

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to submit request. Please try again later.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred. Please check your connection.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delete Account',
          style: TextStyle(
              color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        // backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Deleting Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Please explain why you want to delete your account...',
                border: OutlineInputBorder(),
              ),
              enabled:
                  !_isRequestSubmitted, // Disable input if already submitted
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRequestSubmitted
                          ? null
                          : _submitDeleteRequest, // Disable if already submitted
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit Request',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  ),
            if (_isRequestSubmitted)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Your account termination request has been submitted.',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

