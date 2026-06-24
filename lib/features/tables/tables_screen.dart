import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/table_model.dart';
import '../../core/providers/api_client_provider.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import 'tables_provider.dart';
import 'widgets/table_card.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  void _onTableTap(BuildContext context, WidgetRef ref, TableModel table) {
    if (table.status == 'free') {
      _showAssignDialog(context, ref, table);
    } else {
      context.go(
        '/orders/new?tableId=${table.id}&tableLabel=${Uri.encodeComponent(table.label)}',
      );
    }
  }

  void _showAssignDialog(
      BuildContext context, WidgetRef ref, TableModel table) {
    final nameCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Asignar ${table.label}'),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nombre del cliente (opcional)',
              hintText: 'Juan, Mesa 3, etc.',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onSubmitted: (_) {
              Navigator.pop(ctx);
              _assignAndNavigate(context, ref, table, nameCtrl.text.trim());
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _assignAndNavigate(context, ref, table, nameCtrl.text.trim());
            },
            child: const Text('Asignar mesa'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignAndNavigate(BuildContext context, WidgetRef ref,
      TableModel table, String customerName) async {
    final dio = ref.read(dioProvider);
    try {
      // Refresh tables to get current version
      await ref.read(tablesProvider.notifier).refresh();
      final tables = ref.read(tablesProvider).value ?? [];
      final fresh = tables.where((t) => t.id == table.id).firstOrNull;
      final version = fresh?.version ?? table.version;
      await dio.patch<void>('/tables/${table.id}/status',
          data: {'status': 'occupied', 'version': version});
    } catch (_) {}
    ref.read(tablesProvider.notifier).refresh();
    if (context.mounted) {
      final encodedLabel = Uri.encodeComponent(table.label);
      final encodedName = Uri.encodeComponent(customerName);
      context.go(
        '/orders/new?tableId=${table.id}&tableLabel=$encodedLabel'
        '${customerName.isNotEmpty ? '&customerName=$encodedName' : ''}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tv_outlined),
            tooltip: 'KDS — Pantalla cocina',
            onPressed: () => context.push('/kds'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => ref.read(tablesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: tablesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: e.toString(),
          onRetry: () => ref.read(tablesProvider.notifier).refresh(),
        ),
        data: (tables) => _TablesGrid(
          tables: tables,
          onTap: (t) => _onTableTap(context, ref, t),
        ),
      ),
      bottomNavigationBar: _Legend(),
    );
  }
}

class _TablesGrid extends StatelessWidget {
  const _TablesGrid({required this.tables, required this.onTap});

  final List<TableModel> tables;
  final void Function(TableModel) onTap;

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return const Center(
        child: Text('No hay mesas configuradas.'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1,
        ),
        itemCount: tables.length,
        itemBuilder: (_, i) =>
            TableCard(table: tables[i], onTap: () => onTap(tables[i])),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Error al cargar mesas',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _LegendItem(color: AppColors.tableFree, label: 'Libre'),
          SizedBox(width: AppSpacing.lg),
          _LegendItem(color: AppColors.tableOccupied, label: 'Ocupada'),
          SizedBox(width: AppSpacing.lg),
          _LegendItem(
              color: AppColors.tableBillRequested, label: 'Pidió cuenta'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
