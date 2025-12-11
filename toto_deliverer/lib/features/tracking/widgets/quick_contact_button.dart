import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

class QuickContactButton extends StatelessWidget {
  final String phoneNumber;
  final bool isFloating;

  const QuickContactButton({
    super.key,
    required this.phoneNumber,
    this.isFloating = false,
  });

  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Impossible d\'appeler $phoneNumber'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'appel: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFloating) {
      return FloatingActionButton(
        onPressed: () => _makePhoneCall(context),
        backgroundColor: AppColors.primary,
        elevation: AppSizes.elevationLg,
        child: const Icon(
          Icons.phone,
          color: AppColors.textWhite,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _makePhoneCall(context),
      icon: const Icon(Icons.phone, size: 20),
      label: Text(AppStrings.callCustomer),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm,
        ),
      ),
    );
  }
}
