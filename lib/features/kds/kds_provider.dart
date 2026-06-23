import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/order_model.dart';
import '../orders/orders_repository.dart';

final kdsStationFilterProvider = StateProvider<String?>((_) => null);

final kdsOrdersProvider =
    AsyncNotifierProvider<KdsNotifier, List<OrderModel>>(KdsNotifier.new);

class KdsNotifier extends AsyncNotifier<List<OrderModel>> {
  Timer? _timer;

  @override
  Future<List<OrderModel>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _startPolling();
    return _fetch();
  }

  Future<List<OrderModel>> _fetch() =>
      ref.read(ordersRepositoryProvider).getActiveOrders();

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final result = await AsyncValue.guard(_fetch);
      if (result is AsyncData) state = result;
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
