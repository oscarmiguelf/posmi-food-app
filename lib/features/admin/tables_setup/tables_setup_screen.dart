import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import 'tables_setup_repository.dart';

final _tablesSetupProvider = AsyncNotifierProvider<_TablesSetupNotifier,
    List<TableSetupModel>>(_TablesSetupNotifier.new);

class _TablesSetupNotifier
    extends AsyncNotifier<List<TableSetupModel>> {
  @override
  Future<List<TableSetupModel>> build() =>
      ref.read(tablesSetupRepositoryProvider).getAll();

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(tablesSetupRepositoryProvider).getAll());
  }

  Future<void> create(String label, int capacity) async {
    await ref.read(tablesSetupRepositoryProvider).create(label, capacity);
    await reload();
  }

  Future<void> editTable(String id, String label, int capacity) async {
    await ref
        .read(tablesSetupRepositoryProvider)
        .update(id, label, capacity);
    await reload();
  }

  Future<void> deleteTable(String id) async {
    await ref.read(tablesSetupRepositoryProvider).delete(id);
    await reload();
  }
}

class TablesSetupScreen extends ConsumerWidget {
  const TablesSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_tablesSetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(_tablesSetupProvider.notifier).reload(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva mesa'),
        onPressed: () => _showForm(context, ref, null),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tables) {
          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_restaurant_outlined,
                      size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Sin mesas. Crea la primera.'),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.4,
              ),
              itemCount: tables.length,
              itemBuilder: (_, i) => _TableSetupCard(
                table: tables[i],
                onEdit: () => _showForm(context, ref, tables[i]),
                onDelete: () =>
                    _confirmDelete(context, ref, tables[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showForm(
      BuildContext context, WidgetRef ref, TableSetupModel? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => _TableFormDialog(
        existing: existing,
        onSave: (label, capacity) {
          if (existing == null) {
            ref
                .read(_tablesSetupProvider.notifier)
                .create(label, capacity);
          } else {
            ref
                .read(_tablesSetupProvider.notifier)
                .editTable(existing.id, label, capacity);
          }
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, TableSetupModel table) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar mesa'),
        content: Text(
            '¿Eliminar "${table.label}"? Solo es posible si no tiene órdenes activas.'),
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
                  .read(_tablesSetupProvider.notifier)
                  .deleteTable(table.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _TableSetupCard extends StatelessWidget {
  const _TableSetupCard({
    required this.table,
    required this.onEdit,
    required this.onDelete,
  });

  final TableSetupModel table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_restaurant_outlined,
                    color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    table.label,
                    style: Theme.of(context).textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${table.capacity} personas',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppColors.primary),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.danger),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableFormDialog extends StatefulWidget {
  const _TableFormDialog({required this.existing, required this.onSave});

  final TableSetupModel? existing;
  final void Function(String label, int capacity) onSave;

  @override
  State<_TableFormDialog> createState() => _TableFormDialogState();
}

class _TableFormDialogState extends State<_TableFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _capacity;

  @override
  void initState() {
    super.initState();
    _label =
        TextEditingController(text: widget.existing?.label ?? '');
    _capacity = TextEditingController(
        text: widget.existing?.capacity.toString() ?? '4');
  }

  @override
  void dispose() {
    _label.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Nueva mesa' : 'Editar mesa'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Nombre / número',
                  hintText: 'Mesa 1, Terraza 3…',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _capacity,
                decoration: const InputDecoration(
                    labelText: 'Capacidad (personas)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Número válido ≥ 1';
                  return null;
                },
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
            widget.onSave(
              _label.text.trim(),
              int.parse(_capacity.text.trim()),
            );
            Navigator.pop(context);
          },
          child: Text(isNew ? 'Crear' : 'Guardar'),
        ),
      ],
    );
  }
}
