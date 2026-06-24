import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/menu_item_model.dart';
import '../../core/models/order_model.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';
import '../menu/menu_repository.dart';
import 'order_notifier.dart';
import 'orders_repository.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({
    super.key,
    this.tableId,
    this.tableLabel,
    this.orderId,
    this.initialCustomerName,
  });

  final String? tableId;
  final String? tableLabel;
  final String? orderId;
  final String? initialCustomerName;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrder());
  }

  @override
  void didUpdateWidget(OrderScreen old) {
    super.didUpdateWidget(old);
    if (old.tableId != widget.tableId || old.orderId != widget.orderId) {
      _loadOrder();
    }
  }

  void _loadOrder() async {
    final notifier = ref.read(orderNotifierProvider.notifier);
    notifier.reset();
    if (widget.initialCustomerName != null &&
        widget.initialCustomerName!.isNotEmpty) {
      notifier.setCustomerName(widget.initialCustomerName);
    }
    if (widget.orderId != null) {
      await notifier.loadOrder(widget.orderId!);
    } else if (widget.tableId != null) {
      await notifier.findOpenOrderForTable(widget.tableId!);
    }
  }

  Future<void> _sendOrder(List<MenuItemModel> menuItems) async {
    final order = await ref.read(orderNotifierProvider.notifier).submitCart(
          tableId: widget.tableId,
          menuItems: menuItems,
        );
    if (order != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Productos ordenados'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showCustomizeDialog(
      BuildContext context, WidgetRef ref, MenuItemModel item) {
    final notesCtrl = TextEditingController();
    final modifiers = <ItemModifier>[];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(item.name),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Modificadores',
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _ModifierInput(
                    onAdd: (name, action, price) {
                      setDialogState(() {
                        modifiers.add(ItemModifier(
                          ingredientName: name,
                          action: action,
                          extraPrice: price,
                        ));
                      });
                    },
                  ),
                  if (modifiers.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: modifiers.asMap().entries.map((e) {
                        final m = e.value;
                        final priceTag = m.hasCharge
                            ? ' +\$${m.extraPrice!.toStringAsFixed(2)}'
                            : '';
                        final label = m.action == 'remove'
                            ? 'SIN ${m.ingredientName}'
                            : 'EXTRA ${m.ingredientName}$priceTag';
                        return Chip(
                          label: Text(label,
                              style: const TextStyle(fontSize: 12)),
                          deleteIcon:
                              const Icon(Icons.close, size: 14),
                          onDeleted: () => setDialogState(
                              () => modifiers.removeAt(e.key)),
                          backgroundColor: m.action == 'remove'
                              ? AppColors.danger.withAlpha(20)
                              : AppColors.success.withAlpha(20),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nota para cocina',
                      hintText: 'Bien cocido, sin picante...',
                    ),
                    maxLines: 2,
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
                ref.read(orderNotifierProvider.notifier).addToCart(
                      item,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      modifiers:
                          modifiers.isEmpty ? null : List.from(modifiers),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(orderNotifierProvider);
    final menuAsync = ref.watch(menuItemsProvider);

    final label = widget.tableLabel ?? 'Orden';

    final readyItems = cart.order?.items.where((i) => i.isReady && !i.isFullyDelivered).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Tomar orden — $label'),
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

          return Column(
            children: [
              if (readyItems.isNotEmpty)
                _ReadyItemsBanner(
                  items: readyItems,
                  onDeliverItem: (item) async {
                    await ref.read(ordersRepositoryProvider).updateItemStatus(
                          orderId: cart.order!.id,
                          itemId: item.id,
                          itemStatus: 'delivered',
                        );
                    ref
                        .read(orderNotifierProvider.notifier)
                        .loadOrder(cart.order!.id);
                  },
                ),
              Expanded(
                child: Row(
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
                        onCustomize: (item) =>
                            _showCustomizeDialog(context, ref, item),
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
    required this.onCustomize,
  });

  final List<MenuItemModel> items;
  final CartState cart;
  final void Function(MenuItemModel) onAdd;
  final void Function(MenuItemModel) onCustomize;

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
        return _MenuItemCard(
          item: item,
          qty: qty,
          onTap: () => onAdd(item),
          onLongPress: () => onCustomize(item),
        );
      },
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.qty,
    required this.onTap,
    required this.onLongPress,
  });

  final MenuItemModel item;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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

class _OrderPanel extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final existingItems = cart.order?.items ?? [];
    final menuMap = {for (final m in allItems) m.id: m};

    double cartTotal = 0;
    for (final item in cart.items) {
      final price = menuMap[item.menuItemId]?.price ?? 0;
      final extrasPrice = item.modifiers
          .where((m) => m.action == 'add' && m.extraPrice != null && m.extraPrice! > 0)
          .fold(0.0, (s, m) => s + m.extraPrice!);
      cartTotal += (price + extrasPrice) * item.quantity;
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
          if (cart.order == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Nombre del cliente (opcional)',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                ),
                onChanged: (v) => ref
                    .read(orderNotifierProvider.notifier)
                    .setCustomerName(v.trim().isEmpty ? null : v.trim()),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                // Already submitted items
                ...existingItems.map(
                  (item) {
                    final parts = <String>[];
                    if (item.modifiersSummary.isNotEmpty) {
                      parts.add(item.modifiersSummary);
                    }
                    if (item.progressLabel.isNotEmpty) {
                      parts.add(item.progressLabel);
                    }
                    return _OrderLine(
                      name: item.menuItemName,
                      qty: item.quantity,
                      price: item.lineTotalWithExtras,
                      isSent: true,
                      onRemove: null,
                      subtitle: parts.isNotEmpty ? parts.join(' · ') : null,
                      statusIcon: switch (item.itemStatus) {
                        'ready' => const Icon(Icons.dinner_dining,
                            color: AppColors.success, size: 16),
                        'delivered' => const Icon(Icons.check_circle,
                            color: AppColors.textDisabled, size: 16),
                        'in_kitchen' => const Icon(Icons.local_fire_department,
                            color: AppColors.warning, size: 16),
                        _ => null,
                      },
                    );
                  },
                ),
                // Pending cart items
                ...cart.items.map((cartItem) {
                  final menuItem = menuMap[cartItem.menuItemId];
                  if (menuItem == null) return const SizedBox.shrink();
                  return _OrderLine(
                    name: menuItem.name,
                    qty: cartItem.quantity,
                    price: menuItem.price * cartItem.quantity,
                    isSent: false,
                    subtitle: cartItem.modifiers.isNotEmpty || (cartItem.notes != null && cartItem.notes!.isNotEmpty)
                        ? [
                            ...cartItem.modifiers.map((m) =>
                                m.action == 'remove' ? 'SIN ${m.ingredientName}' : 'EXTRA ${m.ingredientName}'),
                            if (cartItem.notes != null && cartItem.notes!.isNotEmpty) cartItem.notes!,
                          ].join(' · ')
                        : null,
                    onRemove: () => onRemove(cartItem.menuItemId),
                  );
                }),
                if (existingItems.isEmpty && cart.items.isEmpty)
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
              label: const Text('Ordenar'),
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
    this.subtitle,
    this.statusIcon,
  });

  final String name;
  final int qty;
  final double price;
  final bool isSent;
  final VoidCallback? onRemove;
  final String? subtitle;
  final Widget? statusIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyMd.copyWith(
                    color: isSent ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (statusIcon != null) ...[
            statusIcon!,
            const SizedBox(width: 4),
          ],
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

class _ModifierInput extends StatefulWidget {
  const _ModifierInput({required this.onAdd});
  final void Function(String name, String action, double? price) onAdd;

  @override
  State<_ModifierInput> createState() => _ModifierInputState();
}

class _ModifierInputState extends State<_ModifierInput> {
  final _ctrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _action = 'remove';

  @override
  void dispose() {
    _ctrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'remove', label: Text('SIN')),
                ButtonSegment(value: 'add', label: Text('EXTRA')),
              ],
              selected: {_action},
              onSelectionChanged: (s) =>
                  setState(() => _action = s.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Ingrediente',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle,
                  color: AppColors.primary),
              onPressed: _submit,
            ),
          ],
        ),
        if (_action == 'add') ...[
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                prefixText: '\$ ',
                hintText: '0.00 = sin cargo',
                labelText: 'Cargo extra',
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final price = _action == 'add'
        ? double.tryParse(_priceCtrl.text.trim())
        : null;
    widget.onAdd(text, _action, price != null && price > 0 ? price : null);
    _ctrl.clear();
    _priceCtrl.clear();
  }
}

class _ReadyItemsBanner extends StatelessWidget {
  const _ReadyItemsBanner({
    required this.items,
    required this.onDeliverItem,
  });
  final List<OrderItemModel> items;
  final void Function(OrderItemModel) onDeliverItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: AppColors.success.withAlpha(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${items.length} platillo${items.length > 1 ? 's' : ''} listo${items.length > 1 ? 's' : ''} para entregar',
                style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: items
                .map((item) => ActionChip(
                      avatar: const Icon(Icons.check_circle,
                          color: AppColors.success, size: 16),
                      label: Text(
                        '${item.menuItemName}'
                        '${item.pendingDelivery < item.quantity ? ' (${item.pendingDelivery})' : ''}',
                      ),
                      onPressed: () => onDeliverItem(item),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
