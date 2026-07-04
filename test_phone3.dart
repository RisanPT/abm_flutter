import 'package:intl_phone_field/countries.dart';

void main() {
  void parsePhone(String fullPhone, void Function(String, String) onParsed) {
    if (fullPhone.isEmpty) {
      onParsed('IN', '');
      return;
    }
    if (!fullPhone.startsWith('+')) {
      onParsed('IN', fullPhone);
      return;
    }
    try {
      final country = countries.firstWhere(
          (c) => fullPhone.startsWith('+${c.dialCode}'));
      final number = fullPhone.substring(country.dialCode.length + 1);
      onParsed(country.code, number);
    } catch (e) {
      onParsed('IN', fullPhone);
    }
  }

  parsePhone('+919876543210', (code, num) {
    print("Code: $code, Num: $num");
  });
  
  parsePhone('+12025550123', (code, num) {
    print("Code: $code, Num: $num");
  });
  
  parsePhone('9876543210', (code, num) {
    print("Code: $code, Num: $num");
  });
}
