import 'package:abm_madrasa/core/auth/role_permissions.dart';
import 'package:abm_madrasa/core/providers/institute_provider.dart';
import 'package:abm_madrasa/core/router/route_names.dart';
import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/auth/domain/user_model.dart';
import 'package:abm_madrasa/features/auth/presentation/auth_controller.dart';
import 'package:abm_madrasa/features/settings/presentation/permission_controller.dart';
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
    final allowedModules = user != null ? ref.read(permissionControllerProvider.notifier).getPermissionsForRole(user.role) : <String>{};
    
    final navItems = user?.role.navigationItems(allowedModules) ??
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
                            final hasChildren = item.children != null && item.children!.isNotEmpty;
                            final isChildSelected = hasChildren && item.children!.any(
                              (child) => currentLocation == child.route || currentLocation.startsWith('${child.route}/')
                            );
                            final isExpanded = selected || isChildSelected;

                            if (hasChildren) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: isExpanded,
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    collapsedShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    backgroundColor: isExpanded ? colors.white.withValues(alpha: 0.05) : Colors.transparent,
                                    collapsedBackgroundColor: Colors.transparent,
                                    iconColor: colors.white.withValues(alpha: 0.75),
                                    collapsedIconColor: colors.white.withValues(alpha: 0.75),
                                    title: Row(
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 18,
                                          color: isExpanded ? colors.secondary : colors.white.withValues(alpha: 0.75),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: context.typography.bodyMediumSemiBold.copyWith(
                                              color: isExpanded ? colors.white : colors.white.withValues(alpha: 0.75),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: item.children!.map((child) {
                                      final childSelected = currentLocation == child.route || currentLocation.startsWith('${child.route}/');
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 36, bottom: 8, right: 8, top: 4),
                                        child: InkWell(
                                          onTap: () => context.go(child.route),
                                          borderRadius: BorderRadius.circular(14),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: childSelected ? colors.white.withValues(alpha: 0.09) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: childSelected ? colors.secondary.withValues(alpha: 0.45) : Colors.transparent,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  child.icon,
                                                  size: 16,
                                                  color: childSelected ? colors.secondary : colors.white.withValues(alpha: 0.65),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    child.label,
                                                    style: context.typography.bodyMedium.copyWith(
                                                      color: childSelected ? colors.white : colors.white.withValues(alpha: 0.65),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }

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
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: context.typography.bodyMediumSemiBold.copyWith(
                                            color: selected
                                                ? colors.white
                                                : colors.white.withValues(alpha: 0.75),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(0),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout? You will need to sign in again to continue.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Logout'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;
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
                  final hasChildren = item.children != null && item.children!.isNotEmpty;
                  final isChildSelected = hasChildren && item.children!.any(
                    (child) => currentLocation == child.route || currentLocation.startsWith('${child.route}/')
                  );
                  final isExpanded = selected || isChildSelected;

                  if (hasChildren) {
                    return Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: isExpanded,
                        leading: Icon(
                          item.icon,
                          color: isExpanded ? colors.primary : colors.textSecondary,
                        ),
                        title: Text(
                          item.label,
                          style: context.typography.bodyMediumSemiBold.copyWith(
                            color: isExpanded ? colors.primary : colors.textPrimary,
                          ),
                        ),
                        children: item.children!.map((child) {
                          final childSelected = currentLocation == child.route || currentLocation.startsWith('${child.route}/');
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 54, right: 16),
                            leading: Icon(
                              child.icon,
                              size: 20,
                              color: childSelected ? colors.primary : colors.textSecondary,
                            ),
                            title: Text(
                              child.label,
                              style: context.typography.bodyMedium.copyWith(
                                color: childSelected ? colors.primary : colors.textPrimary,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            tileColor: childSelected ? colors.secondary.withValues(alpha: 0.15) : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              context.go(child.route);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }

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
    final user = ref.watch(authControllerProvider).value;
    final canChangeInstitute = user?.role == AppRoles.superAdmin || 
                               user?.role == AppRoles.itAdmin || 
                               user?.role == AppRoles.headMaster;
    final colors = context.colors;

    Widget content = Container(
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
          if (canChangeInstitute) ...[
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronsUpDown, size: 14, color: colors.white.withValues(alpha: 0.55)),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: canChangeInstitute
          ? GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => _InstitutePickerSheetSidebar(widgetRef: ref),
                );
              },
              child: content,
            )
          : content,
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
    final user = ref.watch(authControllerProvider).value;
    final canChangeInstitute = user?.role == AppRoles.superAdmin || 
                               user?.role == AppRoles.itAdmin || 
                               user?.role == AppRoles.headMaster;

    final content = Container(
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
              if (canChangeInstitute)
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
    );

    return canChangeInstitute
        ? GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _InstitutePickerSheetSidebar(widgetRef: ref),
              );
            },
            child: content,
          )
        : content;
  }
}
