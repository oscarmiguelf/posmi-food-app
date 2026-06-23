import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

class _SupplierModel {
  const _SupplierModel({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
  });
  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;

  factory _SupplierModel.fromJson(Map<String, dynamic> json) =>
      _SupplierModel(
        id: json['id'] as String,
        name: json['name'] as String,
        contactName: json['contactName'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );
}

class _SuppliersRepo {
  _SuppliersRepo(this._dio);
  final Dio _dio;

  Future<List<_SupplierModel>> getAll() async {
    final res = await _dio.get<Map<String, dynamic>>('/suppliers');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => _SupplierModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(Map<String, dynamic> body) async {
    await _dio.post<void>('/suppliers', data: body);
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _dio.patch<void>('/suppliers/$id', data: body);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/suppliers/$id');
  }
}

final _repoProvider =
    Provider<_SuppliersRepo>((ref) => _SuppliersRepo(ref.watch(dioProvider)));

final _suppliersProvider =
    AsyncNotifierProvider<_SuppliersNotifier, List<_SupplierModel>>(
        _SuppliersNotifier.new);

class _SuppliersNotifier extends AsyncNotifier<List<_SupplierModel>> {
  @override
  Future<List<_SupplierModel>> build() =>
      ref.read(_repoProvider).getAll();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => ref.read(_repoProvider).getAll());
  }

  Future<void> create(Map<String, dynamic> body) async {
    await ref.read(_repoProvider).create(body);
    await reload();
  }

  Future<void> edit(String id, Map<String, dynamic> body) async {
    await ref.read(_repoProvider).update(id, body);
    await reload();
  }

  Future<void> remove(String id) async {
    await ref.read(_repoProvider).delete(id);
    await reload();
  }
}

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(_suppliersProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo proveedor'),
        onPressed: () => _showForm(context, ref, null),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 64, color: AppColors.textDisabled),
                  SizedBox(height: AppSpacing.md),
                  Text('Sin proveedores. Crea el primero.'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: suppliers.length,
            separatorBuilder: (context, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final s = suppliers[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.local_shipping_outlined,
                        color: AppColors.primaryContent, size: 20),
                  ),
                  title: Text(s.name),
                  subtitle: Text([
                    if (s.contactName != null) s.contactName,
                    if (s.phone != null) s.phone,
                    if (s.email != null) s.email,
                  ].join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () => _showForm(context, ref, s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: () =>
                            _confirmDelete(context, ref, s),
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
      BuildContext context, WidgetRef ref, _SupplierModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contactCtrl =
        TextEditingController(text: existing?.contactName ?? '');
    final phoneCtrl =
        TextEditingController(text: existing?.phone ?? '');
    final emailCtrl =
        TextEditingController(text: existing?.email ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(existing == null ? 'Nuevo proveedor' : 'Editar proveedor'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre / Razón social'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Contacto (opcional)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email (opcional)'),
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
                if (contactCtrl.text.trim().isNotEmpty)
                  'contactName': contactCtrl.text.trim(),
                if (phoneCtrl.text.trim().isNotEmpty)
                  'phone': phoneCtrl.text.trim(),
                if (emailCtrl.text.trim().isNotEmpty)
                  'email': emailCtrl.text.trim(),
              };
              if (existing == null) {
                ref.read(_suppliersProvider.notifier).create(body);
              } else {
                body['version'] = '0';
                ref
                    .read(_suppliersProvider.notifier)
                    .edit(existing.id, body);
              }
              Navigator.pop(ctx);
            },
            child: Text(existing == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, _SupplierModel supplier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text('¿Eliminar "${supplier.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(_suppliersProvider.notifier)
                  .remove(supplier.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
