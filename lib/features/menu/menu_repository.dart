import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/providers/api_client_provider.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
  (ref) => MenuRepository(ref.watch(dioProvider)),
);

final menuItemsProvider = FutureProvider<List<MenuItemModel>>((ref) {
  return ref.watch(menuRepositoryProvider).getMenuItems();
});

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
