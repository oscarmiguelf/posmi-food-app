import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/models/order_model.dart';
import 'orders_repository.dart';

@immutable
class CartItem {
  const CartItem({
    required this.menuItemId,
    required this.quantity,
    this.notes,
    this.modifiers = const [],
  });
  final String menuItemId;
  final int quantity;
  final String? notes;
  final List<ItemModifier> modifiers;

  CartItem copyWith({int? quantity, String? notes, List<ItemModifier>? modifiers}) =>
      CartItem(
        menuItemId: menuItemId,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        modifiers: modifiers ?? this.modifiers,
      );

  Map<String, dynamic> toApiJson() => {
        'menuItemId': menuItemId,
        'quantity': quantity,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (modifiers.isNotEmpty)
          'modifiers': modifiers.map((m) => m.toJson()).toList(),
      };
}

@immutable
class CartState {
  const CartState({
    this.order,
    this.items = const [],
    this.isSubmitting = false,
    this.error,
    this.extraTableIds = const [],
    this.customerName,
  });

  final OrderModel? order;
  final List<CartItem> items;
  final bool isSubmitting;
  final String? error;
  final List<String> extraTableIds;
  final String? customerName;

  bool get isEmpty => items.isEmpty;

  // For backward compat with menu grid badges
  Map<String, int> get cartItems {
    final map = <String, int>{};
    for (final item in items) {
      map[item.menuItemId] = (map[item.menuItemId] ?? 0) + item.quantity;
    }
    return map;
  }

  int quantityOf(String menuItemId) =>
      items.where((i) => i.menuItemId == menuItemId).fold(0, (s, i) => s + i.quantity);

  CartState copyWith({
    OrderModel? order,
    List<CartItem>? items,
    bool? isSubmitting,
    String? error,
    List<String>? extraTableIds,
    String? customerName,
    bool clearError = false,
    bool clearOrder = false,
    bool clearCustomerName = false,
  }) =>
      CartState(
        order: clearOrder ? null : order ?? this.order,
        items: items ?? this.items,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        error: clearError ? null : error ?? this.error,
        extraTableIds: extraTableIds ?? this.extraTableIds,
        customerName: clearCustomerName ? null : customerName ?? this.customerName,
      );
}

final orderNotifierProvider =
    NotifierProvider<OrderNotifier, CartState>(OrderNotifier.new);

class OrderNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  Future<void> loadOrder(String orderId) async {
    try {
      final order = await _repo.getOrder(orderId);
      state = state.copyWith(order: order, items: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> findOpenOrderForTable(String tableId) async {
    try {
      final orders = await _repo.getOpenOrdersForTable(tableId);
      if (orders.isNotEmpty) {
        state = state.copyWith(order: orders.first, items: []);
        return orders.first.id;
      }
    } catch (_) {}
    return null;
  }

  void addToCart(MenuItemModel item, {String? notes, List<ItemModifier>? modifiers}) {
    if ((modifiers != null && modifiers.isNotEmpty) || (notes != null && notes.isNotEmpty)) {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(
            menuItemId: item.id,
            quantity: 1,
            notes: notes,
            modifiers: modifiers ?? [],
          ),
        ],
        clearError: true,
      );
    } else {
      final existing = state.items.indexWhere(
          (i) => i.menuItemId == item.id && i.modifiers.isEmpty && (i.notes == null || i.notes!.isEmpty));
      if (existing >= 0) {
        final updated = List<CartItem>.from(state.items);
        updated[existing] = updated[existing].copyWith(quantity: updated[existing].quantity + 1);
        state = state.copyWith(items: updated, clearError: true);
      } else {
        state = state.copyWith(
          items: [...state.items, CartItem(menuItemId: item.id, quantity: 1)],
          clearError: true,
        );
      }
    }
  }

  void removeFromCart(String menuItemId) {
    final idx = state.items.lastIndexWhere((i) => i.menuItemId == menuItemId);
    if (idx < 0) return;
    final item = state.items[idx];
    final updated = List<CartItem>.from(state.items);
    if (item.quantity <= 1) {
      updated.removeAt(idx);
    } else {
      updated[idx] = item.copyWith(quantity: item.quantity - 1);
    }
    state = state.copyWith(items: updated);
  }

  void setExtraTables(List<String> tableIds) {
    state = state.copyWith(extraTableIds: tableIds);
  }

  void setCustomerName(String? name) {
    state = state.copyWith(customerName: name);
  }

  Future<OrderModel?> submitCart({
    required String? tableId,
    required List<MenuItemModel> menuItems,
  }) async {
    if (state.items.isEmpty) return state.order;
    state = state.copyWith(isSubmitting: true, clearError: true);

    final apiItems = state.items.map((i) => i.toApiJson()).toList();

    try {
      OrderModel order;
      if (state.order != null) {
        await _repo.addItems(orderId: state.order!.id, items: apiItems);
        order = await _repo.getOrder(state.order!.id);
      } else {
        order = await _repo.createOrder(
          tableId: tableId,
          items: apiItems,
          extraTableIds: state.extraTableIds.isNotEmpty ? state.extraTableIds : null,
          customerName: state.customerName,
        );
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
