import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'product_list.dart';

class SetupAccountScreen extends StatefulWidget {
  const SetupAccountScreen({super.key});

  @override
  _SetupAccountScreenState createState() => _SetupAccountScreenState();
}

class _SetupAccountScreenState extends State<SetupAccountScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  String? _businessSize;
  String? _businessType;
  String? _businessPosition;
  String? _goal;

  int _currentStep = 0;

  final List<String> _businessSizes = [
    'Just me',
    '2-5',
    '6-50',
    '51-100',
    '101-250',
    'More than 250 people',
  ];

  final List<String> _businessTypes = [
    'Retail',
    'Distribution',
    'Consulting',
    'Construction',
    'Education',
    'Transportation',
    'Real Estate',
    'Service',
    'Manufacturing',
    'E-commerce',
    'Technology',
    'Healthcare',
    'Government/municipal Organization',
    'Other',
  ];

  final List<String> _businessPositions = [
    'Owner',
    'Sales manager',
    'Consulting',
    'IT specialist',
    'Marketing Manager',
    'HR Manager',
    'Other',
  ];

  final List<String> _goals = [
    'Increase Sales',
    'Improve Customer Service',
    'Expand Market Reach',
    'Enhance Brand Awareness',
    'Streamline Operations',
  ];

  bool _isFormValid() {
    if (_currentStep == 0) return _businessNameController.text.isNotEmpty;
    if (_currentStep == 1) return _businessSize != null;
    if (_currentStep == 2) return _businessType != null;
    if (_currentStep == 3) return _businessPosition != null;
    if (_currentStep == 4) return _goal != null;
    return false;
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _navigateToNextStep() {
    if (_isFormValid()) {
      setState(() {
        _currentStep++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in the required field."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 Future<void> _finishSetup() async {
  if (!_isFormValid()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill in all fields."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('apikey');

  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Authorization token missing. Please log in again."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final url = Uri.parse('https://salespro.livepetal.com/v1/onboarding');

  final Map<String, String> data = {
    "businessname": _businessNameController.text.trim(),
    "companysize": _businessSize!,
    "businesstype": _businessType!,
    "position": _businessPosition!,
    "goal": _goal!,
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
      body: jsonEncode(data),
    );

    print("Request data: ${jsonEncode(data)}");
    print("Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body);
  await prefs.setString('userData', jsonEncode(decoded));

  if (decoded['apikey'] != null) {
    await prefs.setString('apikey', decoded['apikey']);
  }


  await prefs.setString('business', _businessNameController.text.trim());
  await prefs.setBool('isOnboarded', true);


  Navigator.pushReplacement(context,
    MaterialPageRoute(builder: (context) => const ProductsPage()),
  );
}

    
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Account Setup failed: ${response.reasonPhrase}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("An error occurred: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Widget _buildBusinessNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('What is your business name?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        TextField(
          controller: _businessNameController,
          decoration: InputDecoration(
            hintText: 'Business Name',
            hintStyle: const TextStyle(fontWeight: FontWeight.w300),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessSizeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('What is the size of your business team?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _businessSize,
          items: _businessSizes
              .map((size) => DropdownMenuItem(value: size, child: Text(size)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _businessSize = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Select business size'),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Business Type:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _businessType,
          items: _businessTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _businessType = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Select business type'),
        ),
      ],
    );
  }

  Widget _buildBusinessPositionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('What is your position',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _businessPosition,
          items: _businessPositions
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _businessPosition = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Select position'),
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('What is your primary goal with SalesPro?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _goal,
          items: _goals
              .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _goal = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          hint: const Text('Select your goal'),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBusinessNameStep();
      case 1:
        return _buildBusinessSizeStep();
      case 2:
        return _buildBusinessTypeStep();
      case 3:
        return _buildBusinessPositionStep();
      case 4:
        return _buildGoalStep();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18),
      minimumSize: const Size(150, 50),
    );

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text('SalesPro',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300)),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentStep > 0)
                    ElevatedButton(
                      onPressed: _previousStep,
                      style: buttonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(Colors.grey),
                      ),
                      child:
                          const Text('Back', style: TextStyle(color: Colors.white)),
                    ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _currentStep < 4 ? _navigateToNextStep : _finishSetup,
                    style: buttonStyle.copyWith(
                      backgroundColor:
                          WidgetStateProperty.all(primaryColor),
                    ),
                    child: Text(
                      _currentStep < 4 ? 'Next' : 'Finish',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
