import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import 'package:uuid/uuid.dart';

final ingredientsRepositoryProvider = Provider<IngredientsRepository>(
  (ref) => IngredientsRepository(ref.watch(dioProvider)),
);

class IngredientModel {
  const IngredientModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.stockQuantity,
    required this.minStock,
    required this.unitCost,
  });

  final String id;
  final String name;
  final String unit;
  final double stockQuantity;
  final double minStock;
  final double unitCost;

  bool get isLowStock => stockQuantity <= minStock;

  factory IngredientModel.fromJson(Map<String, dynamic> json) =>
      IngredientModel(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String,
        stockQuantity:
            double.tryParse(json['stockQuantity']?.toString() ?? '0') ?? 0,
        minStock:
            double.tryParse(json['minStock']?.toString() ?? '0') ?? 0,
        unitCost:
            double.tryParse(json['unitCost']?.toString() ?? '0') ?? 0,
      );
}

class IngredientsRepository {
  IngredientsRepository(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Future<List<IngredientModel>> getAll() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/ingredients');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => IngredientModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IngredientModel> create(Map<String, dynamic> body) async {
    final res =
        await _dio.post<Map<String, dynamic>>('/ingredients', data: body);
    return IngredientModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<IngredientModel> update(
      String id, Map<String, dynamic> body) async {
    final res = await _dio
        .patch<Map<String, dynamic>>('/ingredients/$id', data: body);
    return IngredientModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> adjust({
    required String id,
    required double delta,
    required String reason,
  }) async {
    await _dio.post<void>(
      '/ingredients/$id/adjustments',
      data: {
        'idempotencyKey': _uuid.v4(),
        'quantityDelta': delta,
        'reason': reason,
      },
    );
  }
}
