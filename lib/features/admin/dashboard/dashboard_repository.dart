import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dioProvider)),
);

class DashboardData {
  const DashboardData({
    required this.dailySales,
    required this.openOrders,
    required this.openCashSessions,
    required this.lowStockAlerts,
    required this.topItems,
  });

  final String dailySales;
  final int openOrders;
  final int openCashSessions;
  final List<Map<String, dynamic>> lowStockAlerts;
  final List<Map<String, dynamic>> topItems;

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        dailySales: json['dailySales']?.toString() ?? '0.00',
        openOrders: json['openOrders'] as int? ?? 0,
        openCashSessions: json['openCashSessions'] as int? ?? 0,
        lowStockAlerts: (json['lowStockAlerts'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
        topItems: (json['topItems'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
      );
}

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  Future<DashboardData> getDashboard() async {
    final res = await _dio.get<Map<String, dynamic>>('/reports/dashboard');
    return DashboardData.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }
}
