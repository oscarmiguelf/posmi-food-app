import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order_model.dart';
import '../../core/websocket/socket_service.dart';
import '../orders/orders_repository.dart';

final kdsStationFilterProvider = StateProvider<String?>((_) => null);

final kdsOrdersProvider =
    AsyncNotifierProvider<KdsNotifier, List<OrderModel>>(KdsNotifier.new);

class KdsNotifier extends AsyncNotifier<List<OrderModel>> {
  Timer? _pollTimer;

  @override
  Future<List<OrderModel>> build() async {
    ref.onDispose(() => _pollTimer?.cancel());
    _subscribeSocket();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final result = await AsyncValue.guard(_fetch);
      if (result is AsyncData) state = result;
    });
    return _fetch();
  }

  Future<List<OrderModel>> _fetch() =>
      ref.read(ordersRepositoryProvider).getActiveOrders();

  void _subscribeSocket() {
    if (kIsWeb) return;
    try {
      final socket = ref.read(socketServiceProvider);
      for (final event in [
        'order.created',
        'order.item.routed',
        'order.closed',
      ]) {
        socket.on(event, (_) async {
          final result = await AsyncValue.guard(_fetch);
          if (result is AsyncData) state = result;
        });
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
