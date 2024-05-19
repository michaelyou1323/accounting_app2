// calculator_widget.dart

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorWidget extends StatefulWidget {
  final Function(String) onResultChanged;

  const CalculatorWidget({super.key, required this.onResultChanged});

  @override
  _CalculatorWidgetState createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _expression = '';
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _expression,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCalculatorButton('7'),
            _buildCalculatorButton('8'),
            _buildCalculatorButton('9'),
            _buildCalculatorButton('/'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCalculatorButton('4'),
            _buildCalculatorButton('5'),
            _buildCalculatorButton('6'),
            _buildCalculatorButton('*'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCalculatorButton('1'),
            _buildCalculatorButton('2'),
            _buildCalculatorButton('3'),
            _buildCalculatorButton('-'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCalculatorButton('0'),
            _buildCalculatorButton('.'),
            _buildCalculatorButton('='),
            _buildCalculatorButton('+'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _expression = '';
                  _result = '';
                });
              },
              child: const Text(
                'مسح',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Remove the last digit from the quantity
                _removeLastDigit();
              },
              child: const Icon(Icons.backspace),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            widget.onResultChanged(
                _result); // Replace calculatorResult with the actual variable holding the result
            Navigator.of(context).pop();
          },
          child: const Text('استخدام النتيجة'),
        ),
      ],
    );
  }

  Widget _buildCalculatorButton(String value) {
    return ElevatedButton(
      onPressed: () {
        _onButtonPressed(value);
      },
      style: ButtonStyle(
        backgroundColor: value == '='
            ? MaterialStateProperty.all<Color>(Colors.orangeAccent)
            : null,
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  void _removeLastDigit() {
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == '=') {
        _calculateResult();
      } else {
        _expression += value;
      }
    });
  }

  void _calculateResult() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(_expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      _result = eval.toString();
      _expression = _result;
    } catch (e) {
      _result = 'Error';
    }
  }
}
