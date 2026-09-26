import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A single, consistent confirmation dialog for destructive / irreversible
/// actions across the app. Returns true only when the user confirms.
Future<bool> confirmActionDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
  bool destructive = true,
  IconData? icon,
}) async {
  final colors = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: destructive ? colors.red : colors.primary, size: 22),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? colors.red : colors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}
