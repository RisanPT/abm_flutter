import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:abm_madrasa/core/auth/role_permissions.dart';

class RolePermissionsScreen extends ConsumerWidget {
  const RolePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final asyncPermissions = ref.watch(permissionControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Role Permissions', style: typography.h3.copyWith(color: colors.primary)),
      ),
      body: asyncPermissions.when(
        data: (permissions) {
          if (permissions.isEmpty) {
            return const Center(child: Text('No permissions found.'));
          }

          // We don't want to edit Super Admin or IT Admin to avoid lockouts
          final editableRoles = AppRoles.coreRoles.where((r) => r != AppRoles.superAdmin && r != AppRoles.itAdmin).toList();
          final allModules = AppModule.values.toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Manage Role Access', style: typography.h4.copyWith(color: colors.textPrimary)),
              const Gap(8),
              Text('Check the boxes below to grant a role access to a specific module. Changes take effect immediately upon saving.', style: typography.body.copyWith(color: colors.textSecondary)),
              const Gap(24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(colors.primary.withValues(alpha: 0.05)),
                  columns: [
                    DataColumn(label: Text('Role', style: typography.bodySemiBold)),
                    ...allModules.map((m) => DataColumn(label: Text(m.name, style: typography.bodySemiBold))),
                  ],
                  rows: editableRoles.map((role) {
                    final roleModel = permissions.firstWhere((p) => p.role == role, orElse: () => throw Exception('Role not found'));
                    final currentPerms = roleModel.permissions.toSet();

                    return DataRow(
                      cells: [
                        DataCell(Text(role, style: typography.bodySemiBold.copyWith(color: colors.primary))),
                        ...allModules.map((m) {
                          final hasAccess = currentPerms.contains(m.name);
                          return DataCell(
                            Checkbox(
                              value: hasAccess,
                              activeColor: colors.primary,
                              onChanged: (bool? value) {
                                if (value == null) return;
                                final newPerms = Set<String>.from(currentPerms);
                                if (value) {
                                  newPerms.add(m.name);
                                } else {
                                  newPerms.remove(m.name);
                                }
                                ref.read(permissionControllerProvider.notifier).updatePermissions(role, newPerms.toList());
                              },
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading permissions: $e')),
      ),
    );
  }
}
