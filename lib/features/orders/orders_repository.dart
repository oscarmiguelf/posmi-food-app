import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/order_model.dart';
import '../../core/providers/api_client_provider.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(dioProvider)),
);

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  /// Creates a new order or returns an existing one for the table (idempotent).
  Future<OrderModel> createOrder({
    String? tableId,
    required List<Map<String, dynamic>> items,
    List<String>? extraTableIds,
    String? customerName,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'idempotencyKey': _uuid.v4(),
        'tableId': ?tableId,
        'items': items,
        if (extraTableIds != null && extraTableIds.isNotEmpty)
          'extraTableIds': extraTableIds,
        if (customerName != null && customerName.isNotEmpty)
          'customerName': customerName,
      },
    );
    return OrderModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> getOrder(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/orders/$id');
    return OrderModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// Returns open orders for a specific table.
  Future<List<OrderModel>> getOpenOrdersForTable(String tableId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: {'tableId': tableId, 'status': 'open'},
    );
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns all open/in_kitchen orders (for KDS).
  Future<List<OrderModel>> getActiveOrders() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: {'status': 'open'},
    );
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> addItems({
    required String orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/items',
      data: {'items': items},
    );
    return OrderModel.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> closeOrder({
    required String orderId,
    required int version,
    required List<Map<String, dynamic>> payments,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/close',
      data: {
        'idempotencyKey': _uuid.v4(),
        'version': version,
        'payments': payments,
      },
    );
    return res.data!['data'] as Map<String, dynamic>;
  }

  Future<void> updateItemStatus({
    required String orderId,
    required String itemId,
    required String itemStatus,
  }) async {
    await _dio.patch<void>(
      '/orders/$orderId/items/$itemId/status',
      data: {'itemStatus': itemStatus},
    );
  }
}
