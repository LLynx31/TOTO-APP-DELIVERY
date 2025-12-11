import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/delivery_model.dart';

enum CourseSortType {
  priceAsc,
  priceDesc,
  distance,
}

class CourseFilters extends StatelessWidget {
  final DeliveryMode? selectedMode;
  final CourseSortType? selectedSort;
  final Function(DeliveryMode?) onModeChanged;
  final Function(CourseSortType?) onSortChanged;

  const CourseFilters({
    super.key,
    required this.selectedMode,
    required this.selectedSort,
    required this.onModeChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                context: context,
                label: 'Tous',
                isSelected: selectedMode == null,
                onTap: () => onModeChanged(null),
                icon: Icons.all_inclusive,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildFilterChip(
                context: context,
                label: 'Standard',
                isSelected: selectedMode == DeliveryMode.standard,
                onTap: () => onModeChanged(DeliveryMode.standard),
                icon: Icons.schedule,
                color: AppColors.standard,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildFilterChip(
                context: context,
                label: 'Express',
                isSelected: selectedMode == DeliveryMode.express,
                onTap: () => onModeChanged(DeliveryMode.express),
                icon: Icons.bolt,
                color: AppColors.express,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.spacingSm),

        // Sort options
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(
                Icons.sort,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                'Trier:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildSortChip(
                context: context,
                label: 'Prix ↓',
                isSelected: selectedSort == CourseSortType.priceDesc,
                onTap: () => onSortChanged(
                  selectedSort == CourseSortType.priceDesc
                      ? null
                      : CourseSortType.priceDesc,
                ),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildSortChip(
                context: context,
                label: 'Prix ↑',
                isSelected: selectedSort == CourseSortType.priceAsc,
                onTap: () => onSortChanged(
                  selectedSort == CourseSortType.priceAsc
                      ? null
                      : CourseSortType.priceAsc,
                ),
              ),
              const SizedBox(width: AppSizes.spacingSm),
              _buildSortChip(
                context: context,
                label: 'Distance',
                isSelected: selectedSort == CourseSortType.distance,
                onTap: () => onSortChanged(
                  selectedSort == CourseSortType.distance
                      ? null
                      : CourseSortType.distance,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(
            color: chipColor,
            width: isSelected ? 0 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.textWhite : chipColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected ? AppColors.textWhite : chipColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
