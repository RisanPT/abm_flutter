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
        );

    if (success && mounted) {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        context.go(user.role.defaultRoute);
      }
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
                  Expanded(child: const _BrandPanel()),
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
                  Positioned.fill(child: const _BrandPanel()),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 140, 16, 16),
                      child: _LoginCard(
                        usernameController: _usernameController,
                        passwordController: _passwordController,
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
  const _BrandPanel();

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
    required this.onSubmit,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
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
          const Gap(32),
          if (errorText != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade700.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                errorText.replaceFirst('Exception: ', ''),
                style: typography.bodySmall.copyWith(color: Colors.red.shade700),
              ),
            ),
            const Gap(20),
          ],
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
}
