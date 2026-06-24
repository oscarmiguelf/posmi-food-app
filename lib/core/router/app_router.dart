import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../auth/current_user.dart';
import '../navigation/app_shell.dart';
import '../../features/auth/login_screen.dart';
import '../../features/tables/tables_screen.dart';
import '../../features/orders/order_screen.dart';
import '../../features/orders/payment_screen.dart';
import '../../features/kds/kds_screen.dart';
import '../../features/admin/dashboard/dashboard_screen.dart';
import '../../features/admin/reports/reports_screen.dart';
import '../../features/admin/menu/menu_admin_screen.dart';
import '../../features/admin/ingredients/ingredients_screen.dart';
import '../../features/admin/users/users_screen.dart';
import '../../features/admin/tables_setup/tables_setup_screen.dart';
import '../../features/admin/stations/stations_screen.dart';
import '../../features/admin/setup/setup_screen.dart';
import '../../features/admin/business/business_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/cash/cash_screen.dart';
import '../../features/admin/suppliers/suppliers_screen.dart';
import '../../features/admin/purchase_orders/purchase_orders_screen.dart';
import '../../features/admin/menu/recipe_screen.dart';
import '../../features/admin/menu_categories/menu_categories_screen.dart';
import '../../features/digital_menu/digital_menu_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/tables',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;
      final path = state.matchedLocation;
      final isPublic = path.startsWith('/menu/');
      final isLogin = path == '/login';
      if (!auth.isAuthenticated && !isLogin && !isPublic) return '/login';
      if (auth.isAuthenticated && isLogin) return '/tables';

      // Admin-only routes
      if (path.startsWith('/admin')) {
        final user = ref.read(currentUserProvider);
        if (user == null || !user.isAdmin) return '/tables';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/menu/:branchId',
        builder: (context, state) => DigitalMenuScreen(
          branchId: state.pathParameters['branchId']!,
        ),
      ),
      // Full-screen routes — no shell
      GoRoute(
        path: '/orders/new',
        builder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'];
          return OrderScreen(
            key: ValueKey('order-$tableId'),
            tableId: tableId,
            tableLabel: state.uri.queryParameters['tableLabel'],
            initialCustomerName: state.uri.queryParameters['customerName'],
          );
        },
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderScreen(
          key: ValueKey('order-${state.pathParameters['id']}'),
          orderId: state.pathParameters['id'],
          tableLabel: state.uri.queryParameters['tableLabel'],
        ),
      ),
      GoRoute(
        path: '/orders/:id/payment',
        builder: (context, state) => PaymentScreen(
          orderId: state.pathParameters['id']!,
          total: state.uri.queryParameters['total'] ?? '0',
          version:
              int.tryParse(state.uri.queryParameters['version'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/admin/menu-items/:id/recipe',
        builder: (context, state) => RecipeScreen(
          menuItemId: state.pathParameters['id']!,
          menuItemName:
              state.uri.queryParameters['name'] ?? 'Producto',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, _) => const ProfileScreen(),
      ),
      // Shell: persistent sidebar navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/tables',
                builder: (context, _) => const TablesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/kds', builder: (context, _) => const KdsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/cash',
                builder: (context, _) => const CashScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/dashboard',
                builder: (context, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/reports',
                builder: (context, _) => const ReportsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/menu',
                builder: (context, _) => const MenuAdminScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/ingredients',
                builder: (context, _) => const IngredientsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/users',
                builder: (context, _) => const UsersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/menu-categories',
                builder: (context, _) =>
                    const MenuCategoriesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/suppliers',
                builder: (context, _) => const SuppliersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/purchase-orders',
                builder: (context, _) => const PurchaseOrdersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/tables',
                builder: (context, _) => const TablesSetupScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/stations',
                builder: (context, _) => const StationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/setup',
                builder: (context, _) => const SetupScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/admin/business',
                builder: (context, _) => const BusinessScreen()),
          ]),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref<GoRouter> ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}
