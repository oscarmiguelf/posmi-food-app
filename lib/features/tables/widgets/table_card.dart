import 'package:flutter/material.dart';
import '../../../core/models/table_model.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_typography.dart';

class TableCard extends StatelessWidget {
  const TableCard({
    super.key,
    required this.table,
    required this.onTap,
  });

  final TableModel table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: table.statusColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.label,
              style: AppTypography.headingMd.copyWith(
                color: table.statusTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: table.statusTextColor.withAlpha(200),
                ),
                const SizedBox(width: 4),
                Text(
                  '${table.capacity}',
                  style: AppTypography.caption.copyWith(
                    color: table.statusTextColor.withAlpha(200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                table.statusLabel,
                style: AppTypography.caption.copyWith(
                  color: table.statusTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
