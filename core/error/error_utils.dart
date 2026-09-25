import 'package:abm_madrasa/core/network/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Turns any thrown error into a short, human-readable message suitable for a
/// snackbar or an error state — surfacing the server's own `message` where one
/// exists (e.g. "A user with this email already exists") instead of raw
/// `DioException`/`Exception` text.
String friendlyErrorMessage(Object? error) {
  if (error == null) return 'Something went wrong. Please try again.';

  if (error is AppException) return error.message;

  if (error is DioException) {
    // The ErrorInterceptor already attaches an AppException; fall back to a fresh
    // mapping if it didn't.
    if (error.error is AppException) return (error.error as AppException).message;
    return AppException.fromDioError(error).message;
  }

  var s = error.toString().trim();

  // Repositories often wrap failures as `Exception('Failed to X: <inner>')`.
  // Strip the wrapper(s) and pull out the meaningful tail.
  s = s.replaceFirst(RegExp(r'^Exception:\s*'), '');

  // Common technical errors → plain language, so nothing raw ever reaches a user.
  final low = s.toLowerCase();
  if (low.contains('e11000') || low.contains('duplicate key')) {
    return 'This record already exists.';
  }
  if (low.contains('socketexception') ||
      low.contains('failed host lookup') ||
      low.contains('connection refused') ||
      low.contains('network is unreachable') ||
      low.contains('connection closed')) {
    return 'Cannot reach the server. Please check your connection.';
  }
  if (low.contains('timeoutexception') || low.contains('timed out')) {
    return 'The request timed out. Please try again.';
  }

  // If a DioException got stringified into the message, extract its human part
  // ("DioException [bad response]: <message>") and drop the technical prefix.
  final dioIdx = s.indexOf('DioException');
  if (dioIdx != -1) {
    final after = s.substring(dioIdx);
    final marker = after.indexOf(']:');
    if (marker != -1) {
      final tail = after.substring(marker + 2).trim();
      if (tail.isNotEmpty && !tail.toLowerCase().contains('status code')) {
        return _firstSentence(tail);
      }
    }
    return 'Something went wrong. Please try again.';
  }

  // Drop a trailing "Failed to …: " lead-in if the tail is the real message.
  final lastColon = s.lastIndexOf(': ');
  if (s.toLowerCase().startsWith('failed to') && lastColon != -1 && lastColon < s.length - 2) {
    s = s.substring(lastColon + 2).trim();
  }

  return _firstSentence(s.isEmpty ? 'Something went wrong. Please try again.' : s);
}

String _firstSentence(String s) {
  // Keep it short — one line is plenty for a snackbar.
  final trimmed = s.length > 160 ? '${s.substring(0, 157)}…' : s;
  return trimmed;
}

/// Shows a red snackbar with a friendly message for [error].
void showErrorSnackBar(BuildContext context, Object? error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(friendlyErrorMessage(error)),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
