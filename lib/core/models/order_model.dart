class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPriceWithTax,
    this.stationName,
  });

  final String id;
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final String unitPriceWithTax;
  final String? stationName;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] as String,
        menuItemId: json['menuItemId'] as String,
        menuItemName: (json['menuItem'] as Map<String, dynamic>?)?['name'] as String? ??
            json['menuItemName'] as String? ??
            '',
        quantity: json['quantity'] as int,
        unitPriceWithTax: json['unitPriceWithTax']?.toString() ?? '0.00',
        stationName: (json['station'] as Map<String, dynamic>?)?['name'] as String?,
      );

  double get lineTotal =>
      (double.tryParse(unitPriceWithTax) ?? 0) * quantity;
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
  });

  final String id;
  final String status; // open | in_kitchen | ready | closed
  final int version;
  final List<OrderItemModel> items;
  final String? tableId;
  final String? tableLabel;
  final String? total;

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
      items: rawItems
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get computedTotal =>
      items.fold(0.0, (sum, item) => sum + item.lineTotal);
}
