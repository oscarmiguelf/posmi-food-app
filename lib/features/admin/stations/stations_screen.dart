import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class StationModel {
  const StationModel({required this.id, required this.name});
  final String id;
  final String name;
  factory StationModel.fromJson(Map<String, dynamic> json) =>
      StationModel(id: json['id'] as String, name: json['name'] as String);
}

class _StationsRepository {
  _StationsRepository(this._dio);
  final Dio _dio;

  Future<List<StationModel>> getAll() async {
    final res = await _dio.get<Map<String, dynamic>>('/stations');
    final data = res.data!['data'] as List<dynamic>;
    return data
        .map((e) => StationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StationModel> create(String name) async {
    final res = await _dio
        .post<Map<String, dynamic>>('/stations', data: {'name': name});
    return StationModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<StationModel> update(String id, String name) async {
    final res = await _dio.patch<Map<String, dynamic>>(
        '/stations/$id', data: {'name': name, 'version': 0});
    return StationModel.fromJson(
        res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/stations/$id');
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _stationsRepoProvider = Provider<_StationsRepository>(
    (ref) => _StationsRepository(ref.watch(dioProvider)));

final _stationsProvider =
    AsyncNotifierProvider<_StationsNotifier, List<StationModel>>(
        _StationsNotifier.new);

class _StationsNotifier extends AsyncNotifier<List<StationModel>> {
  @override
  Future<List<StationModel>> build() =>
      ref.read(_stationsRepoProvider).getAll();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(_stationsRepoProvider).getAll());
  }

  Future<void> create(String name) async {
    await ref.read(_stationsRepoProvider).create(name);
    await reload();
  }

  Future<void> editStation(String id, String name) async {
    await ref.read(_stationsRepoProvider).update(id, name);
    await reload();
  }

  Future<void> deleteStation(String id) async {
    await ref.read(_stationsRepoProvider).delete(id);
    await reload();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StationsScreen extends ConsumerWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_stationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones de preparación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(_stationsProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva estación'),
        onPressed: () => _showForm(context, ref, null),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stations) {
          if (stations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.kitchen_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Sin estaciones. Crea la primera.'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ejemplos: Cocina, Barra, Postres, Grill…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 80),
            itemCount: stations.length,
            separatorBuilder: (context, _) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) {
              final s = stations[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.kitchen_outlined,
                        color: AppColors.primaryContent, size: 20),
                  ),
                  title: Text(s.name,
                      style: Theme.of(context).textTheme.bodyLarge),
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
      BuildContext context, WidgetRef ref, StationModel? existing) {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            Text(existing == null ? 'Nueva estación' : 'Editar estación'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 320,
            child: TextFormField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Cocina, Barra, Postres…',
              ),
              autofocus: true,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Requerido' : null,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              if (existing == null) {
                ref
                    .read(_stationsProvider.notifier)
                    .create(ctrl.text.trim());
              } else {
                ref
                    .read(_stationsProvider.notifier)
                    .editStation(existing.id, ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text(existing == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, StationModel station) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar estación'),
        content: Text('¿Eliminar "${station.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(_stationsProvider.notifier)
                  .deleteStation(station.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
