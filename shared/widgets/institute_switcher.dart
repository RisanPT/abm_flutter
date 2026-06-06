import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';


class InstituteSwitcher extends ConsumerWidget {
  const InstituteSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedInstituteProvider);
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ListTile(
        onTap: () => _showPicker(context, ref),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(selected.icon, color: colors.primary, size: 20),
        ),
        title: Text(
          selected.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          selected.location,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(LucideIcons.chevronDown, size: 16),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final institutesAsync = ref.read(instituteListProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Switch Institute',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              institutesAsync.when(
                data: (institutes) => Column(
                  children: institutes.map((inst) => ListTile(
                    leading: Icon(inst.icon, color: ref.read(selectedInstituteProvider).id == inst.id ? context.colors.primary : null),
                    title: Text(inst.name),
                    subtitle: Text(inst.location),
                    onTap: () {
                      ref.read(selectedInstituteProvider.notifier).setInstitute(inst);
                      Navigator.pop(context);
                    },
                    trailing: ref.read(selectedInstituteProvider).id == inst.id 
                      ? Icon(LucideIcons.check, color: context.colors.primary) 
                      : null,
                  )).toList(),
                ),
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                )),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        );
      },
    );
  }
}
