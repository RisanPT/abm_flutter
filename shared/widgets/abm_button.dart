import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ABMButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final Color? color;
  final Color? foregroundColor;
  final IconData? icon;

  const ABMButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.color,
    this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final bg = color ?? (isSecondary ? Colors.transparent : colors.primary);
    final fg = foregroundColor ?? (color != null ? Colors.white : (isSecondary ? colors.primary : Colors.white));

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          side: isSecondary ? BorderSide(color: colors.primary) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSecondary ? 0 : 4,
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: fg))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: typography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

