import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

class _CategoryModel {
  const _CategoryModel({
    required this.id,
    required this.name,
    required this.displayOrder,
    required this.isVisible,
    this.description,
    this.itemCount = 0,
  });
  final String id;
  final String name;
  final int displayOrder;
  final bool isVisible;
  final String? description;
  final int itemCount;

  factory _CategoryModel.fromJson(Map<String, dynamic> json) =>
      _CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        displayOrder: json['displayOrder'] as int? ?? 0,
        isVisible: json['isVisible'] as bool? ?? true,
        description: json['description'] as String?,
        itemCount:
            (json['menuItems'] as List<dynamic>?)?.length ?? 0,
      );
}

class _CatRepo {
  _CatRepo(this._dio);
  final Dio _dio;

  Future<List<_CategoryModel>> list() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/menu-categories');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) =>
            _CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post<void>('/menu-categories', data: body);
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _dio.patch<void>('/menu-categories/$id', data: body);
  }

  Future<void> reorder(List<Map<String, dynamic>> items) async {
    await _dio
        .patch<void>('/menu-categories/reorder', data: {'items': items});
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/menu-categories/$id');
  }
}

final _repoProvider =
    Provider<_CatRepo>((ref) => _CatRepo(ref.watch(dioProvider)));

final _categoriesProvider =
    AsyncNotifierProvider<_CatNotifier, List<_CategoryModel>>(
        _CatNotifier.new);

class _CatNotifier extends AsyncNotifier<List<_CategoryModel>> {
  @override
  Future<List<_CategoryModel>> build() =>
      ref.read(_repoProvider).list();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => ref.read(_repoProvider).list());
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(_repoProvider).create(body);
    await reload();
  }

  Future<void> edit(String id, Map<String, dynamic> body) async {
    await ref.read(_repoProvider).update(id, body);
    await reload();
  }

  Future<void> reorder(List<_CategoryModel> newOrder) async {
    final items = newOrder.asMap().entries.map((e) => {
          'id': e.value.id,
          'displayOrder': e.key,
        }).toList();
    await ref.read(_repoProvider).reorder(items);
    await reload();
  }

  Future<void> remove(String id) async {
    await ref.read(_repoProvider).delete(id);
    await reload();
  }
}

class MenuCategoriesScreen extends ConsumerWidget {
  const MenuCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías del menú digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(_categoriesProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
        onPressed: () => _showForm(context, ref, null),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: AppColors.textDisabled),
                  SizedBox(height: AppSpacing.md),
                  Text('Sin categorías. Crea la primera.'),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ejemplos: Bebidas, Entradas, Plato fuerte, Postres…',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final list = List<_CategoryModel>.from(categories);
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(_categoriesProvider.notifier).reorder(list);
            },
            itemBuilder: (_, i) {
              final cat = categories[i];
              return Card(
                key: ValueKey(cat.id),
                child: ListTile(
                  leading: Icon(
                    cat.isVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: cat.isVisible
                        ? AppColors.success
                        : AppColors.textDisabled,
                  ),
                  title: Text(cat.name),
                  subtitle: Text(
                    '${cat.itemCount} platillos'
                    '${cat.description != null ? ' · ${cat.description}' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle,
                          color: AppColors.textDisabled),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () =>
                            _showForm(context, ref, cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: () =>
                            _confirmDelete(context, ref, cat),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showForm(
      BuildContext context, WidgetRef ref, _CategoryModel? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool isVisible = existing?.isVisible ?? true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? 'Nueva categoría'
              : 'Editar categoría'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Bebidas, Entradas, Lo nuevo…',
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SwitchListTile(
                    title: const Text('Visible en menú digital'),
                    value: isVisible,
                    onChanged: (v) =>
                        setDialogState(() => isVisible = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final body = {
                  'name': nameCtrl.text.trim(),
                  if (descCtrl.text.trim().isNotEmpty)
                    'description': descCtrl.text.trim(),
                  'isVisible': isVisible,
                };
                if (existing == null) {
                  ref
                      .read(_categoriesProvider.notifier)
                      .create(body);
                } else {
                  ref
                      .read(_categoriesProvider.notifier)
                      .edit(existing.id, body);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Crear' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, _CategoryModel cat) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar "${cat.name}"? Los platillos asignados '
          'quedarán sin categoría en el menú digital.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(_categoriesProvider.notifier)
                  .remove(cat.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
