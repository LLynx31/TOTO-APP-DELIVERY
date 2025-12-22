import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../providers/create_delivery_provider.dart';

/// Step 3: Détails du colis
class PackageDetailsStep extends ConsumerStatefulWidget {
  const PackageDetailsStep({super.key});

  @override
  ConsumerState<PackageDetailsStep> createState() => _PackageDetailsStepState();
}

class _PackageDetailsStepState extends ConsumerState<PackageDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _packageDescriptionController = TextEditingController();
  final _packageWeightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing values from provider if any
    final state = ref.read(createDeliveryProvider);
    _receiverNameController.text = state.receiverName ?? '';
    _receiverPhoneController.text = state.receiverPhone ?? '';
    _packageDescriptionController.text = state.packageDescription ?? '';
    _packageWeightController.text = state.packageWeight?.toString() ?? '';
    _specialInstructionsController.text = state.specialInstructions ?? '';

    // Add listeners to update provider on change
    _receiverNameController.addListener(_updateProvider);
    _receiverPhoneController.addListener(_updateProvider);
    _packageDescriptionController.addListener(_updateProvider);
    _packageWeightController.addListener(_updateProvider);
    _specialInstructionsController.addListener(_updateProvider);
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _packageDescriptionController.dispose();
    _packageWeightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _updateProvider() {
    // Only update provider if required fields are filled
    if (_receiverNameController.text.trim().isEmpty ||
        _receiverPhoneController.text.trim().isEmpty ||
        _packageDescriptionController.text.trim().isEmpty) {
      return;
    }

    final weight = _packageWeightController.text.isNotEmpty
        ? double.tryParse(_packageWeightController.text)
        : null;

    ref.read(createDeliveryProvider.notifier).setPackageDetails(
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: _receiverPhoneController.text.trim(),
      packageDescription: _packageDescriptionController.text.trim(),
      packageWeight: weight,
      specialInstructions: _specialInstructionsController.text.isNotEmpty
          ? _specialInstructionsController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.spacingSm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails du colis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Renseignez les informations du destinataire et du colis',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),

            // Receiver Information Section
            const Text(
              'Informations du destinataire',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Receiver Name
            TextFormField(
              controller: _receiverNameController,
              decoration: InputDecoration(
                labelText: 'Nom du destinataire *',
                hintText: 'Ex: Jean Kouassi',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom du destinataire est requis';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Receiver Phone
            TextFormField(
              controller: _receiverPhoneController,
              decoration: InputDecoration(
                labelText: 'Téléphone du destinataire *',
                hintText: 'Ex: 0701234567',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le numéro de téléphone est requis';
                }
                if (value.length < 10) {
                  return 'Numéro de téléphone invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spacingLg),

            // Package Information Section
            const Text(
              'Informations du colis',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Package Description
            TextFormField(
              controller: _packageDescriptionController,
              decoration: InputDecoration(
                labelText: 'Description du colis *',
                hintText: 'Ex: Documents, vêtements, nourriture...',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description du colis est requise';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Package Weight (Optional)
            TextFormField(
              controller: _packageWeightController,
              decoration: InputDecoration(
                labelText: 'Poids du colis (kg)',
                hintText: 'Ex: 2.5',
                prefixIcon: const Icon(Icons.scale_outlined),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
            ),
            const SizedBox(height: AppSizes.spacingMd),

            // Special Instructions (Optional)
            TextFormField(
              controller: _specialInstructionsController,
              decoration: InputDecoration(
                labelText: 'Instructions spéciales (optionnel)',
                hintText: 'Ex: Appeler avant la livraison, fragile...',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSizes.spacingLg),

            // Info card
            Container(
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: AppSizes.spacingSm),
                  Expanded(
                    child: Text(
                      'Les champs marqués d\'un astérisque (*) sont obligatoires. Le destinataire sera contacté lors de la livraison.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.info.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
