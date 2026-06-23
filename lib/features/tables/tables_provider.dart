import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/table_model.dart';
import '../../core/websocket/socket_service.dart';
import 'tables_repository.dart';

/// Real-time table updates via Socket.IO; falls back to 5s polling
/// when the socket is unavailable (e.g. web without CORS).
final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableModel>>(
  TablesNotifier.new,
);

class TablesNotifier extends AsyncNotifier<List<TableModel>> {
  Timer? _pollTimer;

  @override
  Future<List<TableModel>> build() async {
    ref.onDispose(_cleanup);
    _subscribeSocket();
    // Polling every 5s as guaranteed fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await AsyncValue.guard(_fetch);
      if (result is AsyncData) state = result;
    });
    return _fetch();
  }

  Future<List<TableModel>> _fetch() =>
      ref.read(tablesRepositoryProvider).getTables();

  void _subscribeSocket() {
    if (kIsWeb) return; // Socket.IO CORS may block on web in dev; rely on poll
    try {
      final socket = ref.read(socketServiceProvider);
      socket.on('table.status_changed', (_) async {
        final result = await AsyncValue.guard(_fetch);
        if (result is AsyncData) state = result;
      });
    } catch (_) {}
  }

  void _cleanup() {
    _pollTimer?.cancel();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
