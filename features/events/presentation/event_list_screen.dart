import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/events/domain/event_model.dart';
import 'package:abm_madrasa/features/events/presentation/event_controller.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';

import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';

class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final eventsAsync = ref.watch(eventControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final isAdmin = user?.role == AppRoles.itAdmin || user?.role == AppRoles.headMaster;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Administration', style: typography.h3.copyWith(color: colors.primary)),
        actions: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showEventDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Event'),
              ),
            ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('No upcoming events.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _EventCard(event: event, isAdmin: isAdmin);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showEventDialog(BuildContext context, WidgetRef ref, {EventModel? event}) {
     showDialog(
      context: context,
      builder: (context) => _AddEventDialog(event: event),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final EventModel event;
  final bool isAdmin;
  const _EventCard({required this.event, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;

    final imageUrls = event.imageUrls ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(event.date),
                    style: typography.bodySmallSemiBold.copyWith(color: colors.primary),
                  ),
                ),
                if (isAdmin)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        onPressed: () => _showEditDialog(context, ref),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => ref.read(eventControllerProvider.notifier).deleteEvent(event.id!),
                      ),
                    ],
                  ),
              ],
            ),
            const Gap(16),
            if (imageUrls.isNotEmpty) ...[
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[index],
                            height: 200,
                            width: 300,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 300,
                              color: colors.primary.withValues(alpha: 0.1),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),
            ],
            Text(event.title, style: typography.h3.copyWith(color: colors.textPrimary)),
            if (event.description != null && event.description!.isNotEmpty) ...[
                const Gap(8),
                Text(event.description!, style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
            ],
            const Gap(16),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: colors.textSecondary),
                const Gap(8),
                Text(event.location, style: typography.bodySmall.copyWith(color: colors.textSecondary)),
                const Spacer(),
                _StatusBadge(status: event.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _AddEventDialog(event: event),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EventStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case EventStatus.upcoming: color = Colors.blue; break;
      case EventStatus.completed: color = Colors.green; break;
      case EventStatus.cancelled: color = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AddEventDialog extends ConsumerStatefulWidget {
  final EventModel? event;
  const _AddEventDialog({this.event});

  @override
  ConsumerState<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends ConsumerState<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locController;
  late DateTime _date;
  final List<XFile> _images = [];
  final List<Uint8List> _imagesBytes = [];
  bool _isUploading = false;
  EventStatus _status = EventStatus.upcoming;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title);
    _descController = TextEditingController(text: widget.event?.description);
    _locController = TextEditingController(text: widget.event?.location);
    _date = widget.event?.date ?? DateTime.now();
    _status = widget.event?.status ?? EventStatus.upcoming;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      final List<XFile> validFiles = [];
      final List<Uint8List> validBytes = [];
      bool hasLargeFiles = false;

      for (final file in picked) {
        final size = await file.length();
        if (size <= 5 * 1024 * 1024) { // 5MB Limit
          final bytes = await file.readAsBytes();
          validFiles.add(file);
          validBytes.add(bytes);
        } else {
          hasLargeFiles = true;
        }
      }

      if (mounted) {
        if (hasLargeFiles) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Some images were skipped because they exceed the 5MB limit.')),
          );
        }

        setState(() {
          _images.addAll(validFiles);
          _imagesBytes.addAll(validBytes);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!mounted) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      // Capture messenger before any await calls
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context, rootNavigator: true);

      try {
        List<String> finalImageUrls = widget.event?.imageUrls != null ? List<String>.from(widget.event!.imageUrls!) : [];

        if (_images.isNotEmpty) {
          final List<String> newUrls = [];
          for (int i = 0; i < _images.length; i++) {
            final file = _images[i];
            final bytes = _imagesBytes[i];
            final dataUri = 'data:image/${file.path.split('.').last};base64,${base64Encode(bytes)}';

            final url = await ref.read(eventControllerProvider.notifier).uploadImage(dataUri, file.name);
            
            if (!mounted) return;

            if (url != null) {
              newUrls.add(url);
            } else {
              throw Exception('Failed to upload ${file.name}');
            }
          }
          finalImageUrls = newUrls;
        }

        final updatedEvent = EventModel(
          id: widget.event?.id,
          title: _titleController.text,
          description: _descController.text,
          date: _date,
          location: _locController.text,
          status: _status,
          imageUrls: finalImageUrls,
        );

        if (widget.event != null) {
          await ref.read(eventControllerProvider.notifier).updateEvent(widget.event!.id!, updatedEvent);
        } else {
          await ref.read(eventControllerProvider.notifier).addEvent(updatedEvent);
        }

        if (!mounted) return;
        nav.pop();
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
          setState(() => _isUploading = false);
        }
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _imagesBytes.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    if (widget.event?.imageUrls != null) {
      setState(() {
        widget.event!.imageUrls!.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.05),
                  border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.event == null ? Icons.add_circle_outline : Icons.edit_calendar, color: colors.primary),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event == null ? 'Add New Event' : 'Edit Event',
                            style: typography.h3.copyWith(color: colors.textPrimary),
                          ),
                          Text(
                            'Enter the details for this administration event',
                            style: typography.bodySmall.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.background,
                        foregroundColor: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section: General Information
                        _SectionHeader(title: 'General Information', icon: Icons.info_outline),
                        const Gap(16),
                        ABMTextField(
                          label: 'Title',
                          hint: 'e.g. Annual Sports Day 2026',
                          controller: _titleController,
                          validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                        ),
                        const Gap(16),
                        ABMTextField(
                          label: 'Description',
                          hint: 'Provide a brief summary of the event...',
                          controller: _descController,
                          maxLines: 3,
                        ),
                        
                        const Gap(24),
                        const Divider(),
                        const Gap(24),

                        // Section: Details
                        _SectionHeader(title: 'Event Details', icon: Icons.location_on_outlined),
                        const Gap(16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ABMTextField(
                                label: 'Location',
                                hint: 'e.g. Main Hall',
                                controller: _locController,
                                validator: (val) => val == null || val.isEmpty ? 'Location is required' : null,
                              ),
                            ),
                            const Gap(16),
                            Expanded(
                              child: _CustomDropdown<EventStatus>(
                                label: 'Status',
                                value: _status,
                                items: EventStatus.values
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
                                    .toList(),
                                onChanged: (val) { if (val != null) setState(() => _status = val); },
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        _DatePickerField(
                          label: 'Event Date',
                          date: _date,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                        ),

                        const Gap(24),
                        const Divider(),
                        const Gap(24),

                        // Section: Media
                        _SectionHeader(title: 'Event Media', icon: Icons.image_outlined),
                        const Gap(16),
                        _ImageManager(
                          imagesBytes: _imagesBytes,
                          imageUrls: widget.event?.imageUrls ?? [],
                          onPick: _pickImages,
                          onRemoveNew: _removeImage,
                          onRemoveExisting: _removeExistingImage,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: 0.5),
                  border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: typography.bodyMedium.copyWith(color: colors.textSecondary)),
                    ),
                    const Gap(16),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.event == null ? 'Create Event' : 'Update Event'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const Gap(8),
        Text(title, style: typography.bodyLargeSemiBold.copyWith(color: colors.primary)),
      ],
    );
  }
}

class _CustomDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _CustomDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: colors.primary)),
        const Gap(8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.background.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5))),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: colors.primary)),
        const Gap(8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 20, color: colors.primary),
                const Gap(12),
                Text(DateFormat('EEEE, dd MMMM yyyy').format(date), style: typography.bodyLarge),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageManager extends StatelessWidget {
  final List<Uint8List> imagesBytes;
  final List<String> imageUrls;
  final VoidCallback onPick;
  final Function(int) onRemoveNew;
  final Function(int) onRemoveExisting;

  const _ImageManager({
    required this.imagesBytes,
    required this.imageUrls,
    required this.onPick,
    required this.onRemoveNew,
    required this.onRemoveExisting,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    final hasImages = imagesBytes.isNotEmpty || imageUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasImages) ...[
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing Images
                ...imageUrls.asMap().entries.map((entry) => _ImagePreview(
                      url: entry.value,
                      onRemove: () => onRemoveExisting(entry.key),
                    )),
                // New Images
                ...imagesBytes.asMap().entries.map((entry) => _ImagePreview(
                      bytes: entry.value,
                      onRemove: () => onRemoveNew(entry.key),
                    )),
              ],
            ),
          ),
          const Gap(16),
        ],
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.primary.withValues(alpha: 0.2), width: 2, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.add_photo_alternate_outlined, color: colors.primary),
                ),
                const Gap(12),
                Text(hasImages ? 'Add More Images' : 'Upload Event Images', style: typography.bodyLargeSemiBold.copyWith(color: colors.primary)),
                Text('JPG, PNG up to 5MB', style: typography.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? url;
  final Uint8List? bytes;
  final VoidCallback onRemove;

  const _ImagePreview({this.url, this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url != null
                ? CachedNetworkImage(imageUrl: url!, width: 120, height: 120, fit: BoxFit.cover)
                : Image.memory(bytes!, width: 120, height: 120, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
