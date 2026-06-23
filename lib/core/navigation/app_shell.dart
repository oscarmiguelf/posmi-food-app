import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../auth/current_user.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final items = _navItems(user?.isAdmin ?? false);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              items: items,
              selectedIndex: navigationShell.currentIndex,
              onTap: (i) => navigationShell.goBranch(i,
                  initialLocation: i == navigationShell.currentIndex),
              user: user,
              onLogout: () => ref.read(authProvider.notifier).logout(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      drawer: _DrawerNav(
        items: items,
        selectedIndex: navigationShell.currentIndex,
        onTap: (i) {
          Navigator.of(context).pop();
          navigationShell.goBranch(i,
              initialLocation: i == navigationShell.currentIndex);
        },
        user: user,
        onLogout: () => ref.read(authProvider.notifier).logout(),
      ),
      appBar: AppBar(
        title: Text(items[navigationShell.currentIndex].label),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
    );
  }

  List<_NavItem> _navItems(bool isAdmin) => [
        const _NavItem(
            icon: Icons.table_restaurant_outlined,
            label: 'Mesas',
            path: '/tables'),
        const _NavItem(
            icon: Icons.tv_outlined, label: 'Cocina', path: '/kds'),
        if (isAdmin) ...[
          const _NavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              path: '/admin/dashboard'),
          const _NavItem(
              icon: Icons.analytics_outlined,
              label: 'Reportes',
              path: '/admin/reports'),
          const _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Menú',
              path: '/admin/menu'),
          const _NavItem(
              icon: Icons.inventory_2_outlined,
              label: 'Ingredientes',
              path: '/admin/ingredients'),
          const _NavItem(
              icon: Icons.people_outline,
              label: 'Usuarios',
              path: '/admin/users'),
          const _NavItem(
              icon: Icons.table_bar_outlined,
              label: 'Mesas',
              path: '/admin/tables'),
          const _NavItem(
              icon: Icons.kitchen_outlined,
              label: 'Estaciones',
              path: '/admin/stations'),
          const _NavItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              path: '/admin/setup'),
        ],
      ];
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.user,
    required this.onLogout,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final void Function(int) onTap;
  final CurrentUser? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    color: AppColors.primaryContent),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'PosmiFood',
                  style: AppTypography.headingMd
                      .copyWith(color: AppColors.primaryContent),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              children: items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final selected = i == selectedIndex;
                return _SidebarTile(
                  item: item,
                  selected: selected,
                  onTap: () => onTap(i),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // User footer
          ListTile(
            dense: true,
            leading: const Icon(Icons.account_circle_outlined,
                color: Colors.white70),
            title: Text(
              user?.email ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              user?.roleName ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
              tooltip: 'Cerrar sesión',
              onPressed: onLogout,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: selected ? Colors.white24 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(item.icon,
            color: selected ? AppColors.primaryContent : Colors.white70,
            size: 20),
        title: Text(
          item.label,
          style: AppTypography.bodyMd.copyWith(
            color: selected ? AppColors.primaryContent : Colors.white70,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerNav extends StatelessWidget {
  const _DrawerNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
    required this.user,
    required this.onLogout,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final void Function(int) onTap;
  final CurrentUser? user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    color: AppColors.primaryContent, size: 32),
                const SizedBox(width: AppSpacing.sm),
                Text('PosmiFood',
                    style: AppTypography.headingLg
                        .copyWith(color: AppColors.primaryContent)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  selected: i == selectedIndex,
                  selectedTileColor: AppColors.primary.withAlpha(20),
                  onTap: () => onTap(i),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
