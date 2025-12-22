import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Widget pour afficher le code de livraison 4 chiffres
class DeliveryCodeDisplay extends StatelessWidget {
  final String code;
  final String title;
  final String description;

  const DeliveryCodeDisplay({
    super.key,
    required this.code,
    this.title = 'Code de validation',
    this.description = 'Communiquez ce code au livreur si le scan QR ne fonctionne pas',
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papier'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Séparer le code en caractères individuels
    final codeDigits = code.split('');

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSizes.spacingLg),

          // Boxes pour chaque chiffre
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: codeDigits.asMap().entries.map((entry) {
              final isLast = entry.key == codeDigits.length - 1;
              return Padding(
                padding: EdgeInsets.only(
                  right: isLast ? 0 : AppSizes.spacingMd,
                ),
                child: _DigitBox(digit: entry.value),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.spacingLg),

          // Bouton copier
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _copyToClipboard(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
              ),
              icon: const Icon(
                Icons.copy,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'Copier le code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.spacingMd),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher un chiffre individuel dans une box
class _DigitBox extends StatelessWidget {
  final String digit;

  const _DigitBox({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
