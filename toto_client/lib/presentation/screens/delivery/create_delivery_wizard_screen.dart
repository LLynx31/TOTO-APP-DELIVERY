import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/repositories/delivery_repository.dart';
import '../../providers/create_delivery_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../widgets/custom_button.dart';
import 'steps/pickup_location_step.dart';
import 'steps/delivery_location_step.dart';
import 'steps/package_details_step.dart';
import 'steps/review_step.dart';

/// Wizard de création de livraison en 4 étapes
class CreateDeliveryWizardScreen extends ConsumerStatefulWidget {
  const CreateDeliveryWizardScreen({super.key});

  @override
  ConsumerState<CreateDeliveryWizardScreen> createState() =>
      _CreateDeliveryWizardScreenState();
}

class _CreateDeliveryWizardScreenState
    extends ConsumerState<CreateDeliveryWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNext() {
    final state = ref.watch(createDeliveryProvider);
    switch (_currentStep) {
      case 0:
        return state.canProceedToStep2;
      case 1:
        return state.canProceedToStep3;
      case 2:
        return state.canProceedToStep4;
      case 3:
        return true; // Review step
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(createDeliveryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            _currentStep == 0 ? Icons.close : Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (_currentStep == 0) {
              // Confirmer l'annulation
              _showCancelDialog();
            } else {
              _previousStep();
            }
          },
        ),
        title: Text(
          AppStrings.createDelivery,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Indicateur de progression
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingLg,
                  vertical: AppSizes.paddingMd,
                ),
                child: Row(
                  children: List.generate(4, (index) {
                    final isActive = index <= _currentStep;
                    final isCompleted = index < _currentStep;

                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusFull),
                              ),
                            ),
                          ),
                          if (index < 3)
                            Container(
                              width: 8,
                              height: 4,
                              color: Colors.transparent,
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              // Titre de l'étape
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSizes.paddingLg,
                  right: AppSizes.paddingLg,
                  bottom: AppSizes.paddingMd,
                ),
                child: Row(
                  children: [
                    Text(
                      '${AppStrings.step} ${_currentStep + 1} ${AppStrings.stepOf} 4',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(width: AppSizes.spacingSm),
                    Text(
                      _getStepTitle(_currentStep),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Contenu des étapes
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                PickupLocationStep(),
                DeliveryLocationStep(),
                PackageDetailsStep(),
                ReviewStep(),
              ],
            ),
          ),

          // Boutons de navigation
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: CustomButton(
                        text: AppStrings.back,
                        isOutlined: true,
                        onPressed: _previousStep,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: AppSizes.spacingMd),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 2,
                    child: CustomButton(
                      text: _currentStep == 3
                          ? AppStrings.payAndOrder
                          : AppStrings.next,
                      onPressed: _canProceedToNext()
                          ? (_currentStep == 3 ? _submitDelivery : _nextStep)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return AppStrings.pickupLocation;
      case 1:
        return AppStrings.deliveryLocation;
      case 2:
        return AppStrings.packageDetails;
      case 3:
        return AppStrings.reviewAndConfirm;
      default:
        return '';
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la création'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ? Toutes les informations seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              ref.read(createDeliveryProvider.notifier).reset();
              Navigator.pop(context);
              context.pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDelivery() async {
    final state = ref.read(createDeliveryProvider);

    // Vérifier que toutes les données sont présentes
    if (!state.canProceedToStep4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir toutes les informations requises'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Créer les paramètres de livraison
      final params = CreateDeliveryParams(
        pickupAddress: state.pickupAddress!,
        pickupLatitude: state.pickupLocation!.latitude,
        pickupLongitude: state.pickupLocation!.longitude,
        deliveryAddress: state.deliveryAddress!,
        deliveryLatitude: state.deliveryLocation!.latitude,
        deliveryLongitude: state.deliveryLocation!.longitude,
        deliveryPhone: state.receiverPhone!,
        receiverName: state.receiverName!,
        packageDescription: state.packageDescription,
        packageWeight: state.packageWeight,
        specialInstructions: state.specialInstructions,
      );

      // Appeler l'API pour créer la livraison
      final delivery = await ref.read(deliveriesProvider.notifier).createDelivery(params);

      // Fermer le dialog de chargement
      if (mounted) Navigator.of(context).pop();

      if (delivery != null) {
        // Réinitialiser le wizard
        ref.read(createDeliveryProvider.notifier).reset();

        // Recharger les livraisons pour inclure la nouvelle
        ref.read(deliveriesProvider.notifier).loadDeliveries();

        // Afficher un message de succès et retourner à l'accueil
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Livraison créée ! En attente d\'un livreur...'),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  context.push('/delivery/${delivery.id}/tracking');
                },
              ),
            ),
          );

          // Retourner à l'accueil
          context.go('/home');
        }
      } else {
        // Afficher une erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la création de la livraison'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement en cas d'erreur
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
