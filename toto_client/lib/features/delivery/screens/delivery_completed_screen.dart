import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/widgets.dart';
import '../../home/screens/main_screen.dart';

class DeliveryCompletedScreen extends StatefulWidget {
  final String deliveryAddress;
  final String deliveryId;
  final String? delivererName;

  const DeliveryCompletedScreen({
    super.key,
    required this.deliveryAddress,
    required this.deliveryId,
    this.delivererName,
  });

  @override
  State<DeliveryCompletedScreen> createState() =>
      _DeliveryCompletedScreenState();
}

class _DeliveryCompletedScreenState extends State<DeliveryCompletedScreen> {
  void _showRatingDialog() {
    int rating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Évaluer le livreur'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.delivererName != null) ...[
                    Text(
                      widget.delivererName!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.spacingLg),
                  ],
                  Text(
                    'Comment évaluez-vous votre livreur ?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSizes.spacingLg),
                  CustomTextField(
                    label: 'Commentaire (optionnel)',
                    hint: 'Partagez votre expérience...',
                    controller: commentController,
                    maxLines: 4,
                    prefixIcon: const Icon(Icons.comment_outlined),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Dispose controller after dialog is closed
                  Future.microtask(() {
                    commentController.dispose();
                  });
                },
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (rating > 0) {
                    // TODO: Submit rating
                    Navigator.pop(context);
                    // Dispose controller after dialog is closed
                    Future.microtask(() {
                      commentController.dispose();
                    });
                    _returnToDashboard();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez donner une note'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _returnToDashboard() {
    // Navigate to main screen and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(), // Remove back button
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.spacingXxl),

            // Success Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textPrimary,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 70,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Title
            Text(
              'Livraison effectuée !',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // Success Message Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingLg),
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Text(
                'Votre colis a été remis avec succès à ${widget.deliveryAddress}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // Illustration Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.2),
                    AppColors.success.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Icon(
                Icons.delivery_dining,
                size: 80,
                color: AppColors.success,
              ),
            ),

            const SizedBox(height: AppSizes.spacingXxl),

            // Rate Deliverer Button
            CustomButton(
              text: 'Évaluer le livreur',
              onPressed: _showRatingDialog,
              icon: const Icon(
                Icons.star_outline,
                color: AppColors.textWhite,
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Return to Dashboard Button
            CustomButton(
              text: 'Retour au tableau de bord',
              onPressed: _returnToDashboard,
              variant: ButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }
}
