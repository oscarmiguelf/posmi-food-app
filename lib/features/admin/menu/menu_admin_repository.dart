import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/providers/api_client_provider.dart';

final menuAdminRepositoryProvider = Provider<MenuAdminRepository>(
  (ref) => MenuAdminRepository(ref.watch(dioProvider)),
);

class MenuAdminRepository {
  MenuAdminRepository(this._dio);
  final Dio _dio;

  Future<List<MenuItemModel>> getAll() async {
    final res = await _dio.get<Map<String, dynamic>>('/menu-items');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MenuItemModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/menu-items', data: body);
    return MenuItemModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<MenuItemModel> update(
      String id, Map<String, dynamic> body) async {
    final res = await _dio.patch<Map<String, dynamic>>(
        '/menu-items/$id', data: body);
    return MenuItemModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/menu-items/$id');
  }
}
