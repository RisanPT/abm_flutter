import 'package:intl_phone_field/phone_number.dart';
void main() async {
  try {
    final phone = PhoneNumber.fromCompleteNumber(completeNumber: '+919876543210');
    print(phone.countryISOCode);
    print(phone.number);
  } catch (e) {
    print(e);
  }
}
