import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_notifier.dart';
import '../../features/auth/login_screen.dart';
import '../../features/tables/tables_screen.dart';
import '../../features/orders/order_screen.dart';
import '../../features/orders/payment_screen.dart';
import '../../features/kds/kds_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/tables',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;
      final isLogin = state.matchedLocation == '/login';
      if (!auth.isAuthenticated && !isLogin) return '/login';
      if (auth.isAuthenticated && isLogin) return '/tables';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/tables',
        builder: (context, _) => const TablesScreen(),
      ),
      GoRoute(
        path: '/orders/new',
        builder: (_, state) {
          final tableId = state.uri.queryParameters['tableId'];
          final tableLabel = state.uri.queryParameters['tableLabel'];
          return OrderScreen(tableId: tableId, tableLabel: tableLabel);
        },
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) {
          final orderId = state.pathParameters['id']!;
          final tableLabel = state.uri.queryParameters['tableLabel'];
          return OrderScreen(orderId: orderId, tableLabel: tableLabel);
        },
      ),
      GoRoute(
        path: '/orders/:id/payment',
        builder: (_, state) {
          final orderId = state.pathParameters['id']!;
          final total = state.uri.queryParameters['total'] ?? '0';
          final version = int.tryParse(
                state.uri.queryParameters['version'] ?? '0',
              ) ??
              0;
          return PaymentScreen(
            orderId: orderId,
            total: total,
            version: version,
          );
        },
      ),
      GoRoute(
        path: '/kds',
        builder: (context, _) => const KdsScreen(),
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref<GoRouter> ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}
