import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/repositories/rating_repository.dart';
import '../../../core/di/injection.dart' as di;
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/rating/star_rating_input.dart';

/// Écran de notation d'une livraison
class RateDeliveryScreen extends ConsumerStatefulWidget {
  final String deliveryId;
  final String delivererName;
  final String? delivererPhotoUrl;

  const RateDeliveryScreen({
    super.key,
    required this.deliveryId,
    required this.delivererName,
    this.delivererPhotoUrl,
  });

  @override
  ConsumerState<RateDeliveryScreen> createState() => _RateDeliveryScreenState();
}

class _RateDeliveryScreenState extends ConsumerState<RateDeliveryScreen> {
  int _selectedStars = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Suggestions de commentaires rapides
  final List<String> _quickComments = [
    'Ponctuel',
    'Poli',
    'Professionnel',
    'Rapide',
    'Soin du colis',
    'Très bien',
  ];

  final List<String> _selectedQuickComments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleQuickComment(String comment) {
    setState(() {
      if (_selectedQuickComments.contains(comment)) {
        _selectedQuickComments.remove(comment);
      } else {
        _selectedQuickComments.add(comment);
      }

      // Mettre à jour le champ de commentaire
      _commentController.text = _selectedQuickComments.join(', ');
    });
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une note';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final createRatingUsecase = ref.read(di.createRatingUsecaseProvider);

      final params = CreateRatingParams(
        deliveryId: widget.deliveryId,
        stars: _selectedStars,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      final result = await createRatingUsecase(params);

      if (!mounted) return;

      switch (result) {
        case Success():
          // Navigation vers l'écran de félicitation
          context.go('/delivery/${widget.deliveryId}/success');

        case Failure(:final message):
          setState(() {
            _errorMessage = message;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Une erreur est survenue: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Noter la livraison'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingLg),
        child: Column(
          children: [
            // Avatar et nom du livreur
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: widget.delivererPhotoUrl != null
                  ? NetworkImage(widget.delivererPhotoUrl!)
                  : null,
              child: widget.delivererPhotoUrl == null
                  ? Text(
                      widget.delivererName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Nom du livreur
            Text(
              widget.delivererName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingSm),

            Text(
              'Comment s\'est passée votre livraison ?',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Sélection d'étoiles
            StarRatingInput(
              initialRating: _selectedStars,
              onRatingChanged: (rating) {
                setState(() {
                  _selectedStars = rating;
                  _errorMessage = null;
                });
              },
              size: 50,
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Suggestions de commentaires rapides
            Text(
              'Suggestions rapides',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickComments.map((comment) {
                final isSelected = _selectedQuickComments.contains(comment);
                return FilterChip(
                  label: Text(comment),
                  selected: isSelected,
                  onSelected: (_) => _toggleQuickComment(comment),
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Champ de commentaire
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: AppSizes.spacingXl),

            // Message d'erreur
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                margin: const EdgeInsets.only(bottom: AppSizes.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: AppSizes.spacingSm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // Bouton soumettre
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _selectedStars == 0 ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  disabledBackgroundColor: AppColors.border,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Soumettre',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppSizes.spacingMd),

            // Bouton ignorer
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      // Navigation vers l'écran de félicitation sans noter
                      context.go('/delivery/${widget.deliveryId}/success');
                    },
              child: Text(
                'Ignorer',
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
