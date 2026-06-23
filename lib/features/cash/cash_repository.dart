import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/api_client_provider.dart';

final cashRepositoryProvider = Provider<CashRepository>(
  (ref) => CashRepository(ref.watch(dioProvider)),
);

class CashSessionModel {
  const CashSessionModel({
    required this.id,
    required this.openedAt,
    required this.openingAmount,
    this.closedAt,
    this.closingAmountDeclared,
    this.closingAmountSystem,
    this.cashierName,
  });

  final String id;
  final DateTime openedAt;
  final String openingAmount;
  final DateTime? closedAt;
  final String? closingAmountDeclared;
  final String? closingAmountSystem;
  final String? cashierName;

  bool get isOpen => closedAt == null;

  factory CashSessionModel.fromJson(Map<String, dynamic> json) =>
      CashSessionModel(
        id: json['id'] as String,
        openedAt: DateTime.parse(json['openedAt'] as String),
        openingAmount: json['openingAmount']?.toString() ?? '0.00',
        closedAt: json['closedAt'] != null
            ? DateTime.parse(json['closedAt'] as String)
            : null,
        closingAmountDeclared:
            json['closingAmountDeclared']?.toString(),
        closingAmountSystem:
            json['closingAmountSystem']?.toString(),
        cashierName:
            (json['cashier'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

class CashMovementModel {
  const CashMovementModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String type;
  final String amount;
  final String paymentMethod;
  final DateTime createdAt;
  final String? notes;

  factory CashMovementModel.fromJson(Map<String, dynamic> json) =>
      CashMovementModel(
        id: json['id'] as String,
        type: json['type'] as String,
        amount: json['amount']?.toString() ?? '0.00',
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        createdAt: DateTime.parse(json['createdAt'] as String),
        notes: json['notes'] as String?,
      );
}

class CashReportModel {
  const CashReportModel({
    required this.session,
    required this.movements,
    required this.byPaymentMethod,
    required this.revenue,
  });

  final Map<String, dynamic> session;
  final Map<String, dynamic> movements;
  final Map<String, dynamic> byPaymentMethod;
  final Map<String, dynamic> revenue;

  factory CashReportModel.fromJson(Map<String, dynamic> json) =>
      CashReportModel(
        session: json['session'] as Map<String, dynamic>,
        movements: json['movements'] as Map<String, dynamic>,
        byPaymentMethod:
            json['byPaymentMethod'] as Map<String, dynamic>,
        revenue: json['revenue'] as Map<String, dynamic>,
      );
}

class CashRepository {
  CashRepository(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<List<CashSessionModel>> list() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/cash-sessions');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) =>
            CashSessionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CashSessionModel> open(String openingAmount) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/cash-sessions/open',
            data: {
              'idempotencyKey': _uuid.v4(),
              'openingAmount': openingAmount,
            });
    return CashSessionModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> registerMovement({
    required String sessionId,
    required String type,
    required String amount,
    required String paymentMethod,
    String? notes,
  }) async {
    await _dio.post<void>(
      '/cash-sessions/$sessionId/movements',
      data: {
        'idempotencyKey': _uuid.v4(),
        'type': type,
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> close({
    required String sessionId,
    required String closingAmountDeclared,
  }) async {
    await _dio.post<void>(
      '/cash-sessions/$sessionId/close',
      data: {
        'idempotencyKey': _uuid.v4(),
        'closingAmountDeclared': closingAmountDeclared,
      },
    );
  }

  Future<CashReportModel> report(String sessionId) async {
    final res = await _dio
        .get<Map<String, dynamic>>('/cash-sessions/$sessionId/report');
    return CashReportModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }
}
