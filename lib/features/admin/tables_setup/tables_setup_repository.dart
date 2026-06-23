import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';

final tablesSetupRepositoryProvider = Provider<TablesSetupRepository>(
  (ref) => TablesSetupRepository(ref.watch(dioProvider)),
);

class TableSetupModel {
  const TableSetupModel({
    required this.id,
    required this.label,
    required this.capacity,
    required this.status,
  });

  final String id;
  final String label;
  final int capacity;
  final String status;

  factory TableSetupModel.fromJson(Map<String, dynamic> json) =>
      TableSetupModel(
        id: json['id'] as String,
        label: json['label'] as String,
        capacity: json['capacity'] as int,
        status: json['status'] as String,
      );
}

class TablesSetupRepository {
  TablesSetupRepository(this._dio);
  final Dio _dio;

  Future<List<TableSetupModel>> getAll() async {
    final res = await _dio.get<Map<String, dynamic>>('/tables');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => TableSetupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TableSetupModel> create(String label, int capacity) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/tables',
      data: {'label': label, 'capacity': capacity},
    );
    return TableSetupModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<TableSetupModel> update(
      String id, String label, int capacity) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/tables/$id',
      data: {'label': label, 'capacity': capacity, 'version': 0},
    );
    return TableSetupModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/tables/$id');
  }
}
