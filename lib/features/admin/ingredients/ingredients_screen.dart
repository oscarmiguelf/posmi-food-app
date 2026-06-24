import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import 'ingredients_repository.dart';

final _ingredientsProvider =
    AsyncNotifierProvider<_IngredientsNotifier, List<IngredientModel>>(
        _IngredientsNotifier.new);

class _IngredientsNotifier
    extends AsyncNotifier<List<IngredientModel>> {
  @override
  Future<List<IngredientModel>> build() =>
      ref.read(ingredientsRepositoryProvider).getAll();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(ingredientsRepositoryProvider).getAll());
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(ingredientsRepositoryProvider).create(body);
    await reload();
  }

  Future<void> adjust(String id, double delta, String reason) async {
    await ref
        .read(ingredientsRepositoryProvider)
        .adjust(id: id, delta: delta, reason: reason);
    await reload();
  }
}

class IngredientsScreen extends ConsumerWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_ingredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(_ingredientsProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo ingrediente'),
        onPressed: () => _showCreateDialog(context, ref),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
                child: Text('Sin ingredientes. Crea el primero.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: items.length,
            separatorBuilder: (context, _) => const SizedBox(height: 2),
            itemBuilder: (_, i) => _IngredientCard(
              ingredient: items[i],
              onAdjust: () =>
                  _showAdjustDialog(context, ref, items[i]),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _CreateIngredientDialog(
        onSave: (body) =>
            ref.read(_ingredientsProvider.notifier).create(body),
      ),
    );
  }

  void _showAdjustDialog(
      BuildContext context, WidgetRef ref, IngredientModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => _AdjustDialog(
        ingredient: item,
        onSave: (delta, reason) =>
            ref.read(_ingredientsProvider.notifier).adjust(
                  item.id,
                  delta,
                  reason,
                ),
      ),
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({
    required this.ingredient,
    required this.onAdjust,
  });

  final IngredientModel ingredient;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final isLow = ingredient.isLowStock;
    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isLow
                ? AppColors.danger.withAlpha(20)
                : AppColors.success.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: isLow ? AppColors.danger : AppColors.success,
          ),
        ),
        title: Text(ingredient.name),
        subtitle: Text(
          'Stock: ${ingredient.stockQuantity} ${ingredient.unit}'
          '  ·  Mín: ${ingredient.minStock}  ·  \$${ingredient.unitCost}/u',
          style: AppTypography.bodySm.copyWith(
            color: isLow ? AppColors.danger : AppColors.textSecondary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLow)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('BAJO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Registrar ajuste',
              onPressed: onAdjust,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateIngredientDialog extends StatefulWidget {
  const _CreateIngredientDialog({required this.onSave});

  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_CreateIngredientDialog> createState() =>
      _CreateIngredientDialogState();
}

const _units = ['kilogramo', 'gramo', 'litro', 'mililitro', 'pieza'];

class _CreateIngredientDialogState
    extends State<_CreateIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cost = TextEditingController();
  final _minStock = TextEditingController();
  final _initialStock = TextEditingController();
  String _unit = _units.first;

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _minStock.dispose();
    _initialStock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo ingrediente'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration:
                          const InputDecoration(labelText: 'Unidad'),
                      items: _units
                          .map((u) => DropdownMenuItem(
                              value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _unit = v);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _cost,
                      decoration:
                          const InputDecoration(
                            labelText: 'Costo/unidad',
                            prefixText: '\$ ',
                          ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Número válido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minStock,
                      decoration:
                          const InputDecoration(labelText: 'Stock mínimo'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Número válido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _initialStock,
                      decoration:
                          const InputDecoration(labelText: 'Stock inicial'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Número válido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              'name': _name.text.trim(),
              'unit': _unit,
              'unitCost': double.parse(_cost.text.trim()),
              'minStock': double.parse(_minStock.text.trim()),
              'stockQuantity': double.parse(_initialStock.text.trim()),
            });
            Navigator.pop(context);
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _AdjustDialog extends StatefulWidget {
  const _AdjustDialog({
    required this.ingredient,
    required this.onSave,
  });

  final IngredientModel ingredient;
  final void Function(double delta, String reason) onSave;

  @override
  State<_AdjustDialog> createState() => _AdjustDialogState();
}

class _AdjustDialogState extends State<_AdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  String _reason = 'adjustment';
  bool _isAdd = true;

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajuste — ${widget.ingredient.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock actual: ${widget.ingredient.stockQuantity} ${widget.ingredient.unit}',
              style:
                  AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Entrada'),
                  selected: _isAdd,
                  selectedColor: AppColors.success.withAlpha(60),
                  onSelected: (_) => setState(() => _isAdd = true),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: const Text('Merma / Salida'),
                  selected: !_isAdd,
                  selectedColor: AppColors.danger.withAlpha(60),
                  onSelected: (_) => setState(() => _isAdd = false),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _qty,
              decoration: InputDecoration(
                  labelText: 'Cantidad (${widget.ingredient.unit})'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Número inválido' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Razón'),
              items: const [
                DropdownMenuItem(
                    value: 'adjustment', child: Text('Ajuste manual')),
                DropdownMenuItem(value: 'waste', child: Text('Merma')),
              ],
              onChanged: (v) => setState(() => _reason = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final qty = double.parse(_qty.text);
            final delta = _isAdd ? qty : -qty;
            widget.onSave(delta, _reason);
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
