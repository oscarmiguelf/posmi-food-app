import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';
import 'dashboard_repository.dart';

final _dashboardProvider = FutureProvider<DashboardData>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});

final _mxn = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_dashboardProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Err(e.toString(),
            onRetry: () => ref.invalidate(_dashboardProvider)),
        data: (d) => _DashboardBody(data: d),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hoy — ${DateFormat('EEEE d MMMM', 'es_MX').format(DateTime.now())}',
              style: AppTypography.headingSm
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          // KPI cards
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.8,
              children: [
                _KpiCard(
                  icon: Icons.attach_money,
                  label: 'Ventas del día',
                  value: _mxn.format(
                      double.tryParse(data.dailySales) ?? 0),
                  color: AppColors.success,
                ),
                _KpiCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Órdenes activas',
                  value: '${data.openOrders}',
                  color: AppColors.info,
                ),
                _KpiCard(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Cajas abiertas',
                  value: '${data.openCashSessions}',
                  color: AppColors.primary,
                ),
                _KpiCard(
                  icon: Icons.warning_amber_outlined,
                  label: 'Alertas de stock',
                  value: '${data.lowStockAlerts.length}',
                  color: data.lowStockAlerts.isEmpty
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          // Top items
          if (data.topItems.isNotEmpty) ...[
            Text('Top productos del día',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.topItems.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = data.topItems[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: AppColors.primaryContent,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item['name']?.toString() ?? '—'),
                    trailing: Text(
                      '${item['totalSold'] ?? 0} uds.',
                      style: AppTypography.label
                          .copyWith(color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          // Low stock alerts
          if (data.lowStockAlerts.isNotEmpty) ...[
            Text('Alertas de stock bajo',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.lowStockAlerts.length,
                separatorBuilder: (context, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final alert = data.lowStockAlerts[i];
                  return ListTile(
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: AppColors.danger),
                    title: Text(alert['name']?.toString() ?? '—'),
                    subtitle: Text(
                        'Stock: ${alert['stockQuantity']} ${alert['unit'] ?? ''} '
                        '(mín. ${alert['minStock']})'),
                    trailing: const Icon(Icons.warning_amber,
                        color: AppColors.danger),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(label,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Text(value,
                style: AppTypography.displayMd.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _Err extends StatelessWidget {
  const _Err(this.msg, {required this.onRetry});

  final String msg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
}
