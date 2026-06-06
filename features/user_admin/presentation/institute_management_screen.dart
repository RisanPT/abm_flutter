import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/color/color_palatte.dart';

class InstituteManagementScreen extends ConsumerWidget {
  const InstituteManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final institutesAsync = ref.watch(instituteListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Management'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showInstituteDialog(context, ref),
          ),
        ],
      ),
      body: institutesAsync.when(
        data: (institutes) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: institutes.length,
          itemBuilder: (context, index) {
            final institute = institutes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ColorPalette.primary.withValues(alpha: 0.1),
                  child: Icon(institute.icon, color: ColorPalette.primary),
                ),
                title: Text(institute.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${institute.location}\n${institute.contactNumber ?? 'No contact'}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.edit2, size: 20),
                      onPressed: () => _showInstituteDialog(context, ref, institute: institute),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ref, institute),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showInstituteDialog(BuildContext context, WidgetRef ref, {Institute? institute}) {
    final nameController = TextEditingController(text: institute?.name);
    final locationController = TextEditingController(text: institute?.location);
    final addressController = TextEditingController(text: institute?.address);
    final contactController = TextEditingController(text: institute?.contactNumber);
    final emailController = TextEditingController(text: institute?.email);
    final latController = TextEditingController(text: institute?.latitude.toString() ?? '25.2048');
    final lngController = TextEditingController(text: institute?.longitude.toString() ?? '55.2708');
    final radiusController = TextEditingController(text: institute?.radius.toString() ?? '500');
    String selectedIcon = institute?.iconName ?? 'school';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(institute == null ? 'Add Institute' : 'Edit Institute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Institute Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location (e.g. Al Ain)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Full Address'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact Number'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Latitude (for face/GPS check-in)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: lngController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Longitude (for face/GPS check-in)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: radiusController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  decoration: const InputDecoration(labelText: 'Allowed Radius (meters)'),
                ),
                const SizedBox(height: 16),
                const Text('Select Icon'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _iconOption(LucideIcons.school, 'school', selectedIcon, (val) => setState(() => selectedIcon = val)),
                    _iconOption(LucideIcons.building, 'building', selectedIcon, (val) => setState(() => selectedIcon = val)),
                    _iconOption(LucideIcons.globe, 'globe', selectedIcon, (val) => setState(() => selectedIcon = val)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameController.text,
                  'location': locationController.text,
                  'address': addressController.text,
                  'contactNumber': contactController.text,
                  'email': emailController.text,
                  'iconName': selectedIcon,
                  'latitude': double.tryParse(latController.text) ?? 25.2048,
                  'longitude': double.tryParse(lngController.text) ?? 55.2708,
                  'radius': double.tryParse(radiusController.text) ?? 500.0,
                };

                if (institute == null) {
                  await ref.read(instituteListProvider.notifier).addInstitute(data);
                } else {
                  await ref.read(instituteListProvider.notifier).updateInstitute(institute.id, data);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(institute == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconOption(IconData icon, String value, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? ColorPalette.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? ColorPalette.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: isSelected ? ColorPalette.primary : Colors.grey),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Institute institute) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: Text('Are you sure you want to deactivate ${institute.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(instituteListProvider.notifier).deleteInstitute(institute.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Deactivate', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
