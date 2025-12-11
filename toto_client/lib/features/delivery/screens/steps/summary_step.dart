import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

class SummaryStep extends StatelessWidget {
  final AddressModel pickupAddress;
  final AddressModel deliveryAddress;
  final PackageModel package;
  final DeliveryMode mode;
  final bool hasInsurance;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const SummaryStep({
    super.key,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.package,
    required this.mode,
    required this.hasInsurance,
    required this.onConfirm,
    required this.onBack,
  });

  double _calculatePrice() {
    double basePrice = 1000;

    switch (package.size) {
      case PackageSize.small:
        basePrice *= 0.8;
        break;
      case PackageSize.medium:
        basePrice *= 1.0;
        break;
      case PackageSize.large:
        basePrice *= 1.5;
        break;
    }

    basePrice += (package.weight * 200);

    if (mode == DeliveryMode.express) {
      basePrice *= 1.5;
    }

    if (hasInsurance) {
      basePrice += 500;
    }

    return basePrice;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.secondary.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 80,
                  color: AppColors.textWhite.withValues(alpha: 0.9),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            Text(
              AppStrings.deliverySummary,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Package Photo
            if (package.photoUrl != null) ...[
              Text(
                'Photo du colis:',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSizes.spacingSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: Image.network(
                  package.photoUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSizes.spacingLg),
            ],

            // Addresses
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    context,
                    label: '${AppStrings.from}:',
                    value: pickupAddress.address,
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  _buildInfoRow(
                    context,
                    label: '${AppStrings.to}:',
                    value: deliveryAddress.address,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Package Details
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Colis:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  _buildInfoRow(
                    context,
                    label: 'Taille:',
                    value: '${package.size.displayName}, ${package.weight}kg',
                  ),
                  if (package.description != null &&
                      package.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.spacingSm),
                    _buildInfoRow(
                      context,
                      label: 'Description:',
                      value: package.description!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Delivery Mode
            CustomCard(
              child: _buildInfoRow(
                context,
                label: 'Mode:',
                value: mode.displayName,
                trailing: Text(
                  mode.duration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Price Breakdown
            CustomCard(
              color: AppColors.backgroundGrey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.estimatedPrice,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  if (hasInsurance) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Assurance',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '500 ${AppStrings.currency}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingSm),
                  ],
                  const Divider(),
                  const SizedBox(height: AppSizes.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${_calculatePrice().toStringAsFixed(0)} ${AppStrings.currency}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Payment info
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.info.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: AppSizes.iconSizeMd,
                  ),
                  const SizedBox(width: AppSizes.spacingMd),
                  Expanded(
                    child: Text(
                      AppStrings.paymentAtDelivery,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: AppStrings.previous,
                    onPressed: onBack,
                    variant: ButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Expanded(
                  child: CustomButton(
                    text: AppStrings.confirmDelivery,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: AppSizes.iconSizeSm,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizes.spacingSm),
        ],
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
              const SizedBox(height: AppSizes.spacingXs),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
