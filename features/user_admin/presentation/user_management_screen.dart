import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/user_admin/domain/admin_user_model.dart';
import 'package:abm_madrasa/features/user_admin/presentation/admin_controller.dart';
import 'package:abm_madrasa/features/user_admin/data/admin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final usersState = ref.watch(adminControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Role Assignment', style: typography.h3.copyWith(color: colors.primary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: colors.primary,
        foregroundColor: colors.primary,
      ),
      body: usersState.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Gap(16),
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserTile(user: user);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString(), style: TextStyle(color: colors.red))),
      ),
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, [AdminUser? existingUser]) {
    showDialog(
      context: context,
      builder: (context) => _UserDialog(existingUser: existingUser),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final AdminUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: colors.primary),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: typography.bodySemiBold.copyWith(color: colors.textPrimary)),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: typography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _UserDialog(existingUser: user),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(adminControllerProvider.notifier).deleteUser(user.id).catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: context.colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserDialog extends ConsumerStatefulWidget {
  final AdminUser? existingUser;

  const _UserDialog({this.existingUser});

  @override
  ConsumerState<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String _selectedRole = AppRoles.staff;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.existingUser?.username ?? '');
    _passwordController = TextEditingController();
    if (widget.existingUser != null) {
      _selectedRole = widget.existingUser!.role;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final roleStr = _selectedRole;

      if (widget.existingUser == null) {
        await ref.read(adminControllerProvider.notifier).createUser(
          username: _usernameController.text,
          password: _passwordController.text,
          role: roleStr,
        );
      } else {
        await ref.read(adminControllerProvider.notifier).updateUser(
          id: widget.existingUser!.id,
          username: _usernameController.text,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          role: roleStr,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateRoleDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Custom Role'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Role Name (e.g. Inspector)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await ref.read(adminServiceProvider).createRole(name);
        ref.invalidate(rolesProvider);
        setState(() {
          _selectedRole = name;
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Revert if cancelled and "Add Custom..." was somehow selected, though it shouldn't be the assigned value.
      setState(() {
         // Reset to previously selected or default
         if (!AppRoles.coreRoles.contains(_selectedRole)) {
             _selectedRole = AppRoles.staff;
         }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isEdit = widget.existingUser != null;
    
    // Fetch dynamic roles
    final rolesAsync = ref.watch(rolesProvider);
    List<String> availableRoles = [...AppRoles.coreRoles];
    if (rolesAsync.hasValue) {
      for (final r in rolesAsync.value!) {
        if (!availableRoles.contains(r)) availableRoles.add(r);
      }
    }
    
    // Ensure selected role is in the list (e.g. if a user has a custom role that isn't fetched yet)
    if (!availableRoles.contains(_selectedRole) && _selectedRole != '+ Add New Role...') {
      availableRoles.add(_selectedRole);
    }

    return AlertDialog(
      title: Text(isEdit ? 'Edit User' : 'Add User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  ...availableRoles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }),
                  const DropdownMenuItem(
                    value: '+ Add New Role...',
                    child: Text('+ Add New Role...', style: TextStyle(color: Colors.blue)),
                  ),
                ],
                onChanged: (val) {
                  if (val == '+ Add New Role...') {
                    _showCreateRoleDialog();
                  } else if (val != null) {
                    setState(() => _selectedRole = val);
                  }
                },
              ),
              const Gap(16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: isEdit ? 'New Password (Optional)' : 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                obscureText: true,
                validator: (v) {
                  if (!isEdit && (v == null || v.isEmpty)) return 'Required';
                  if (v != null && v.isNotEmpty && v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              if (rolesAsync.isLoading) const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.primary,
          ),
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}
