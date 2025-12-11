import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/delivery_model.dart';

class PackageInfoCard extends StatefulWidget {
  final PackageModel package;
  final double price;

  const PackageInfoCard({
    super.key,
    required this.package,
    required this.price,
  });

  @override
  State<PackageInfoCard> createState() => _PackageInfoCardState();
}

class _PackageInfoCardState extends State<PackageInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.packageDetails,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Summary (always visible)
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  label: AppStrings.size,
                  value: widget.package.size.displayName,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: _buildInfoItem(
                  context: context,
                  icon: Icons.scale_outlined,
                  label: AppStrings.weight,
                  value: '${widget.package.weight} kg',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingSm),

          _buildInfoItem(
            context: context,
            icon: Icons.attach_money,
            label: AppStrings.proposedPrice,
            value: '${widget.price.toInt()} FCFA',
            isHighlight: true,
          ),

          // Expandable content
          if (_isExpanded) ...[
            const SizedBox(height: AppSizes.spacingMd),
            const Divider(),
            const SizedBox(height: AppSizes.spacingMd),

            // Description
            if (widget.package.description != null &&
                widget.package.description!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.packageDescription,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.package.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMd),
            ] else ...[
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  Text(
                    AppStrings.noDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacingMd),
            ],

            // Package photo
            if (widget.package.photoUrl != null &&
                widget.package.photoUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    widget.package.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surfaceGrey,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: AppSizes.spacingSm),
                              Text(
                                'Image non disponible',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.surfaceGrey,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isHighlight ? AppColors.primary : AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
