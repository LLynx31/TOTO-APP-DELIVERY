import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

class PackageDetailsStep extends StatefulWidget {
  final PackageModel? initialPackage;
  final DeliveryMode initialMode;
  final bool initialHasInsurance;
  final Function({
    required PackageModel package,
    required DeliveryMode mode,
    required bool hasInsurance,
  }) onCompleted;
  final VoidCallback onBack;

  const PackageDetailsStep({
    super.key,
    this.initialPackage,
    required this.initialMode,
    required this.initialHasInsurance,
    required this.onCompleted,
    required this.onBack,
  });

  @override
  State<PackageDetailsStep> createState() => _PackageDetailsStepState();
}

class _PackageDetailsStepState extends State<PackageDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();

  PackageSize _selectedSize = PackageSize.medium;
  DeliveryMode _selectedMode = DeliveryMode.standard;
  bool _hasInsurance = false;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    if (widget.initialPackage != null) {
      _selectedSize = widget.initialPackage!.size;
      _weightController.text = widget.initialPackage!.weight.toString();
      _descriptionController.text = widget.initialPackage!.description ?? '';
      _photoPath = widget.initialPackage!.photoUrl;
    }
    _selectedMode = widget.initialMode;
    _hasInsurance = widget.initialHasInsurance;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      final package = PackageModel(
        size: _selectedSize,
        weight: double.parse(_weightController.text),
        description: _descriptionController.text,
        photoUrl: _photoPath,
      );

      widget.onCompleted(
        package: package,
        mode: _selectedMode,
        hasInsurance: _hasInsurance,
      );
    }
  }

  double _calculatePrice() {
    double basePrice = 1000;

    // Size multiplier
    switch (_selectedSize) {
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

    // Weight addition
    final weight = double.tryParse(_weightController.text) ?? 0;
    basePrice += (weight * 200);

    // Mode multiplier
    if (_selectedMode == DeliveryMode.express) {
      basePrice *= 1.5;
    }

    // Insurance
    if (_hasInsurance) {
      basePrice += 500;
    }

    return basePrice;
  }

  Future<void> _pickImage() async {
    // Show bottom sheet to choose between camera and gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choisir une photo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSizes.spacingLg),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.secondary),
                  title: const Text('Prendre une photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.secondary),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: AppSizes.spacingSm),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _photoPath = image.path;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la sélection de l\'image: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _photoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Section
              Text(
                AppStrings.packagePhoto,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: AppSizes.spacingMd),

              _buildPhotoUpload(),

              const SizedBox(height: AppSizes.spacingXl),

              // Size Selection
              Text(
                AppStrings.packageSize,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: AppSizes.spacingMd),

              _buildSizeSelector(),

              const SizedBox(height: AppSizes.spacingXl),

              // Weight
              CustomTextField(
                label: AppStrings.packageWeight,
                hint: '5.5',
                controller: _weightController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0) {
                    return 'Poids invalide';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Description
              CustomTextField(
                label: AppStrings.packageDescription,
                hint: 'Décrivez brièvement le contenu de votre colis...',
                controller: _descriptionController,
                maxLines: 3,
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Delivery Mode
              Text(
                AppStrings.deliveryMode,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: AppSizes.spacingMd),

              _buildModeSelector(),

              const SizedBox(height: AppSizes.spacingXl),

              // Insurance Toggle
              CustomCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.addInsurance,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: AppSizes.spacingXs),
                          Text(
                            'Protection en cas de dommage (+500 FCFA)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hasInsurance,
                      onChanged: (value) {
                        setState(() {
                          _hasInsurance = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.spacingXl),

              // Estimated Price - Enhanced UI
              _buildPriceBreakdown(),

              const SizedBox(height: AppSizes.spacingXl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.previous,
                      onPressed: widget.onBack,
                      variant: ButtonVariant.outline,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spacingMd),
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.next,
                      onPressed: _handleNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.border,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _photoPath != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: Image.file(
                      File(_photoPath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // Remove button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textWhite,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSizes.spacingSm),
                  Text(
                    AppStrings.addPhoto,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Row(
      children: PackageSize.values.map((size) {
        final isSelected = _selectedSize == size;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSizes.spacingSm),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSize = size;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color:
                          isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 32,
                    ),
                    const SizedBox(height: AppSizes.spacingXs),
                    Text(
                      size.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: DeliveryMode.values.map((mode) {
        final isSelected = _selectedMode == mode;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingSm),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMode = mode;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(AppSizes.paddingMd),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Radio<DeliveryMode>(
                    value: mode,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMode = value;
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.displayName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          mode.duration,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceBreakdown() {
    final price = _calculatePrice();

    // Calculate individual components
    double basePrice = 1000;

    // Size multiplier
    double sizeMultiplier = 1.0;
    switch (_selectedSize) {
      case PackageSize.small:
        sizeMultiplier = 0.8;
        break;
      case PackageSize.medium:
        sizeMultiplier = 1.0;
        break;
      case PackageSize.large:
        sizeMultiplier = 1.5;
        break;
    }
    final sizePrice = basePrice * sizeMultiplier;

    // Weight addition
    final weight = double.tryParse(_weightController.text) ?? 0;
    final weightPrice = weight * 200;

    // Insurance
    final insurancePrice = _hasInsurance ? 500.0 : 0.0;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prix estimé',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMd,
                  vertical: AppSizes.paddingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  '${price.toInt()} FCFA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spacingMd),
          const Divider(),
          const SizedBox(height: AppSizes.spacingMd),

          // Price breakdown
          _buildPriceItem(
            icon: Icons.inventory_2_outlined,
            label: 'Base (${_selectedSize.displayName})',
            amount: sizePrice,
          ),

          if (weight > 0) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceItem(
              icon: Icons.scale_outlined,
              label: 'Poids (${weight.toStringAsFixed(1)} kg)',
              amount: weightPrice,
            ),
          ],

          if (_selectedMode == DeliveryMode.express) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceItem(
              icon: Icons.flash_on,
              label: 'Mode Express (+50%)',
              amount: (sizePrice + weightPrice) * 0.5,
              isHighlight: true,
            ),
          ],

          if (_hasInsurance) ...[
            const SizedBox(height: AppSizes.spacingSm),
            _buildPriceItem(
              icon: Icons.shield_outlined,
              label: 'Assurance',
              amount: insurancePrice,
            ),
          ],

          const SizedBox(height: AppSizes.spacingMd),

          // Info note
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSizes.spacingSm),
                Expanded(
                  child: Text(
                    'Le prix final peut varier selon la distance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceItem({
    required IconData icon,
    required String label,
    required double amount,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isHighlight ? AppColors.secondary : AppColors.textSecondary,
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isHighlight ? AppColors.secondary : AppColors.textSecondary,
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
        Text(
          '${amount.toInt()} FCFA',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighlight ? AppColors.secondary : AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}
