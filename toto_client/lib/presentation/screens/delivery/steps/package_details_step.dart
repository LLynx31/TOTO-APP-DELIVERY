import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../providers/create_delivery_provider.dart';
import '../../../widgets/country_phone_field.dart';

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
  final _phoneFieldKey = GlobalKey<CountryPhoneFieldState>();
  Country _selectedCountry = availableCountries[0]; // Burkina Faso par défaut

  @override
  void initState() {
    super.initState();
    // Load existing values from provider if any
    final state = ref.read(createDeliveryProvider);
    _receiverNameController.text = state.receiverName ?? '';
    _packageDescriptionController.text = state.packageDescription ?? '';
    _packageWeightController.text = state.packageWeight?.toString() ?? '';
    _specialInstructionsController.text = state.specialInstructions ?? '';

    // Si un numéro de téléphone existe, extraire le numéro local
    if (state.receiverPhone != null && state.receiverPhone!.isNotEmpty) {
      _initPhoneFromFullNumber(state.receiverPhone!);
    }

    // Add listeners to update provider on change
    _receiverNameController.addListener(_updateProvider);
    _receiverPhoneController.addListener(_updateProvider);
    _packageDescriptionController.addListener(_updateProvider);
    _packageWeightController.addListener(_updateProvider);
    _specialInstructionsController.addListener(_updateProvider);
  }

  /// Initialise le champ téléphone à partir d'un numéro complet (+XXX...)
  void _initPhoneFromFullNumber(String fullNumber) {
    // Chercher le pays correspondant à l'indicatif
    for (final country in availableCountries) {
      if (fullNumber.startsWith(country.dialCode)) {
        _selectedCountry = country;
        _receiverPhoneController.text = fullNumber.substring(country.dialCode.length);
        return;
      }
    }
    // Si pas trouvé, utiliser le numéro tel quel
    _receiverPhoneController.text = fullNumber;
  }

  /// Récupère le numéro complet avec indicatif pays
  String _getFullPhoneNumber() {
    final localNumber = _receiverPhoneController.text.trim();
    if (localNumber.isEmpty) return '';

    // Supprimer le 0 initial si présent
    final cleanNumber = localNumber.startsWith('0')
        ? localNumber.substring(1)
        : localNumber;

    return '${_selectedCountry.dialCode}$cleanNumber';
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
    final fullPhoneNumber = _getFullPhoneNumber();
    if (_receiverNameController.text.trim().isEmpty ||
        fullPhoneNumber.isEmpty ||
        _packageDescriptionController.text.trim().isEmpty) {
      return;
    }

    final weight = _packageWeightController.text.isNotEmpty
        ? double.tryParse(_packageWeightController.text)
        : null;

    ref.read(createDeliveryProvider.notifier).setPackageDetails(
      receiverName: _receiverNameController.text.trim(),
      receiverPhone: fullPhoneNumber,
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

            // Receiver Phone avec sélecteur de pays
            CountryPhoneField(
              key: _phoneFieldKey,
              controller: _receiverPhoneController,
              label: 'Téléphone du destinataire *',
              hint: '07 00 00 00 00',
              initialCountry: _selectedCountry,
              onCountryChanged: (country) {
                setState(() {
                  _selectedCountry = country;
                });
                _updateProvider();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le numéro de téléphone est requis';
                }
                // Validation basique: au moins 8 chiffres
                final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                if (digitsOnly.length < 8) {
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
