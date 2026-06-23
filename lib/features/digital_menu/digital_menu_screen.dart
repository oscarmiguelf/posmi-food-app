import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/api_client_provider.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';
import '../../design_system/tokens/app_typography.dart';

class DigitalMenuScreen extends ConsumerWidget {
  const DigitalMenuScreen({super.key, required this.branchId});
  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dio = ref.watch(dioProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchMenu(dio, branchId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        final data = snap.data!;
        final branch = data['branch'] as Map<String, dynamic>;
        final categories = data['categories'] as List<dynamic>;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    branch['companyName'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1A237E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant_menu,
                              color: Colors.white70, size: 40),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            branch['name'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          if (branch['address'] != null)
                            Text(
                              branch['address'] as String,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Category navigation chips
              SliverToBoxAdapter(
                child: Container(
                  height: 52,
                  color: AppColors.surface,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 8),
                    itemCount: categories.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final cat =
                          categories[i] as Map<String, dynamic>;
                      return ActionChip(
                        label: Text(cat['name'] as String),
                        onPressed: () {},
                      );
                    },
                  ),
                ),
              ),

              // Categories + items
              ...categories.map((rawCat) {
                final cat = rawCat as Map<String, dynamic>;
                final items = cat['items'] as List<dynamic>;
                return SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _CategoryHeader(
                        name: cat['name'] as String,
                        description: cat['description'] as String?,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) => _MenuItemCard(
                          item: items[i] as Map<String, dynamic>,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.lg),
                    ),
                  ],
                );
              }),

              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchMenu(
      Dio dio, String branchId) async {
    final res = await dio
        .get<Map<String, dynamic>>('/digital-menu/$branchId');
    return res.data!['data'] as Map<String, dynamic>;
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.name, this.description});
  final String name;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          if (description != null && description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(description!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ),
          const Divider(),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? '';
    final description = item['description'] as String?;
    final price = double.tryParse(
            item['salePriceWithTax']?.toString() ?? '0') ??
        0;
    final typeName =
        (item['type'] as Map<String, dynamic>?)?['name'] as String?;
    final extras = item['extras'] as List<dynamic>? ?? [];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            style: AppTypography.headingSm
                                .copyWith(fontSize: 16)),
                      ),
                      if (typeName != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(typeName,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ],
                  ),
                  if (description != null &&
                      description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (extras.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: extras.map((e) {
                        final ext = e as Map<String, dynamic>;
                        final extPrice = double.tryParse(
                                ext['priceWithTax']?.toString() ??
                                    '0') ??
                            0;
                        return Text(
                          '+${ext['ingredientName']}'
                          '${extPrice > 0 ? ' \$${extPrice.toStringAsFixed(0)}' : ''}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.success),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: AppTypography.headingMd
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
