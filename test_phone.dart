import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

void main() => runApp(const MaterialApp(home: TestScreen()));

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IntlPhoneField(
          initialValue: '+919876543210',
          initialCountryCode: 'IN',
        ),
      ),
    );
  }
}
