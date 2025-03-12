import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';



class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _result = '0';

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '=') {
        try {
          final expression = _input.replaceAll('×', '*').replaceAll('÷', '/');
          Parser parser = Parser();
          Expression exp = parser.parse(expression);
          ContextModel cm = ContextModel();
          _result = exp.evaluate(EvaluationType.REAL, cm).toString();
        } catch (e) {
          _result = 'Error';
        }
      } else {
        _input += value;
      }
    });
  }

Widget _buildButton(String label, Color color, {double fontSize = 26}) {
  return ElevatedButton(
    onPressed: () => _onButtonPressed(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.grey, width: 1), // Add grey border
      ),
      padding: const EdgeInsets.all(14),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Display for input and result
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    _input,
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    _result,
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Buttons Grid
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildButton('C', Colors.red),
                  _buildButton('⌫', Colors.orange),
                  _buildButton('%', Colors.blue),
                  _buildButton('÷', const Color.fromARGB(255, 8, 63, 165)),
                  _buildButton('7', Colors.grey[800]!),
                  _buildButton('8', Colors.grey[800]!),
                  _buildButton('9', Colors.grey[800]!),
                  _buildButton('×', Color.fromARGB(255, 8, 63, 165)),
                  _buildButton('4', Colors.grey[800]!),
                  _buildButton('5', Colors.grey[800]!),
                  _buildButton('6', Colors.grey[800]!),
                  _buildButton('-', Color.fromARGB(255, 8, 63, 165)),
                  _buildButton('1', Colors.grey[800]!),
                  _buildButton('2', Colors.grey[800]!),
                  _buildButton('3', Colors.grey[800]!),
                  _buildButton('+', Color.fromARGB(255, 8, 63, 165)),
                  _buildButton('±', Colors.blue),
                  _buildButton('0', Colors.grey[800]!),
                  _buildButton('.', Colors.grey[800]!),
                  _buildButton('=', const Color.fromARGB(255, 6, 119, 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}