class ItemModifier {
  const ItemModifier({
    required this.ingredientName,
    required this.action,
    this.extraPrice,
  });
  final String ingredientName;
  final String action; // 'remove' | 'add'
  final double? extraPrice;

  factory ItemModifier.fromJson(Map<String, dynamic> json) => ItemModifier(
        ingredientName: json['ingredientName'] as String,
        action: json['action'] as String,
        extraPrice: double.tryParse(json['extraPrice']?.toString() ?? '0'),
      );

  Map<String, dynamic> toJson() => {
        'ingredientName': ingredientName,
        'action': action,
        if (extraPrice != null && extraPrice! > 0)
          'extraPrice': extraPrice!.toStringAsFixed(2),
      };

  bool get hasCharge => action == 'add' && extraPrice != null && extraPrice! > 0;
}

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPriceWithTax,
    this.stationName,
    this.notes,
    this.modifiers = const [],
  });

  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final String unitPriceWithTax;
  final String? stationName;
  final String? notes;
  final List<ItemModifier> modifiers;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] as String,
        menuItemId: json['menuItemId'] as String,
        menuItemName: (json['menuItem'] as Map<String, dynamic>?)?['name'] as String? ??
            json['menuItemName'] as String? ??
            '',
        quantity: json['quantity'] as int,
        unitPriceWithTax: json['unitPriceWithTax']?.toString() ?? '0.00',
        stationName: (json['station'] as Map<String, dynamic>?)?['name'] as String?,
        notes: json['notes'] as String?,
        modifiers: (json['modifiers'] as List<dynamic>?)
                ?.map((e) => ItemModifier.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  double get lineTotal =>
      (double.tryParse(unitPriceWithTax) ?? 0) * quantity;

  String get modifiersSummary {
    if (modifiers.isEmpty && (notes == null || notes!.isEmpty)) return '';
    final parts = <String>[];
    for (final m in modifiers) {
      if (m.action == 'remove') {
        parts.add('SIN ${m.ingredientName}');
      } else {
        final price = m.hasCharge ? ' (+\$${m.extraPrice!.toStringAsFixed(2)})' : '';
        parts.add('EXTRA ${m.ingredientName}$price');
      }
    }
    if (notes != null && notes!.isNotEmpty) parts.add(notes!);
    return parts.join(' · ');
  }

  double get extrasTotal => modifiers
      .where((m) => m.hasCharge)
      .fold(0.0, (sum, m) => sum + m.extraPrice! * quantity);

  double get lineTotalWithExtras => lineTotal + extrasTotal;
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.version,
    required this.items,
    this.tableId,
    this.tableLabel,
    this.total,
    this.createdAt,
    this.customerId,
    this.customerName,
  });

  final String id;
  final String status; // open | in_kitchen | ready | closed
  final int version;
  final List<OrderItemModel> items;
  final String? tableId;
  final String? tableLabel;
  final String? total;
  final DateTime? createdAt;
  final String? customerId;
  final String? customerName;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final table = json['table'] as Map<String, dynamic>?;
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as String,
      status: json['status'] as String,
      version: json['version'] as int? ?? 0,
      tableId: json['tableId'] as String?,
      tableLabel: table?['label'] as String?,
      total: json['total']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get displayName =>
      customerName ?? (tableLabel != null ? null : 'Sin nombre') ?? '';

  double get computedTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotalWithExtras);
}
