import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ABMTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;

  const ABMTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<ABMTextField> createState() => _ABMTextFieldState();
}

class _ABMTextFieldState extends State<ABMTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: typography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const Gap(8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          style: typography.bodyLarge,
          validator: widget.validator,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: colors.primary) : null,
            // Password fields get a show/hide toggle.
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: colors.textSecondary, size: 20),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: colors.background.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
