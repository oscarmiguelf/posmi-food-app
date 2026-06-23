import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/menu_item_model.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../menu/menu_repository.dart';
import 'order_notifier.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({
    super.key,
    this.tableId,
    this.tableLabel,
    this.orderId,
  });

  final String? tableId;
  final String? tableLabel;
  final String? orderId;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(orderNotifierProvider.notifier);
      notifier.reset();
      if (widget.orderId != null) {
        await notifier.loadOrder(widget.orderId!);
      } else if (widget.tableId != null) {
        await notifier.findOpenOrderForTable(widget.tableId!);
      }
    });
  }

  Future<void> _sendOrder(List<MenuItemModel> menuItems) async {
    final order = await ref.read(orderNotifierProvider.notifier).submitCart(
          tableId: widget.tableId,
          menuItems: menuItems,
        );
    if (order != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orden enviada a cocina'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(orderNotifierProvider);
    final menuAsync = ref.watch(menuItemsProvider);

    final label = widget.tableLabel ?? 'Orden';

    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          if (cart.order != null)
            TextButton.icon(
              icon: const Icon(Icons.payment, color: AppColors.primaryContent),
              label: const Text(
                'Cobrar',
                style: TextStyle(color: AppColors.primaryContent),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
              onPressed: () {
                final order = cart.order!;
                context.push(
                  '/orders/${order.id}/payment'
                  '?total=${order.computedTotal.toStringAsFixed(2)}'
                  '&version=${order.version}',
                );
              },
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final categories = items.map((i) => i.category).toSet().toList()
            ..sort();
          if (_selectedCategory.isEmpty && categories.isNotEmpty) {
            _selectedCategory = categories.first;
          }
          final filtered = items
              .where((i) =>
                  i.category == _selectedCategory && i.isAvailable)
              .toList();

          return Row(
            children: [
              // LEFT: Category rail + menu grid
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _CategoryBar(
                      categories: categories,
                      selected: _selectedCategory,
                      onSelect: (c) => setState(() => _selectedCategory = c),
                    ),
                    Expanded(
                      child: _MenuGrid(
                        items: filtered,
                        cart: cart,
                        onAdd: (item) => ref
                            .read(orderNotifierProvider.notifier)
                            .addToCart(item),
                      ),
                    ),
                  ],
                ),
              ),
              // RIGHT: Order summary
              SizedBox(
                width: 300,
                child: _OrderPanel(
                  cart: cart,
                  allItems: items,
                  onRemove: (id) => ref
                      .read(orderNotifierProvider.notifier)
                      .removeFromCart(id),
                  onSend: () => _sendOrder(items),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: categories.length,
        separatorBuilder: (context, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selected;
          return Center(
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => onSelect(cat),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primaryContent
                    : AppColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.items,
    required this.cart,
    required this.onAdd,
  });

  final List<MenuItemModel> items;
  final CartState cart;
  final void Function(MenuItemModel) onAdd;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final qty = cart.quantityOf(item.id);
        return _MenuItemCard(item: item, qty: qty, onTap: () => onAdd(item));
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.qty,
    required this.onTap,
  });

  final MenuItemModel item;
  final int qty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(
                color:
                    qty > 0 ? AppColors.primary : AppColors.border,
                width: qty > 0 ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      item.name,
                      style: AppTypography.bodyMd
                          .copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: AppTypography.label
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          if (qty > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$qty',
                    style: const TextStyle(
                      color: AppColors.primaryContent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderPanel extends StatelessWidget {
  const _OrderPanel({
    required this.cart,
    required this.allItems,
    required this.onRemove,
    required this.onSend,
  });

  final CartState cart;
  final List<MenuItemModel> allItems;
  final void Function(String) onRemove;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final existingItems = cart.order?.items ?? [];
    final cartEntries = cart.cartItems.entries.toList();
    final menuMap = {for (final m in allItems) m.id: m};

    double cartTotal = 0;
    for (final e in cartEntries) {
      final price = menuMap[e.key]?.price ?? 0;
      cartTotal += price * e.value;
    }
    final existingTotal = cart.order?.computedTotal ?? 0;
    final grandTotal = existingTotal + cartTotal;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Orden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                // Already submitted items
                ...existingItems.map(
                  (item) => _OrderLine(
                    name: item.menuItemName,
                    qty: item.quantity,
                    price: item.lineTotal,
                    isSent: true,
                    onRemove: null,
                  ),
                ),
                // Pending cart items
                ...cartEntries.map((e) {
                  final menuItem = menuMap[e.key];
                  if (menuItem == null) return const SizedBox.shrink();
                  return _OrderLine(
                    name: menuItem.name,
                    qty: e.value,
                    price: menuItem.price * e.value,
                    isSent: false,
                    onRemove: () => onRemove(e.key),
                  );
                }),
                if (existingItems.isEmpty && cartEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Toca un producto para agregar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '\$${grandTotal.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          if (cart.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                cart.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ElevatedButton.icon(
              onPressed:
                  (cart.isEmpty || cart.isSubmitting) ? null : onSend,
              icon: cart.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryContent,
                      ),
                    )
                  : const Icon(Icons.send),
              label: const Text('Enviar a cocina'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({
    required this.name,
    required this.qty,
    required this.price,
    required this.isSent,
    required this.onRemove,
  });

  final String name;
  final int qty;
  final double price;
  final bool isSent;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              '$qty×',
              style: AppTypography.label
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMd.copyWith(
                color: isSent ? AppColors.textSecondary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: AppTypography.label,
          ),
          if (!isSent && onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: AppColors.danger,
              ),
            ),
          ] else ...[
            const SizedBox(width: 22),
          ],
        ],
      ),
    );
  }
}
