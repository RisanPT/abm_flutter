import 'package:intl_phone_field/countries.dart';
void main() {
  final code = "+919876543210";
  final country = countries.firstWhere((c) => code.startsWith('+${c.dialCode}'));
  print(country.code);
  print(code.substring(country.dialCode.length + 1));
}
