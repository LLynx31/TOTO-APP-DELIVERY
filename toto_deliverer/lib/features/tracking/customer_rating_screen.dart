import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/simulation_service.dart';
import '../../core/utils/delivery_utils.dart';
import '../../shared/models/delivery_model.dart';
import '../../shared/widgets/widgets.dart';

/// Écran permettant au client de noter la livraison
/// Affiché après DeliverySuccessScreen
class CustomerRatingScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const CustomerRatingScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<CustomerRatingScreen> createState() => _CustomerRatingScreenState();
}

class _CustomerRatingScreenState extends State<CustomerRatingScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    // En mode simulation, pré-remplir avec la note mockée
    if (SimulationService().isSimulationMode) {
      final simulatedRating = SimulationService().getSimulatedRating(widget.delivery.id);
      if (simulatedRating != null) {
        _rating = simulatedRating['rating'] as int;
        _commentController.text = simulatedRating['comment'] as String;
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    // Validation: au moins une étoile
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note avant de valider'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (SimulationService().isSimulationMode) {
        // Mode simulation
        await SimulationService().simulateSubmitRating(
          widget.delivery.id,
          _rating,
          _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        );
      } else {
        // TODO: Envoyer la note à l'API
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre évaluation !'),
          backgroundColor: AppColors.success,
        ),
      );

      // Retourner au Dashboard (root)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de la note: $e'),
          backgroundColor: AppColors.error,
        ),
      );

      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _skipRating() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passer l\'évaluation ?'),
        content: const Text(
          'Êtes-vous sûr de vouloir passer l\'évaluation ? Votre avis nous aide à améliorer notre service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Passer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Retourner au Dashboard sans noter
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Évaluer la livraison'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _skipRating,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône de succès
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingLg),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingLg),

            // Titre
            Text(
              'Livraison terminée !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingSm),

            // Description
            Text(
              'Comment évaluez-vous cette livraison ?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Info livraison
            CustomCard(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DeliveryUtils.formatDeliveryIdWithPrefix(widget.delivery.id),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingSm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text(
                          'Livrée',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacingSm),
                  const Divider(),
                  const SizedBox(height: AppSizes.spacingSm),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      Expanded(
                        child: Text(
                          widget.delivery.deliveryAddress.address,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Rating stars
            Text(
              'Votre note',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            Center(
              child: RatingStars(
                rating: _rating,
                size: 48,
                onRatingChanged: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Commentaire optionnel
            Text(
              'Commentaire (optionnel)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Bouton valider
            CustomButton(
              text: _isSubmitting ? 'Envoi en cours...' : 'Valider',
              onPressed: _isSubmitting ? null : _submitRating,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Bouton passer
            TextButton(
              onPressed: _isSubmitting ? null : _skipRating,
              child: const Text('Passer'),
            ),
          ],
        ),
      ),
    );
  }
}
