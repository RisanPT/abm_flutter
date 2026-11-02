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

  final double? height;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;

  const ABMButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.color,
    this.foregroundColor,
    this.icon,
    this.height,
    this.fontSize,
    this.iconSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final bg = color ?? (isSecondary ? Colors.transparent : colors.primary);
    final fg = foregroundColor ?? (color != null ? Colors.white : (isSecondary ? colors.primary : Colors.white));

    return SizedBox(
      width: double.infinity,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: padding,
          side: isSecondary ? BorderSide(color: colors.primary) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSecondary ? 0 : 4,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: (height != null && height! < 48) ? 20 : 24,
                  height: (height != null && height! < 48) ? 20 : 24,
                  child: CircularProgressIndicator(color: fg, strokeWidth: 2.5),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: iconSize ?? 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        style: (fontSize != null
                                ? typography.bodyMedium.copyWith(fontSize: fontSize)
                                : typography.bodyLarge)
                            .copyWith(
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

