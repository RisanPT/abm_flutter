import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                      _SidebarInstituteSection(ref: ref),
                      const SizedBox(height: 16),
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
            _DrawerInstituteHeader(userName: userName),
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

// ─── Premium Sidebar Institute Section ───────────────────────────────────────

class _SidebarInstituteSection extends ConsumerWidget {
  const _SidebarInstituteSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final institute = ref.watch(selectedInstituteProvider);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => _InstitutePickerSheetSidebar(widgetRef: ref),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.secondary, colors.secondary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(institute.icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      institute.name,
                      style: context.typography.bodyMediumSemiBold.copyWith(
                        color: colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin, size: 10, color: colors.white.withValues(alpha: 0.55)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            institute.location,
                            style: context.typography.bodySmall.copyWith(
                              color: colors.white.withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(LucideIcons.chevronsUpDown, size: 14, color: colors.white.withValues(alpha: 0.55)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Institute Picker Sheet (used from sidebar/drawer) ────────────────────────

class _InstitutePickerSheetSidebar extends ConsumerWidget {
  const _InstitutePickerSheetSidebar({required this.widgetRef});
  final WidgetRef widgetRef;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final colors = context.colors;
    final institutesAsync = widgetRef.watch(instituteListProvider);
    final selected = widgetRef.watch(selectedInstituteProvider);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, -8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(100)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.building2, color: colors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Institute',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    institutesAsync.maybeWhen(
                      data: (list) => Text(
                        '${list.length} institute${list.length == 1 ? '' : 's'} available',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          institutesAsync.when(
            data: (institutes) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: institutes.map((inst) {
                  final isSelected = inst.id == selected.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        widgetRef.read(selectedInstituteProvider.notifier).setInstitute(inst);
                        Navigator.of(context).pop();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.primary.withValues(alpha: 0.06) : colors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? colors.primary.withValues(alpha: 0.4) : colors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [colors.primary, colors.primary.withValues(alpha: 0.7)]
                                      : [colors.border, colors.border.withValues(alpha: 0.5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                inst.icon,
                                color: isSelected ? Colors.white : colors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inst.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? colors.primary : colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(LucideIcons.mapPin, size: 11, color: colors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(inst.location, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? Container(
                                      key: const ValueKey('chk'),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                                      child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
                                    )
                                  : const SizedBox(key: ValueKey('emp'), width: 24),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: colors.primary),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load institutes: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Mobile Drawer Header ─────────────────────────────────────────────

class _DrawerInstituteHeader extends ConsumerWidget {
  const _DrawerInstituteHeader({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final institute = ref.watch(selectedInstituteProvider);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _InstitutePickerSheetSidebar(widgetRef: ref),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primary, colors.primary.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(institute.icon, color: colors.primary, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.repeat2, size: 12, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text('Switch', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              institute.name,
              style: context.typography.bodyLargeSemiBold.copyWith(color: colors.white, height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 11, color: colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    institute.location,
                    style: context.typography.bodySmall.copyWith(color: colors.white.withValues(alpha: 0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 13, color: colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 5),
                Text(
                  userName,
                  style: context.typography.bodySmall.copyWith(color: colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
