import 'dart:convert';
import 'dart:typed_data';

import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/features/notifications/data/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Shows the "Report a Bug" dialog. Any user (teacher / student / principal /
/// staff) can describe an issue and optionally attach a screenshot; it is
/// delivered to the IT Admin only.
Future<void> showBugReportDialog(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _BugReportDialog(),
  );
}

class _BugReportDialog extends ConsumerStatefulWidget {
  const _BugReportDialog();

  @override
  ConsumerState<_BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends ConsumerState<_BugReportDialog> {
  final _titleC = TextEditingController();
  final _bodyC = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _imageName = '';
  bool _sending = false;

  @override
  void dispose() {
    _titleC.dispose();
    _bodyC.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1400,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  String _mimeFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _send() async {
    final title = _titleC.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a short title.')));
      return;
    }
    setState(() => _sending = true);
    try {
      String? screenshot;
      if (_imageBytes != null) {
        screenshot = 'data:${_mimeFor(_imageName)};base64,${base64Encode(_imageBytes!)}';
      }
      await ref.read(notificationRepositoryProvider).reportBug(
            title: title,
            body: _bodyC.text.trim(),
            screenshot: screenshot,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bug report sent to IT. Thank you!'), backgroundColor: Color(0xFF2F855A)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC0392B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.bug, color: Color(0xFFC0392B), size: 20),
          ),
          const Gap(12),
          const Expanded(child: Text('Report a Bug')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Noticed something wrong? Tell the IT team — a screenshot helps them understand it faster.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const Gap(12),
            TextField(
              controller: _titleC,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What happened? (short title)'),
            ),
            const Gap(10),
            TextField(
              controller: _bodyC,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                hintText: 'Which screen, what you tapped, what you expected…',
              ),
            ),
            const Gap(14),
            _buildScreenshotSection(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.send, size: 16),
          label: Text(_sending ? 'Sending…' : 'Send'),
        ),
      ],
    );
  }

  Widget _buildScreenshotSection(BuildContext context) {
    if (_imageBytes == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _sending ? null : _pickScreenshot,
          icon: const Icon(LucideIcons.imagePlus, size: 18),
          label: const Text('Attach screenshot'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _imageBytes!,
            height: 130,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const Gap(6),
        Row(
          children: [
            TextButton.icon(
              onPressed: _sending ? null : _pickScreenshot,
              icon: const Icon(LucideIcons.refreshCw, size: 15),
              label: const Text('Change'),
            ),
            TextButton.icon(
              onPressed: _sending ? null : () => setState(() { _imageBytes = null; _imageName = ''; }),
              icon: const Icon(LucideIcons.trash2, size: 15, color: Color(0xFFC0392B)),
              label: const Text('Remove', style: TextStyle(color: Color(0xFFC0392B))),
            ),
          ],
        ),
      ],
    );
  }
}
