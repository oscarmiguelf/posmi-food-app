import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/table_model.dart';
import 'tables_repository.dart';

/// Polls every 5 seconds to reflect table status changes from other devices.
final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<TableModel>>(
  TablesNotifier.new,
);

class TablesNotifier extends AsyncNotifier<List<TableModel>> {
  Timer? _timer;

  @override
  Future<List<TableModel>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _startPolling();
    return _fetch();
  }

  Future<List<TableModel>> _fetch() =>
      ref.read(tablesRepositoryProvider).getTables();

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final tables = await AsyncValue.guard(_fetch);
      if (tables is AsyncData) state = tables;
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}
