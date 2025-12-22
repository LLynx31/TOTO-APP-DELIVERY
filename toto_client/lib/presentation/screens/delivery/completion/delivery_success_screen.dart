import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/delivery.dart';
import '../../../../core/di/injection.dart' as di;
import '../../../../data/repositories/auth_repository_impl.dart';
import '../../../widgets/celebration/confetti_widget.dart';
import '../../../widgets/celebration/animated_success_icon.dart';
import '../../../../core/router/route_names.dart';

/// Écran de félicitation après livraison réussie
class DeliverySuccessScreen extends ConsumerStatefulWidget {
  final String deliveryId;

  const DeliverySuccessScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  ConsumerState<DeliverySuccessScreen> createState() =>
      _DeliverySuccessScreenState();
}

class _DeliverySuccessScreenState extends ConsumerState<DeliverySuccessScreen> {
  Delivery? _delivery;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveryDetails();
  }

  Future<void> _loadDeliveryDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final getDeliveryUsecase = ref.read(di.getDeliveryUsecaseProvider);
    final result = await getDeliveryUsecase(widget.deliveryId);

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        setState(() {
          _delivery = data;
          _isLoading = false;
        });

      case Failure(:final message):
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
    }
  }

  String _formatDuration(DateTime? createdAt, DateTime? deliveredAt) {
    if (createdAt == null || deliveredAt == null) return '---';

    final duration = deliveredAt.difference(createdAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }
    return '$minutes min';
  }

  String _formatDistance(double? distance) {
    if (distance == null) return '---';
    return '${distance.toStringAsFixed(1)} km';
  }

  String _formatPrice(double? price) {
    if (price == null) return '---';
    return '${price.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Confetti animation
          const Positioned.fill(
            child: CelebrationConfetti(),
          ),

          // Contenu principal
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: AppSizes.spacingMd),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSizes.spacingLg),
                            ElevatedButton(
                              onPressed: () => context.go(RoutePaths.home),
                              child: const Text('Retour à l\'accueil'),
                            ),
                          ],
                        ),
                      )
                    : _buildSuccessContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.spacingXxl),

          // Icône de succès animée
          const AnimatedSuccessIcon(),

          const SizedBox(height: AppSizes.spacingLg),

          // Message principal
          const Text(
            'Livraison réussie ! 🎉',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Sous-titre
          Text(
            'Votre colis a été livré avec succès',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingXxl),

          // Résumé de la livraison
          _buildDeliverySummary(),

          const SizedBox(height: AppSizes.spacingXxl),

          // Boutons d'action
          _buildActionButtons(),

          const SizedBox(height: AppSizes.spacingLg),

          // Message de remerciement
          Text(
            'Merci d\'avoir utilisé TOTO',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySummary() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Résumé de la livraison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.access_time,
                label: 'Durée',
                value: _formatDuration(
                  _delivery?.timestamps.createdAt,
                  _delivery?.timestamps.deliveredAt,
                ),
              ),
              _buildSummaryItem(
                icon: Icons.straighten,
                label: 'Distance',
                value: _formatDistance(_delivery?.distanceKm),
              ),
              _buildSummaryItem(
                icon: Icons.payments,
                label: 'Prix',
                value: _formatPrice(_delivery?.price),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSizes.spacingSm),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSizes.spacingXs),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Bouton principal : Voir les détails
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              context.go('/delivery/${widget.deliveryId}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            child: const Text(
              'Voir les détails',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.spacingMd),

        // Bouton secondaire : Nouvelle livraison
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              context.go(RoutePaths.home);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
            child: const Text(
              AppStrings.newDelivery,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
