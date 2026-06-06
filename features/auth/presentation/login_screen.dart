import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/shared/widgets/abm_button.dart';
import 'package:abm_madrasa/shared/widgets/abm_pattern_painter.dart';
import 'package:abm_madrasa/shared/widgets/abm_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = AppRoles.headMaster;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final success = await ref.read(authControllerProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
          selectedRole: _selectedRole,
        );

    if (success && mounted) {
      context.go(_selectedRole.defaultRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: _BrandPanel(selectedRole: _selectedRole)),
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF8F7F2),
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _LoginCard(
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              selectedRole: _selectedRole,
                              onRoleSelected: (role) {
                                setState(() => _selectedRole = role);
                              },
                              onSubmit: _handleLogin,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(child: _BrandPanel(selectedRole: _selectedRole)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 140, 16, 16),
                      child: _LoginCard(
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        selectedRole: _selectedRole,
                        onRoleSelected: (role) {
                          setState(() => _selectedRole = role);
                        },
                        onSubmit: _handleLogin,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.selectedRole});

  final String selectedRole;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F4A3A),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: AbmPatternPainter(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6B64C),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 42,
                      color: Color(0xFF0F4A3A),
                    ),
                  ),
                  const Gap(28),
                  Text(
                    'Anas Bin Malik Centre',
                    textAlign: TextAlign.center,
                    style: typography.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(10),
                  Text(
                    'Madrassa Management System',
                    textAlign: TextAlign.center,
                    style: typography.subtitle.copyWith(
                      color: const Color(0xFFD6B64C),
                    ),
                  ),
                  const Gap(14),
                  Text(
                    'Selected role: ${selectedRole.label}',
                    style: typography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends ConsumerWidget {
  const _LoginCard({
    required this.usernameController,
    required this.passwordController,
    required this.selectedRole,
    required this.onRoleSelected,
    required this.onSubmit,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final String selectedRole;
  final ValueChanged<String> onRoleSelected;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = context.typography;
    final colors = context.colors;
    final authState = ref.watch(authControllerProvider);
    final errorText = authState.hasError ? authState.error.toString() : null;

    return Container(
      padding: EdgeInsets.all(context.isDesktop ? 40 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Welcome Back', style: typography.h1.copyWith(fontSize: 26)),
          const Gap(8),
          Text(
            'Please log in to your account to continue.',
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const Gap(28),
          Text('Select Role', style: typography.bodyMediumSemiBold),
          const Gap(14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AppRoles.coreRoles.map((role) {
              final selected = selectedRole == role;
              return GestureDetector(
                onTap: () => onRoleSelected(role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF0F4A3A) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF0F4A3A)
                          : const Color(0xFFE7E3D6),
                    ),
                    boxShadow: [
                      if (!selected)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _roleIcon(role),
                        size: 18,
                        color: selected
                            ? const Color(0xFFD6B64C)
                            : colors.textSecondary,
                      ),
                      const Gap(10),
                      Text(
                        role.label,
                        style: typography.bodyMediumSemiBold.copyWith(
                          color: selected ? Colors.white : colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const Gap(28),
          ABMTextField(
            label: 'Email Address',
            hint: 'ustadh.ibrahim@anasbinmalik.edu',
            controller: usernameController,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const Gap(20),
          ABMTextField(
            label: 'Password',
            hint: 'Enter your password',
            controller: passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
          ),
          const Gap(16),
          Row(
            children: [
              Icon(Icons.check_box, color: const Color(0xFF0F4A3A), size: 18),
              const Gap(8),
              Text('Remember me', style: typography.bodyMedium),
              const Spacer(),
              Text(
                'Forgot Password?',
                style: typography.bodyMediumSemiBold.copyWith(
                  color: const Color(0xFF0F4A3A),
                ),
              ),
            ],
          ),
          if (errorText != null) ...[
            const Gap(16),
            Text(
              errorText.replaceFirst('Exception: ', ''),
              style: typography.bodySmall.copyWith(color: Colors.red.shade700),
            ),
          ],
          const Gap(28),
          authState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ABMButton(
                  text: 'Log In',
                  onPressed: onSubmit,
                ),
          const Gap(20),
          Center(
            child: Text(
              '© 2025 Anas Bin Malik Centre',
              style: typography.caption,
            ),
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case AppRoles.itAdmin:
        return Icons.verified_user_outlined;
      case AppRoles.headMaster:
        return Icons.school_outlined;
      case AppRoles.teacher:
        return Icons.cast_for_education_outlined;
      case AppRoles.treasurer:
        return Icons.account_balance_wallet_outlined;
      case AppRoles.staff:
        return Icons.groups_2_outlined;
      default:
        return Icons.person_outline;
    }
  }
}
