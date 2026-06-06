import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PhotoPickerCard extends StatelessWidget {
  const PhotoPickerCard({
    super.key,
    required this.imageBytes,
    required this.photoUrl,
    required this.studentName,
    required this.onPick,
  });

  final Uint8List? imageBytes;
  final String? photoUrl;
  final String studentName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    ImageProvider? provider;
    if (imageBytes != null) {
      provider = MemoryImage(imageBytes!);
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      provider = NetworkImage(photoUrl!);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFDCE7E0),
            backgroundImage: provider,
            child: provider == null
                ? Text(
                    (studentName.isEmpty ? 'S' : studentName[0]).toUpperCase(),
                    style: context.typography.h3.copyWith(
                      color: const Color(0xFF163D32),
                    ),
                  )
                : null,
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload student photo',
                  style: context.typography.bodyLargeSemiBold.copyWith(
                    color: const Color(0xFF163D32),
                  ),
                ),
                const Gap(6),
                Text(
                  'Images will be uploaded to Cloudinary and stored in the student record.',
                  style: context.typography.bodyMedium.copyWith(
                    color: const Color(0xFF6F7A75),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Choose Image'),
          ),
        ],
      ),
    );
  }
}

class FormSectionTitle extends StatelessWidget {
  final String title;

  const FormSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.typography.h3.copyWith(color: context.colors.primary),
        ),
        const Gap(4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: context.colors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.typography.bodyLargeSemiBold.copyWith(
            color: const Color(0xFF163D32),
          ),
        ),
        const Gap(6),
        Container(
          width: 32,
          height: 2,
          decoration: BoxDecoration(
            color: context.colors.secondary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
