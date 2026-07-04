import 'package:intl_phone_field/countries.dart';
void main() {
  final names = countries.map((c) => c.name).toList();
  final uniqueNames = names.toSet().toList();
  if (names.length != uniqueNames.length) {
    print("Duplicates found!");
    final seen = <String>{};
    for (var name in names) {
      if (seen.contains(name)) print(name);
      seen.add(name);
    }
  } else {
    print("No duplicates.");
  }
}
