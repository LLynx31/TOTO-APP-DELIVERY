import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

class NavigationButton extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String destinationLabel;

  const NavigationButton({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.destinationLabel,
  });

  Future<void> _openNavigation(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppSizes.paddingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.navigateWith,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSizes.spacingLg),
              ListTile(
                leading: const Icon(Icons.map, color: AppColors.primary),
                title: Text(AppStrings.googleMaps),
                subtitle: Text('Naviguer vers $destinationLabel'),
                onTap: () {
                  Navigator.pop(context);
                  _launchGoogleMaps(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation, color: AppColors.accent),
                title: Text(AppStrings.waze),
                subtitle: Text('Naviguer vers $destinationLabel'),
                onTap: () {
                  Navigator.pop(context);
                  _launchWaze(context);
                },
              ),
              const SizedBox(height: AppSizes.spacingMd),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppStrings.cancel),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchGoogleMaps(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showError(context, 'Impossible d\'ouvrir Google Maps');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  Future<void> _launchWaze(BuildContext context) async {
    // Try Waze deep link first
    final wazeUrl = Uri.parse('waze://?ll=$latitude,$longitude&navigate=yes');

    try {
      if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Waze web
        final wazeWebUrl = Uri.parse(
          'https://www.waze.com/ul?ll=$latitude,$longitude&navigate=yes',
        );
        if (await canLaunchUrl(wazeWebUrl)) {
          await launchUrl(wazeWebUrl, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            _showError(context, 'Waze n\'est pas installé');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _openNavigation(context),
      icon: const Icon(Icons.directions, size: 20),
      label: Text(AppStrings.openNavigation),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
