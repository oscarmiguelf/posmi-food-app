import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/table_model.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import 'tables_provider.dart';
import 'widgets/table_card.dart';

class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  void _onTableTap(BuildContext context, TableModel table) {
    if (table.status == 'free') {
      context.push(
        '/orders/new?tableId=${table.id}&tableLabel=${Uri.encodeComponent(table.label)}',
      );
    } else {
      // occupied or bill_requested — open existing order
      context.push(
        '/orders/new?tableId=${table.id}&tableLabel=${Uri.encodeComponent(table.label)}',
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
          onTap: (t) => _onTableTap(context, t),
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
