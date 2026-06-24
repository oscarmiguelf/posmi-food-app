import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import 'menu_admin_repository.dart';

final _stationsForMenuProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/stations');
  return (res.data!['data'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList();
});

final _categoriesForMenuProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get<Map<String, dynamic>>('/menu-item-types');
  return (res.data!['data'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList();
});

final _menuAdminProvider =
    AsyncNotifierProvider<_MenuAdminNotifier, List<MenuItemModel>>(
        _MenuAdminNotifier.new);

class _MenuAdminNotifier
    extends AsyncNotifier<List<MenuItemModel>> {
  @override
  Future<List<MenuItemModel>> build() =>
      ref.read(menuAdminRepositoryProvider).getAll();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(menuAdminRepositoryProvider).getAll());
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(menuAdminRepositoryProvider).create(body);
    await reload();
  }

  Future<void> editItem(String id, Map<String, dynamic> body) async {
    await ref.read(menuAdminRepositoryProvider).update(id, body);
    await reload();
  }

  Future<void> deleteItem(String id) async {
    await ref.read(menuAdminRepositoryProvider).delete(id);
    await reload();
  }
}

class MenuAdminScreen extends ConsumerWidget {
  const MenuAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_menuAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(_menuAdminProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        onPressed: () => _showForm(context, ref, null),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Sin productos. Crea el primero.'));
          }
          // Group by category
          final byCategory = <String, List<MenuItemModel>>{};
          for (final item in items) {
            byCategory.putIfAbsent(item.category, () => []).add(item);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            children: byCategory.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    child: Text(entry.key,
                        style: AppTypography.headingSm
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  Card(
                    child: Column(
                      children: entry.value.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        return Column(
                          children: [
                            _MenuItemTile(
                              item: item,
                              onEdit: () =>
                                  _showForm(context, ref, item),
                              onDelete: () =>
                                  _confirmDelete(context, ref, item),
                              onToggle: (val) =>
                                  ref.read(_menuAdminProvider.notifier).editItem(
                                    item.id,
                                    {'isAvailable': val, 'version': 0},
                                  ),
                            ),
                            if (i < entry.value.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showForm(
      BuildContext context, WidgetRef ref, MenuItemModel? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => Consumer(
        builder: (ctx, dialogRef, _) {
          final stationsAsync = dialogRef.watch(_stationsForMenuProvider);
          final categoriesAsync =
              dialogRef.watch(_categoriesForMenuProvider);
          if (stationsAsync.isLoading || categoriesAsync.isLoading) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return _MenuItemDialog(
            existing: existing,
            stations: stationsAsync.value ?? [],
            categories: categoriesAsync.value ?? [],
            onSave: (body) async {
              final hasRecipe =
                  body.remove('_hasRecipe') as bool? ?? false;
              if (existing == null) {
                await ref.read(_menuAdminProvider.notifier).create(body);
                if (hasRecipe && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Producto creado. Configura la receta y extras'
                        ' desde el menú de edición del producto.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } else {
                ref
                    .read(_menuAdminProvider.notifier)
                    .editItem(existing.id, body);
              }
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, MenuItemModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${item.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ref.read(_menuAdminProvider.notifier).deleteItem(item.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final MenuItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: item.isAvailable,
            onChanged: onToggle,
            activeThumbColor: AppColors.success,
          ),
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete),
        ],
      ),
    );
  }
}

class _MenuItemDialog extends StatefulWidget {
  const _MenuItemDialog({
    required this.existing,
    required this.stations,
    required this.categories,
    required this.onSave,
  });

  final MenuItemModel? existing;
  final List<Map<String, dynamic>> stations;
  final List<Map<String, dynamic>> categories;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<_MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  String? _category;
  bool _available = true;
  String? _stationId;
  bool _hasRecipe = false;

  static final _decimalFilter =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _price = TextEditingController(
        text: widget.existing?.salePriceWithTax ?? '');
    _available = widget.existing?.isAvailable ?? true;
    if (widget.existing != null) {
      _category = widget.existing!.category;
    } else if (widget.categories.isNotEmpty) {
      _category = widget.categories.first['name'] as String;
    }
    if (widget.stations.length == 1) {
      _stationId = widget.stations.first['id'] as String;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Nuevo producto' : 'Editar producto'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration:
                      const InputDecoration(labelText: 'Nombre'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                  ),
                  hint: const Text('Selecciona categoría'),
                  items: widget.categories
                      .map((c) => DropdownMenuItem<String>(
                            value: c['name'] as String,
                            child: Text(c['name'] as String),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) =>
                      v == null ? 'Selecciona una categoría' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Precio con IVA',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [_decimalFilter],
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Precio válido > 0';
                    return null;
                  },
                ),
                if (isNew && widget.stations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _stationId,
                    decoration: const InputDecoration(
                      labelText: 'Estación de preparación',
                    ),
                    hint: const Text('Selecciona estación'),
                    items: widget.stations
                        .map((s) => DropdownMenuItem<String>(
                              value: s['id'] as String,
                              child: Text(s['name'] as String? ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _stationId = v),
                    validator: (v) =>
                        v == null ? 'Selecciona una estación' : null,
                  ),
                ],
                if (isNew) ...[
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tiene receta (ingredientes)'),
                    subtitle: Text(
                      _hasRecipe
                          ? 'Configurarás la receta después de crear'
                          : 'Producto sin desglose de ingredientes',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    value: _hasRecipe,
                    onChanged: (v) => setState(() => _hasRecipe = v),
                  ),
                ],
                if (!isNew) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Switch(
                        value: _available,
                        onChanged: (v) =>
                            setState(() => _available = v),
                        activeThumbColor: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('Disponible'),
                    ],
                  ),
                ],
              ],
            ),
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
            final body = <String, dynamic>{
              'name': _name.text.trim(),
              'category': _category!,
              'salePriceWithTax':
                  double.parse(_price.text.trim()),
            };
            if (isNew) {
              body['stationIds'] = [_stationId];
              body['_hasRecipe'] = _hasRecipe;
            } else {
              body['isAvailable'] = _available;
              body['version'] = 0;
            }
            widget.onSave(body);
            Navigator.pop(context);
          },
          child: Text(isNew ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
