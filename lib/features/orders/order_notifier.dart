import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/models/order_model.dart';
import 'orders_repository.dart';

/// Holds the in-progress cart items before they are submitted to the API.
@immutable
class CartState {
  const CartState({
    this.order,
    this.cartItems = const {},
    this.isSubmitting = false,
    this.error,
  });

  /// Existing order loaded from the API (null if creating new).
  final OrderModel? order;

  /// Local cart: menuItemId → quantity (items not yet sent to API).
  final Map<String, int> cartItems;

  final bool isSubmitting;
  final String? error;

  bool get isEmpty => cartItems.isEmpty;

  double get cartTotal => cartItems.entries.fold(
        0.0,
        (sum, e) => sum + (e.value * 0),
      );

  int quantityOf(String menuItemId) => cartItems[menuItemId] ?? 0;

  CartState copyWith({
    OrderModel? order,
    Map<String, int>? cartItems,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearOrder = false,
  }) =>
      CartState(
        order: clearOrder ? null : order ?? this.order,
        cartItems: cartItems ?? this.cartItems,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : error ?? this.error,
      );
}

final orderNotifierProvider =
    NotifierProvider<OrderNotifier, CartState>(OrderNotifier.new);

class OrderNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  /// Load an existing order (e.g., for a table that already has one).
  Future<void> loadOrder(String orderId) async {
    try {
      final order = await _repo.getOrder(orderId);
      state = state.copyWith(order: order, cartItems: {});
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Try to find an open order for a table; returns orderId if found.
  Future<String?> findOpenOrderForTable(String tableId) async {
    try {
      final orders = await _repo.getOpenOrdersForTable(tableId);
      if (orders.isNotEmpty) {
        state = state.copyWith(order: orders.first, cartItems: {});
        return orders.first.id;
      }
    } catch (_) {}
    return null;
  }

  void addToCart(MenuItemModel item) {
    final current = state.cartItems[item.id] ?? 0;
    state = state.copyWith(
      cartItems: {...state.cartItems, item.id: current + 1},
      clearError: true,
    );
  }

  void removeFromCart(String menuItemId) {
    final current = state.cartItems[menuItemId] ?? 0;
    if (current <= 1) {
      final updated = Map<String, int>.from(state.cartItems)
        ..remove(menuItemId);
      state = state.copyWith(cartItems: updated);
    } else {
      state = state.copyWith(
        cartItems: {...state.cartItems, menuItemId: current - 1},
      );
    }
  }

  /// Submit cart items to the API (create or update the order).
  Future<OrderModel?> submitCart({
    required String? tableId,
    required List<MenuItemModel> menuItems,
  }) async {
    if (state.cartItems.isEmpty) return state.order;
    state = state.copyWith(isSubmitting: true, clearError: true);

    final items = state.cartItems.entries.map((e) {
      return {'menuItemId': e.key, 'quantity': e.value};
    }).toList();

    try {
      OrderModel order;
      if (state.order != null) {
        order = await _repo.addItems(
          orderId: state.order!.id,
          items: items,
        );
      } else {
        order = await _repo.createOrder(tableId: tableId, items: items);
      }
      state = CartState(order: order);
      return order;
    } on Exception catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const CartState();
}
