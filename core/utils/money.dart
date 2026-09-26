import 'package:intl/intl.dart';

// One place for money formatting so every fee, salary and total reads
// consistently — with thousands separators (e.g. "SAR 1,250,000").

final NumberFormat _sar0 = NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 0);
final NumberFormat _sar2 = NumberFormat.currency(locale: 'en_US', symbol: 'SAR ', decimalDigits: 2);
final NumberFormat _plain0 = NumberFormat.decimalPatternDigits(locale: 'en_US', decimalDigits: 0);

/// Formats an amount as SAR with thousands separators.
/// `decimals: 0` (default) → "SAR 1,250"; `decimals: 2` → "SAR 1,250.00".
String sar(num? value, {int decimals = 0}) {
  final v = value ?? 0;
  return (decimals >= 2 ? _sar2 : _sar0).format(v);
}

/// A number with thousands separators but no currency symbol (e.g. counts).
String number(num? value) => _plain0.format(value ?? 0);
