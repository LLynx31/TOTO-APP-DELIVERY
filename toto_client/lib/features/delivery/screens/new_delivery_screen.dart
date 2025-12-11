import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/models.dart';
import 'steps/location_step.dart';
import 'steps/package_details_step.dart';
import 'steps/summary_step.dart';
import 'searching_deliverer_screen.dart';

class NewDeliveryScreen extends StatefulWidget {
  final AddressModel? initialPickupAddress;
  final AddressModel? initialDeliveryAddress;

  const NewDeliveryScreen({
    super.key,
    this.initialPickupAddress,
    this.initialDeliveryAddress,
  });

  @override
  State<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends State<NewDeliveryScreen> {
  int _currentStep = 0;

  // Delivery data
  AddressModel? _pickupAddress;
  AddressModel? _deliveryAddress;
  PackageModel? _package;
  DeliveryMode _deliveryMode = DeliveryMode.standard;
  bool _hasInsurance = false;

  final List<String> _stepTitles = [
    'Emplacement',
    'Détails du colis',
    'Récapitulatif',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with passed addresses if provided
    if (widget.initialPickupAddress != null) {
      _pickupAddress = widget.initialPickupAddress;
    }
    if (widget.initialDeliveryAddress != null) {
      _deliveryAddress = widget.initialDeliveryAddress;
    }
  }

  void _onLocationStepCompleted({
    required AddressModel pickup,
    required AddressModel delivery,
  }) {
    setState(() {
      _pickupAddress = pickup;
      _deliveryAddress = delivery;
      _currentStep = 1;
    });
  }

  void _onPackageDetailsCompleted({
    required PackageModel package,
    required DeliveryMode mode,
    required bool hasInsurance,
  }) {
    setState(() {
      _package = package;
      _deliveryMode = mode;
      _hasInsurance = hasInsurance;
      _currentStep = 2;
    });
  }

  void _onDeliveryConfirmed() {
    // Navigate to searching deliverer screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingDelivererScreen(
          pickupAddress: _pickupAddress!.address,
          deliveryAddress: _deliveryAddress!.address,
          packageDescription: _package!.description ?? '',
          packageSize: _package!.size,
          estimatedWeight: _package!.weight,
        ),
      ),
    );
  }

  void _onStepBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${_stepTitles[_currentStep]} ${_currentStep + 1}/3'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _onStepBack();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      backgroundColor: AppColors.background,
      body: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),

            // Step Content
            Expanded(
              child: _buildCurrentStep(),
            ),
          ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return LocationStep(
          initialPickup: _pickupAddress,
          initialDelivery: _deliveryAddress,
          onCompleted: _onLocationStepCompleted,
        );
      case 1:
        return PackageDetailsStep(
          initialPackage: _package,
          initialMode: _deliveryMode,
          initialHasInsurance: _hasInsurance,
          onCompleted: _onPackageDetailsCompleted,
          onBack: _onStepBack,
        );
      case 2:
        // Only build summary if all data is available
        if (_pickupAddress != null &&
            _deliveryAddress != null &&
            _package != null) {
          return SummaryStep(
            pickupAddress: _pickupAddress!,
            deliveryAddress: _deliveryAddress!,
            package: _package!,
            mode: _deliveryMode,
            hasInsurance: _hasInsurance,
            onConfirm: _onDeliveryConfirmed,
            onBack: _onStepBack,
          );
        }
        // Fallback if data is missing (shouldn't happen in normal flow)
        return const Center(
          child: CircularProgressIndicator(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLg,
        vertical: AppSizes.paddingMd,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: AppSizes.spacingXs),
              ],
            ),
          );
        }),
      ),
    );
  }
}
