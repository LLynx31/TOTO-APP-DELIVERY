import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/rating.dart';
import 'package:intl/intl.dart';

/// Card pour afficher un résumé de notation
class RatingSummaryCard extends StatelessWidget {
  final Rating rating;
  final String ratedUserName;
  final bool isGivenRating; // true = notation donnée, false = notation reçue

  const RatingSummaryCard({
    super.key,
    required this.rating,
    required this.ratedUserName,
    this.isGivenRating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec nom et étoiles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isGivenRating
                      ? 'Vous avez noté $ratedUserName'
                      : '$ratedUserName vous a noté',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.stars.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Commentaire si présent
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              rating.comment!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Date
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            DateFormat('dd/MM/yyyy à HH:mm').format(rating.createdAt),
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
