import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import 'reports_repository.dart';

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
final _dateFormat = DateFormat('yyyy-MM-dd');

final _dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month, 1),
    end: now,
  );
});

final _salesProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final range = ref.watch(_dateRangeProvider);
  return ref.watch(reportsRepositoryProvider).getSales(
        from: _dateFormat.format(range.start),
        to: _dateFormat.format(range.end),
      );
});

final _summaryProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final range = ref.watch(_dateRangeProvider);
  return ref.watch(reportsRepositoryProvider).getPeriodSummary(
        from: _dateFormat.format(range.start),
        to: _dateFormat.format(range.end),
      );
});

final _profitabilityProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(reportsRepositoryProvider).getProfitability();
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Ventas'),
            Tab(text: 'Período'),
            Tab(text: 'Rentabilidad'),
          ]),
        ),
        body: TabBarView(children: [
          _SalesTab(),
          _PeriodTab(),
          _ProfitabilityTab(),
        ]),
      ),
    );
  }
}

class _DateRangeBar extends ConsumerWidget {
  const _DateRangeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(_dateRangeProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.date_range, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${_dateFormat.format(range.start)}  →  ${_dateFormat.format(range.end)}',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                initialDateRange: range,
              );
              if (picked != null) {
                ref.read(_dateRangeProvider.notifier).state = picked;
              }
            },
            child: const Text('Cambiar rango'),
          ),
        ],
      ),
    );
  }
}

class _SalesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_salesProvider);
    return Column(
      children: [
        const _DateRangeBar(),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (data) {
              final categories =
                  (data['byCategory'] as List<dynamic>?) ?? [];
              final total =
                  double.tryParse(data['total']?.toString() ?? '0') ?? 0;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryTile(
                        label: 'Total vendido', value: _mxn.format(total)),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Por categoría',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(2),
                        },
                        children: [
                          _tableHeader(
                              ['Categoría', 'Uds.', 'Total']),
                          ...categories.map((c) {
                            final cat = c as Map<String, dynamic>;
                            return TableRow(children: [
                              _tableCell(cat['category']?.toString() ?? '—'),
                              _tableCell('${cat['units'] ?? 0}'),
                              _tableCell(_mxn.format(
                                  double.tryParse(
                                          cat['total']?.toString() ?? '0') ??
                                      0)),
                            ]);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PeriodTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_summaryProvider);
    return Column(
      children: [
        const _DateRangeBar(),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (data) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryTile(
                      label: 'Ventas netas',
                      value: _mxn.format(
                          double.tryParse(data['totalSales']?.toString() ?? '0') ?? 0),
                    ),
                    _SummaryTile(
                      label: 'COGS (Costo mercancía)',
                      value: _mxn.format(
                          double.tryParse(data['totalCogs']?.toString() ?? '0') ?? 0),
                    ),
                    _SummaryTile(
                      label: 'Margen bruto',
                      value: _mxn.format(
                          double.tryParse(data['grossProfit']?.toString() ?? '0') ?? 0),
                    ),
                    _SummaryTile(
                      label: 'Margen %',
                      value: '${data['grossMarginPct'] ?? 0}%',
                      highlight: true,
                    ),
                    _SummaryTile(
                      label: 'IVA recaudado',
                      value: _mxn.format(
                          double.tryParse(data['totalTax']?.toString() ?? '0') ?? 0),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfitabilityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_profitabilityProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (data) {
        final items = (data['items'] as List<dynamic>?) ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Card(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                _tableHeader(
                    ['Producto', 'Precio venta', 'Costo receta', 'Food cost %']),
                ...items.map((i) {
                  final item = i as Map<String, dynamic>;
                  final pct =
                      double.tryParse(item['foodCostPct']?.toString() ?? '0') ??
                          0;
                  return TableRow(children: [
                    _tableCell(item['name']?.toString() ?? '—'),
                    _tableCell(_mxn.format(
                        double.tryParse(item['salePrice']?.toString() ?? '0') ??
                            0)),
                    _tableCell(_mxn.format(
                        double.tryParse(item['recipeCost']?.toString() ?? '0') ??
                            0)),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: pct > 35 ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]);
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withAlpha(20) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(
          color: highlight ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyLg),
          Text(
            value,
            style: AppTypography.headingMd.copyWith(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

TableRow _tableHeader(List<String> cols) => TableRow(
      decoration: const BoxDecoration(color: AppColors.surfaceVariant),
      children: cols
          .map((c) => Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(c,
                    style: AppTypography.label
                        .copyWith(color: AppColors.textSecondary)),
              ))
          .toList(),
    );

Widget _tableCell(String text) => Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(text, style: AppTypography.bodyMd),
    );
