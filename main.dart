import 'dart:async';

import 'package:abm_madrasa/core/network/connectivity_provider.dart';
import 'package:abm_madrasa/core/router/app_router.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ABMMadrasaApp(),
    ),
  );
}

class ABMMadrasaApp extends ConsumerWidget {
  const ABMMadrasaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Anas Bin Malik Centre',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: darkAppTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        // Initialize SizeConfig
        SizeConfig().init(context);
        // A global offline banner sits above every screen (incl. login), so the
        // user is told the moment the internet drops.
        return _ConnectivityBanner(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// Shows a persistent red "No internet connection" bar above the app whenever
/// the device is offline, and a brief green "Back online" bar when it returns.
class _ConnectivityBanner extends ConsumerStatefulWidget {
  const _ConnectivityBanner({required this.child});
  final Widget child;

  @override
  ConsumerState<_ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<_ConnectivityBanner> {
  bool _showBackOnline = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch transitions so we can flash a short "Back online" confirmation the
    // moment the connection is restored.
    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final wasOnline = prev?.value ?? true;
      final isOnline = next.value ?? true;
      if (!wasOnline && isOnline) {
        _timer?.cancel();
        setState(() => _showBackOnline = true);
        _timer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showBackOnline = false);
        });
      } else if (!isOnline && _showBackOnline) {
        _timer?.cancel();
        setState(() => _showBackOnline = false);
      }
    });

    // Default to online while the first connectivity check resolves, so nothing
    // flashes on a normal launch.
    final online = ref.watch(connectivityProvider).maybeWhen(
          data: (v) => v,
          orElse: () => true,
        );

    Widget? bar;
    if (!online) {
      bar = _StatusBar(
        color: const Color(0xFFC0392B),
        icon: LucideIcons.wifiOff,
        label: 'No internet connection',
      );
    } else if (_showBackOnline) {
      bar = _StatusBar(
        color: const Color(0xFF2F855A),
        icon: LucideIcons.wifi,
        label: 'Back online',
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => SizeTransition(
              sizeFactor: anim,
              axisAlignment: -1,
              child: child,
            ),
            child: bar ?? const SizedBox(width: double.infinity),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: ValueKey(label),
      bottom: false,
      child: Container(
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
