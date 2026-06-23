import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/table_model.dart';
import '../../core/providers/api_client_provider.dart';

final tablesRepositoryProvider = Provider<TablesRepository>(
  (ref) => TablesRepository(ref.watch(dioProvider)),
);

class TablesRepository {
  TablesRepository(this._dio);
  final Dio _dio;

  Future<List<TableModel>> getTables() async {
    final res = await _dio.get<Map<String, dynamic>>('/tables');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => TableModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
