import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/models.dart';
import 'tracking_screen.dart';

class SearchingDelivererScreen extends StatefulWidget {
  final String pickupAddress;
  final String deliveryAddress;
  final String packageDescription;
  final PackageSize packageSize;
  final double? estimatedWeight;

  const SearchingDelivererScreen({
    super.key,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.packageDescription,
    required this.packageSize,
    this.estimatedWeight,
  });

  @override
  State<SearchingDelivererScreen> createState() => _SearchingDelivererScreenState();
}

class _SearchingDelivererScreenState extends State<SearchingDelivererScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Auto-redirect after 4 seconds
    _redirectTimer = Timer(const Duration(seconds: 4), _navigateToTracking);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _navigateToTracking() {
    if (!mounted) return;

    // Generate unique delivery ID
    final deliveryId = 'del_${DateTime.now().millisecondsSinceEpoch}';

    // Replace current screen with tracking screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TrackingScreen(deliveryId: deliveryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Deliverer Icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSizes.spacingXxl),

              // Loading Indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Title
              Text(
                'Recherche d\'un livreur en cours...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingMd),

              // Subtitle
              Text(
                'Nous cherchons le meilleur livreur pour vous',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingXxl),

              // Info Cards
              _buildInfoCard(
                icon: Icons.speed,
                text: 'Recherche des livreurs disponibles à proximité',
              ),

              const SizedBox(height: AppSizes.spacingMd),

              _buildInfoCard(
                icon: Icons.star,
                text: 'Sélection du meilleur livreur selon vos critères',
              ),

              const Spacer(),

              // Bottom text
              Text(
                'Cela ne prendra que quelques secondes...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSizes.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: AppSizes.iconSizeMd,
            ),
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
