import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(dioProvider)),
);

class ReportsRepository {
  ReportsRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getSales({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/sales',
      queryParameters: {'from': from, 'to': to},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPeriodSummary({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/period-summary',
      queryParameters: {'from': from, 'to': to},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSalesByHour({required String date}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/sales-by-hour',
      queryParameters: {'date': date},
    );
    return res.data!['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getProfitability() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/reports/profitability');
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInventoryVariance({
    required String from,
    required String to,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/reports/inventory-variance',
      queryParameters: {'from': from, 'to': to},
    );
    return res.data!['data'] as Map<String, dynamic>;
  }
}
