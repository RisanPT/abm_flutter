import 'package:flutter/material.dart';

class TypographyExtension extends ThemeExtension<TypographyExtension> {
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle h4;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle bodySemiBold;
  final TextStyle bodyMedium;
  final TextStyle bodyMediumSemiBold;
  final TextStyle bodySmall;
  final TextStyle bodySmallSemiBold;
  final TextStyle bodySmallMedium;
  final TextStyle bodyLarge;
  final TextStyle bodyLargeSemiBold;
  final TextStyle bodyLargeMedium;
  final TextStyle caption;
  final TextStyle buttonTxt;
  final TextStyle button2;

  static final TypographyExtension defaultTypography = TypographyExtension(
    h1: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    h2: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    h3: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    h4: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    subtitle: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xFF1B3D2F)),
    body: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Color(0xFF1B3D2F)),
    bodySemiBold: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF1B3D2F)),
    bodyMediumSemiBold: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF6B7280)),
    bodySmallSemiBold: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    bodySmallMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1B3D2F)),
    bodyLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal, color: Color(0xFF1B3D2F)),
    bodyLargeSemiBold: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B3D2F)),
    bodyLargeMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF1B3D2F)),
    caption: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Color(0xFF6B7280)),
    buttonTxt: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    button2: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
  );

  TypographyExtension({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.h4,
    required this.subtitle,
    required this.body,
    required this.bodySemiBold,
    required this.bodyMedium,
    required this.bodyMediumSemiBold,
    required this.bodySmall,
    required this.bodySmallSemiBold,
    required this.bodySmallMedium,
    required this.bodyLarge,
    required this.bodyLargeSemiBold,
    required this.bodyLargeMedium,
    required this.caption,
    required this.buttonTxt,
    required this.button2,
  });

  @override
  ThemeExtension<TypographyExtension> copyWith({
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? bodySemiBold,
    TextStyle? bodyMedium,
    TextStyle? bodyMediumSemiBold,
    TextStyle? bodySmall,
    TextStyle? bodySmallSemiBold,
    TextStyle? bodySmallMedium,
    TextStyle? bodyLarge,
    TextStyle? bodyLargeSemiBold,
    TextStyle? bodyLargeMedium,
    TextStyle? caption,
    TextStyle? buttonTxt,
    TextStyle? button2,
  }) {
    return TypographyExtension(
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      bodySemiBold: bodySemiBold ?? this.bodySemiBold,
      bodyMedium: bodyMedium ?? this.bodyMedium,
      bodyMediumSemiBold: bodyMediumSemiBold ?? this.bodyMediumSemiBold,
      bodySmall: bodySmall ?? this.bodySmall,
      bodySmallSemiBold: bodySmallSemiBold ?? this.bodySmallSemiBold,
      bodySmallMedium: bodySmallMedium ?? this.bodySmallMedium,
      bodyLarge: bodyLarge ?? this.bodyLarge,
      bodyLargeSemiBold: bodyLargeSemiBold ?? this.bodyLargeSemiBold,
      bodyLargeMedium: bodyLargeMedium ?? this.bodyLargeMedium,
      caption: caption ?? this.caption,
      buttonTxt: buttonTxt ?? this.buttonTxt,
      button2: button2 ?? this.button2,
    );
  }

  @override
  ThemeExtension<TypographyExtension> lerp(
      covariant ThemeExtension<TypographyExtension>? other, double t) {
    if (other is! TypographyExtension) {
      return this;
    }
    return TypographyExtension(
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      h4: TextStyle.lerp(h4, other.h4, t)!,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodySemiBold: TextStyle.lerp(bodySemiBold, other.bodySemiBold, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodyMediumSemiBold:
          TextStyle.lerp(bodyMediumSemiBold, other.bodyMediumSemiBold, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      bodySmallSemiBold:
          TextStyle.lerp(bodySmallSemiBold, other.bodySmallSemiBold, t)!,
      bodySmallMedium:
          TextStyle.lerp(bodySmallMedium, other.bodySmallMedium, t)!,
      bodyLarge: TextStyle.lerp(bodyLarge, other.bodyLarge, t)!,
      bodyLargeSemiBold:
          TextStyle.lerp(bodyLargeSemiBold, other.bodyLargeSemiBold, t)!,
      bodyLargeMedium:
          TextStyle.lerp(bodyLargeMedium, other.bodyLargeMedium, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      buttonTxt: TextStyle.lerp(buttonTxt, other.buttonTxt, t)!,
      button2: TextStyle.lerp(button2, other.button2, t)!,
    );
  }
}
