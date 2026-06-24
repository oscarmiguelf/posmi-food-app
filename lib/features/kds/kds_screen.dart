import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/current_user.dart';
import '../../core/models/order_model.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../orders/orders_repository.dart';
import 'kds_provider.dart';

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(kdsOrdersProvider);
    final user = ref.watch(currentUserProvider);
    final manualFilter = ref.watch(kdsStationFilterProvider);

    // Kitchen users auto-filter to their assigned station
    final stationFilter =
        manualFilter ?? (user?.isKitchen == true ? user?.stationName : null);

    final title = stationFilter != null
        ? 'KDS — $stationFilter'
        : 'KDS — Todas las estaciones';

    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.primaryContent,
        title: Text(title),
        actions: [
          PopupMenuButton<String?>(
            tooltip: 'Filtrar por estación',
            icon: const Icon(Icons.filter_list),
            onSelected: (v) =>
                ref.read(kdsStationFilterProvider.notifier).state = v,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todas las estaciones'),
              ),
              const PopupMenuDivider(),
              // Station options will be populated dynamically from orders
              ...?ordersAsync.value
                  ?.expand((o) => o.items)
                  .map((i) => i.stationName)
                  .whereType<String>()
                  .toSet()
                  .map(
                    (s) => PopupMenuItem(
                      value: s,
                      child: Text(s),
                    ),
                  ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(kdsOrdersProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContent),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.primaryContent),
          ),
        ),
        data: (orders) {
          final filtered = stationFilter == null
              ? orders
              : orders
                  .where((o) => o.items.any(
                        (i) => i.stationName == stationFilter,
                      ))
                  .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 64,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sin órdenes pendientes',
                    style: AppTypography.headingLg
                        .copyWith(color: AppColors.primaryContent),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _KdsCard(
              order: filtered[i],
              stationFilter: stationFilter,
            ),
          );
        },
      ),
    );
  }
}

class _KdsCard extends ConsumerWidget {
  const _KdsCard({required this.order, this.stationFilter});

  final OrderModel order;
  final String? stationFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = stationFilter == null
        ? order.items
        : order.items
            .where((i) => i.stationName == stationFilter)
            .toList();

    final age = _orderAge(order);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(
          color: age > 15
              ? AppColors.danger
              : age > 8
                  ? AppColors.warning
                  : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.borderRadius - 2),
                topRight: Radius.circular(AppSpacing.borderRadius - 2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    order.tableLabel ?? 'Para llevar',
                    style: AppTypography.headingSm
                        .copyWith(color: AppColors.primaryContent),
                  ),
                ),
                _AgeBadge(minutes: age),
              ],
            ),
          ),
          // Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: items.length,
              separatorBuilder: (context, _) =>
                  const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            color: AppColors.primaryContent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.menuItemName,
                              style: AppTypography.bodyLg,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.modifiersSummary.isNotEmpty)
                              Text(
                                item.modifiersSummary,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Mark items as ready
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                ...items.where((i) => i.itemStatus != 'ready' && i.itemStatus != 'delivered').map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: Text('${item.menuItemName} lista',
                            overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () =>
                            _markItemReady(context, ref, item),
                      ),
                    ),
                  ),
                ),
                if (items.every((i) => i.itemStatus == 'ready' || i.itemStatus == 'delivered'))
                  const Text('Todo listo',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _orderAge(OrderModel order) {
    if (order.createdAt == null) return 0;
    return DateTime.now().difference(order.createdAt!).inMinutes;
  }

  Future<void> _markItemReady(
      BuildContext context, WidgetRef ref, OrderItemModel item) async {
    try {
      await ref.read(ordersRepositoryProvider).updateItemStatus(
            orderId: order.id,
            itemId: item.id,
            itemStatus: 'ready',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.menuItemName} lista'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
    await ref.read(kdsOrdersProvider.notifier).refresh();
  }
}

class _AgeBadge extends StatelessWidget {
  const _AgeBadge({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final color = minutes > 15
        ? AppColors.danger
        : minutes > 8
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${minutes}m',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
