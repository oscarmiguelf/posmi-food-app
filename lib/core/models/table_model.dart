import 'package:flutter/material.dart';
import '../../design_system/tokens/app_colors.dart';

class TableModel {
  const TableModel({
    required this.id,
    required this.label,
    required this.capacity,
    required this.status,
  });

  final String id;
  final String label;
  final int capacity;
  final String status; // free | occupied | bill_requested

  factory TableModel.fromJson(Map<String, dynamic> json) => TableModel(
        id: json['id'] as String,
        label: json['label'] as String,
        capacity: json['capacity'] as int,
        status: json['status'] as String,
      );

  Color get statusColor => switch (status) {
        'occupied' => AppColors.tableOccupied,
        'bill_requested' => AppColors.tableBillRequested,
        _ => AppColors.tableFree,
      };

  Color get statusTextColor => switch (status) {
        'bill_requested' => AppColors.warningContent,
        _ => AppColors.primaryContent,
      };

  String get statusLabel => switch (status) {
        'occupied' => 'Ocupada',
        'bill_requested' => 'Cuenta',
        _ => 'Libre',
      };
}
