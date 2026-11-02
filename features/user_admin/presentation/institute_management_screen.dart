import 'package:abm_madrasa/core/error/error_utils.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/shared/widgets/abm_page_header.dart';
import 'package:abm_madrasa/shared/widgets/abm_ui.dart';
import 'package:abm_madrasa/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InstituteManagementScreen extends ConsumerStatefulWidget {
  const InstituteManagementScreen({super.key});

  @override
  ConsumerState<InstituteManagementScreen> createState() => _InstituteManagementScreenState();
}

class _InstituteManagementScreenState extends ConsumerState<InstituteManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final institutesAsync = ref.watch(instituteListProvider);
    final activeInstitute = ref.watch(selectedInstituteProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          ABMPageHeader(
            title: 'Institute Management',
            subtitle: 'Manage madrasa branches, campuses, and locations',
            showBackButton: true,
            compact: true,
            actions: [
              FilledButton.icon(
                onPressed: () => showInstituteFormDialog(context, ref),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Add Institute', style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Gap(8),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                tooltip: 'Refresh Institutes',
                onPressed: () => ref.invalidate(instituteListProvider),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Expanded(
            child: institutesAsync.when(
              data: (institutes) {
                final filtered = institutes.where((i) {
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  return i.name.toLowerCase().contains(q) ||
                      i.location.toLowerCase().contains(q) ||
                      (i.address ?? '').toLowerCase().contains(q) ||
                      (i.contactNumber ?? '').toLowerCase().contains(q) ||
                      (i.email ?? '').toLowerCase().contains(q);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  children: [
                    // Search & Overview Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              decoration: InputDecoration(
                                hintText: 'Search branches by name, location, or contact...',
                                prefixIcon: const Icon(LucideIcons.search, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.border),
                                ),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const Gap(8),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              tooltip: 'Clear search',
                              onPressed: () => setState(() => _searchQuery = ''),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Gap(14),

                    // Results header & count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          filtered.isEmpty
                              ? 'No institutes found'
                              : 'Registered Institutes (${filtered.length})',
                          style: typography.bodyMediumSemiBold,
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => showInstituteFormDialog(context, ref),
                          icon: const Icon(LucideIcons.plus, size: 14),
                          label: const Text('Add Institute', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),

                    const Gap(12),

                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(36),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.building2, size: 36, color: colors.primary),
                            ),
                            const Gap(14),
                            Text(
                              _searchQuery.isNotEmpty ? 'No institutes matching "$_searchQuery"' : 'No Institutes Registered',
                              style: typography.bodyLargeSemiBold,
                              textAlign: TextAlign.center,
                            ),
                            const Gap(6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try adjusting your search terms or register a new campus.'
                                  : 'Click below to register and configure your first madrasa campus.',
                              style: typography.bodySmall.copyWith(color: colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const Gap(18),
                            FilledButton.icon(
                              onPressed: () => showInstituteFormDialog(context, ref),
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Add Institute'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      for (final inst in filtered) ...[
                        _InstituteCard(
                          institute: inst,
                          isActive: inst.id == activeInstitute.id,
                          onSelectActive: () {
                            ref.read(selectedInstituteProvider.notifier).setInstitute(inst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Switched active campus to ${inst.name}')),
                            );
                          },
                          onEdit: () => showInstituteFormDialog(context, ref, institute: inst),
                          onDelete: () => _confirmDelete(context, ref, inst),
                        ),
                        const Gap(10),
                      ],
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => AbmErrorView(
                message: friendlyErrorMessage(err),
                onRetry: () => ref.invalidate(instituteListProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showInstituteFormDialog(context, ref),
        backgroundColor: colors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'Add Institute',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Institute institute) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmActionDialog(
      context,
      title: 'Deactivate Institute',
      message: 'Are you sure you want to deactivate "${institute.name}"? Active students and data will remain preserved.',
      icon: LucideIcons.trash2,
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (!ok) return;

    try {
      await ref.read(instituteListProvider.notifier).deleteInstitute(institute.id);
      messenger.showSnackBar(SnackBar(content: Text('"${institute.name}" has been deactivated.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }
}

// ─── Institute Card Component ────────────────────────────────────────────────

class _InstituteCard extends StatelessWidget {
  const _InstituteCard({
    required this.institute,
    required this.isActive,
    required this.onSelectActive,
    required this.onEdit,
    required this.onDelete,
  });

  final Institute institute;
  final bool isActive;
  final VoidCallback onSelectActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? colors.primary.withValues(alpha: 0.5) : colors.border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isActive ? colors.primary : colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    institute.icon,
                    color: isActive ? Colors.white : colors.primary,
                    size: 22,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              institute.name,
                              style: typography.bodyLargeSemiBold.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.check, size: 11, color: Color(0xFF15803D)),
                                  Gap(4),
                                  Text(
                                    'Active Campus',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 12, color: colors.textSecondary),
                          const Gap(4),
                          Text(
                            institute.location,
                            style: typography.bodySmall.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (institute.contactNumber != null && institute.contactNumber!.isNotEmpty) ...[
                            const Gap(12),
                            Icon(LucideIcons.phone, size: 12, color: colors.textSecondary),
                            const Gap(4),
                            Text(
                              institute.contactNumber!,
                              style: typography.bodySmall.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (institute.address != null && institute.address!.isNotEmpty) ...[
              const Gap(10),
              Text(
                'Address: ${institute.address}',
                style: typography.bodySmall.copyWith(fontSize: 11, color: colors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Gap(12),
            const Divider(height: 1),
            const Gap(8),

            // Action strip
            Row(
              children: [
                if (!isActive)
                  OutlinedButton.icon(
                    onPressed: onSelectActive,
                    icon: const Icon(LucideIcons.checkCircle2, size: 13),
                    label: const Text('Switch To', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const Spacer(),
                IconButton.outlined(
                  onPressed: onEdit,
                  icon: const Icon(LucideIcons.pencil, size: 14),
                  tooltip: 'Edit Institute',
                  visualDensity: VisualDensity.compact,
                ),
                const Gap(6),
                IconButton.outlined(
                  onPressed: onDelete,
                  icon: Icon(LucideIcons.trash2, size: 14, color: colors.red),
                  tooltip: 'Deactivate Institute',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Add/Edit Institute Dialog ───────────────────────────────────────

Future<void> showInstituteFormDialog(
  BuildContext context,
  WidgetRef ref, {
  Institute? institute,
}) async {
  final nameController = TextEditingController(text: institute?.name);
  final locationController = TextEditingController(text: institute?.location);
  final addressController = TextEditingController(text: institute?.address);
  final contactController = TextEditingController(text: institute?.contactNumber);
  final emailController = TextEditingController(text: institute?.email);
  String selectedIcon = institute?.iconName ?? 'school';

  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  final availableIcons = <({IconData icon, String key, String label})>[
    (icon: LucideIcons.school, key: 'school', label: 'School'),
    (icon: LucideIcons.building2, key: 'building', label: 'Campus'),
    (icon: LucideIcons.landmark, key: 'landmark', label: 'Madrasa'),
    (icon: LucideIcons.bookOpen, key: 'book', label: 'Academy'),
    (icon: LucideIcons.globe, key: 'globe', label: 'Online'),
    (icon: LucideIcons.graduationCap, key: 'graduationCap', label: 'College'),
  ];

  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final colors = context.colors;
        final typography = context.typography;

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  institute == null ? LucideIcons.plus : LucideIcons.pencil,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institute == null ? 'Add New Institute' : 'Edit Institute',
                      style: typography.h4.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Configure campus name, location, and contact',
                      style: typography.bodySmall.copyWith(color: colors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(8),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Institute / Branch Name *',
                        hintText: 'e.g. Anas Bin Malik Central Campus',
                        prefixIcon: const Icon(LucideIcons.building, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter institute name';
                        }
                        return null;
                      },
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'City / Region *',
                        hintText: 'e.g. Al Ain, Kuala Lumpur, Malappuram',
                        prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Full Address',
                        hintText: 'Physical address of the campus...',
                        prefixIcon: const Icon(LucideIcons.home, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: contactController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone',
                              hintText: '+971...',
                              prefixIcon: const Icon(LucideIcons.phone, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'admin@...',
                              prefixIcon: const Icon(LucideIcons.mail, size: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Text(
                      'Campus Icon',
                      style: typography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: colors.textSecondary),
                    ),
                    const Gap(8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((item) {
                        final isSel = selectedIcon == item.key;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedIcon = item.key),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? colors.primary.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? colors.primary : colors.border,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 16,
                                  color: isSel ? colors.primary : colors.textSecondary,
                                ),
                                const Gap(6),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? colors.primary : colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final data = {
                        'name': nameController.text.trim(),
                        'location': locationController.text.trim(),
                        'address': addressController.text.trim(),
                        'contactNumber': contactController.text.trim(),
                        'email': emailController.text.trim(),
                        'iconName': selectedIcon,
                      };

                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        if (institute == null) {
                          await ref.read(instituteListProvider.notifier).addInstitute(data);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Institute "${data['name']}" created successfully.')),
                          );
                        } else {
                          await ref.read(instituteListProvider.notifier).updateInstitute(institute.id, data);
                          messenger.showSnackBar(
                            SnackBar(content: Text('Institute "${data['name']}" updated successfully.')),
                          );
                        }
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop(true);
                      } catch (err) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(content: Text(friendlyErrorMessage(err))),
                        );
                      }
                    },
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(institute == null ? LucideIcons.plus : LucideIcons.check, size: 16),
              label: Text(institute == null ? 'Create Institute' : 'Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    ),
  );

  nameController.dispose();
  locationController.dispose();
  addressController.dispose();
  contactController.dispose();
  emailController.dispose();
}
