import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

final _decimalFilter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

class RecipeScreen extends ConsumerStatefulWidget {
  const RecipeScreen({
    super.key,
    required this.menuItemId,
    required this.menuItemName,
  });

  final String menuItemId;
  final String menuItemName;

  @override
  ConsumerState<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends ConsumerState<RecipeScreen> {
  List<_RecipeRow> _rows = [];
  List<Map<String, dynamic>> _extras = [];
  List<Map<String, dynamic>> _ingredients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    try {
      final results = await Future.wait([
        dio.get<Map<String, dynamic>>(
            '/menu-items/${widget.menuItemId}/recipe'),
        dio.get<Map<String, dynamic>>(
            '/menu-items/${widget.menuItemId}/extras'),
        dio.get<Map<String, dynamic>>('/ingredients'),
      ]);

      final recipeData =
          results[0].data!['data'] as Map<String, dynamic>;
      final extrasData = results[1].data!['data'] as List<dynamic>;
      final ingredientsData =
          results[2].data!['data'] as List<dynamic>;

      final recipeItems =
          (recipeData['items'] as List<dynamic>?) ?? [];

      setState(() {
        _rows = recipeItems
            .map((e) => _RecipeRow.fromJson(e as Map<String, dynamic>))
            .toList();
        _extras = extrasData
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _ingredients = ingredientsData
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRecipe() async {
    if (_rows.isEmpty) return;
    final dio = ref.read(dioProvider);
    await dio.put<void>(
      '/menu-items/${widget.menuItemId}/recipe',
      data: {
        'items': _rows
            .map((r) => {
                  'ingredientId': r.ingredientId,
                  'quantity': r.quantity,
                  'unit': r.unit,
                })
            .toList(),
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receta guardada'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _addExtra() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo extra'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ingrediente extra'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Precio con IVA',
                    prefixText: '\$ ',
                    hintText: '0 = sin cargo',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [_decimalFilter],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final dio = ref.read(dioProvider);
      await dio.post<void>(
        '/menu-items/${widget.menuItemId}/extras',
        data: {
          'ingredientName': nameCtrl.text.trim(),
          'priceWithTax': priceCtrl.text.trim(),
        },
      );
      _load();
    }
  }

  Future<void> _deleteExtra(String extraId) async {
    final dio = ref.read(dioProvider);
    await dio
        .delete<void>('/menu-items/${widget.menuItemId}/extras/$extraId');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receta — ${widget.menuItemName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // === RECIPE SECTION ===
                Row(
                  children: [
                    const Icon(Icons.receipt_long,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Ingredientes de la receta',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Guardar receta'),
                      onPressed: _saveRecipe,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ..._rows.asMap().entries.map((e) {
                  final i = e.key;
                  final row = e.value;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: row.ingredientId,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Ingrediente',
                              ),
                              items: _ingredients
                                  .map((ing) =>
                                      DropdownMenuItem<String>(
                                        value: ing['id'] as String,
                                        child: Text(
                                            ing['name'] as String? ??
                                                ''),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                final ing = _ingredients
                                    .firstWhere((x) => x['id'] == v);
                                setState(() {
                                  _rows[i] = row.copyWith(
                                    ingredientId: v,
                                    unit: ing['unit'] as String? ??
                                        row.unit,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: row.quantity,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'Cant.',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [_decimalFilter],
                              onChanged: (v) => _rows[i] =
                                  row.copyWith(quantity: v),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 80,
                            child: Text(row.unit,
                                style: AppTypography.caption),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: AppColors.danger, size: 20),
                            onPressed: () => setState(
                                () => _rows.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar ingrediente'),
                  onPressed: () {
                    if (_ingredients.isEmpty) return;
                    final first = _ingredients.first;
                    setState(() {
                      _rows.add(_RecipeRow(
                        ingredientId: first['id'] as String,
                        unit: first['unit'] as String? ?? 'kg',
                        quantity: '0',
                      ));
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),

                // === EXTRAS SECTION ===
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Extras disponibles',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nuevo extra'),
                      onPressed: _addExtra,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_extras.isEmpty)
                  const Text('Sin extras configurados',
                      style:
                          TextStyle(color: AppColors.textSecondary)),
                ..._extras.map((ext) {
                  final price = double.tryParse(
                          ext['priceWithTax']?.toString() ?? '0') ??
                      0;
                  return Card(
                    child: ListTile(
                      title:
                          Text(ext['ingredientName'] as String? ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            price > 0
                                ? '+\$${price.toStringAsFixed(2)}'
                                : 'Sin cargo',
                            style: AppTypography.label.copyWith(
                              color: price > 0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger, size: 20),
                            onPressed: () => _deleteExtra(
                                ext['id'] as String),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _RecipeRow {
  _RecipeRow({
    required this.ingredientId,
    required this.unit,
    required this.quantity,
  });

  final String ingredientId;
  final String unit;
  final String quantity;

  factory _RecipeRow.fromJson(Map<String, dynamic> json) => _RecipeRow(
        ingredientId: json['ingredientId'] as String,
        unit: json['unit'] as String? ?? 'kg',
        quantity: json['quantity']?.toString() ?? '0',
      );

  _RecipeRow copyWith({
    String? ingredientId,
    String? unit,
    String? quantity,
  }) =>
      _RecipeRow(
        ingredientId: ingredientId ?? this.ingredientId,
        unit: unit ?? this.unit,
        quantity: quantity ?? this.quantity,
      );
}
