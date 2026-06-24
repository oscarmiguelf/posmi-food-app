import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/websocket/socket_service.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(dioProvider)),
);

final menuItemsProvider =
    AsyncNotifierProvider<MenuItemsNotifier, List<MenuItemModel>>(
        MenuItemsNotifier.new);

class MenuItemsNotifier extends AsyncNotifier<List<MenuItemModel>> {
  Timer? _pollTimer;

  @override
  Future<List<MenuItemModel>> build() async {
    ref.onDispose(() => _pollTimer?.cancel());
    _subscribeSocket();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final result = await AsyncValue.guard(_fetch);
      if (result is AsyncData) state = result;
    });
    return _fetch();
  }

  Future<List<MenuItemModel>> _fetch() =>
      ref.read(menuRepositoryProvider).getMenuItems();

  void _subscribeSocket() {
    if (kIsWeb) return;
    try {
      final socket = ref.read(socketServiceProvider);
      socket.on('menu.updated', (_) async {
        final result = await AsyncValue.guard(_fetch);
        if (result is AsyncData) state = result;
      });
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

class MenuRepository {
  MenuRepository(this._dio);
  final Dio _dio;

  Future<List<MenuItemModel>> getMenuItems() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/menu-items',
      queryParameters: {'isAvailable': true},
    );
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
