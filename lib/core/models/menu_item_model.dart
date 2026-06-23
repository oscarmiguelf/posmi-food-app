class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.salePriceWithTax,
    required this.isAvailable,
  });

  final String id;
  final String name;
  final String category;
  final String salePriceWithTax;
  final bool isAvailable;

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        salePriceWithTax: json['salePriceWithTax']?.toString() ?? '0.00',
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  double get price => double.tryParse(salePriceWithTax) ?? 0;
}
