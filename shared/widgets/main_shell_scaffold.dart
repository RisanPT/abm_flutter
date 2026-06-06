import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShellScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainShellScaffold({super.key, required this.child});

  @override
  ConsumerState<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends ConsumerState<MainShellScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authControllerProvider).value;
    final navItems = user?.role.navigationItems ??
        const [
          AppNavItem(
            label: 'Dashboard',
            route: '/dashboard',
            icon: Icons.dashboard_outlined,
            module: AppModule.dashboard,
          ),
        ];
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final selectedIndex = navItems.indexWhere(
      (item) =>
          currentLocation == item.route ||
          currentLocation.startsWith('${item.route}/'),
    );
    final mobileNavItems = navItems.take(5).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: context.isDesktop
          ? null
          : _MobileShellDrawer(
              userName: user?.username ?? 'User',
              navItems: navItems,
              currentLocation: currentLocation,
              onItemTap: (index) {
                Navigator.of(context).pop();
                _onItemTapped(index, context, navItems);
              },
              onLogout: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
            ),
      body: Stack(
        children: [
          Row(
            children: [
              if (context.isDesktop)
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: colors.primary,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Anas Bin Malik\nCentre',
                                style: context.typography.bodyLargeSemiBold.copyWith(
                                  color: colors.white,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Expanded(
                        child: ListView.builder(
                          itemCount: navItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemBuilder: (context, index) {
                            final item = navItems[index];
                            final selected = index == selectedIndex;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => _onItemTapped(index, context, navItems),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? colors.white.withValues(alpha: 0.09)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? colors.secondary.withValues(alpha: 0.45)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 18,
                                        color: selected
                                            ? colors.secondary
                                            : colors.white.withValues(alpha: 0.75),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        item.label,
                                        style: context.typography.bodyMediumSemiBold.copyWith(
                                          color: selected
                                              ? colors.white
                                              : colors.white.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                        child: InkWell(
                          onTap: () => _logout(context),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                  color: colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: context.typography.bodyMediumSemiBold.copyWith(
                                    color: colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (context.isTablet)
                NavigationRail(
                  onDestinationSelected: (index) =>
                      _onItemTapped(index, context, navItems),
                  destinations: navItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                  selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                ),
              Expanded(child: widget.child),
            ],
          ),
          if (!context.isDesktop)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_rounded,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: context.isMobile && mobileNavItems.length >= 2
          ? NavigationBar(
              selectedIndex: (() {
                final mobileIndex = mobileNavItems.indexWhere(
                  (item) =>
                      currentLocation == item.route ||
                      currentLocation.startsWith('${item.route}/'),
                );
                return mobileIndex < 0 ? 0 : mobileIndex;
              })(),
              onDestinationSelected: (index) =>
                  _onItemTapped(index, context, mobileNavItems),
              destinations: mobileNavItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.mobileLabel ?? item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }

  void _onItemTapped(
    int index,
    BuildContext context,
    List<AppNavItem> navItems,
  ) {
    if (index < navItems.length) {
      context.go(navItems[index].route);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ref.read(authControllerProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(RouteNames.login);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }
}

class _MobileShellDrawer extends StatelessWidget {
  const _MobileShellDrawer({
    required this.userName,
    required this.navItems,
    required this.currentLocation,
    required this.onItemTap,
    required this.onLogout,
  });

  final String userName;
  final List<AppNavItem> navItems;
  final String currentLocation;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: colors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.secondary,
                    child: Icon(Icons.person_rounded, color: colors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anas Bin Malik Centre',
                    style: context.typography.bodyLargeSemiBold.copyWith(
                      color: colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: context.typography.bodySmall.copyWith(
                      color: colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final selected = currentLocation == item.route ||
                      currentLocation.startsWith('${item.route}/');
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: selected ? colors.primary : colors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: context.typography.bodyMediumSemiBold.copyWith(
                        color: selected ? colors.primary : colors.textPrimary,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: selected
                        ? colors.secondary.withValues(alpha: 0.15)
                        : null,
                    onTap: () => onItemTap(index),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
