import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/models/delivery_model.dart';

/// Bottom sheet pour filtrer l'historique des livraisons
class HistoryFiltersSheet extends StatefulWidget {
  final String? selectedPeriod;
  final DeliveryMode? selectedMode;
  final String? searchQuery;
  final Function(String? period, DeliveryMode? mode, String? query) onApply;

  const HistoryFiltersSheet({
    super.key,
    this.selectedPeriod,
    this.selectedMode,
    this.searchQuery,
    required this.onApply,
  });

  @override
  State<HistoryFiltersSheet> createState() => _HistoryFiltersSheetState();
}

class _HistoryFiltersSheetState extends State<HistoryFiltersSheet> {
  late String? _selectedPeriod;
  late DeliveryMode? _selectedMode;
  late TextEditingController _searchController;

  final List<String> _periods = [
    'Aujourd\'hui',
    'Cette semaine',
    'Ce mois',
    'Tous',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.selectedPeriod;
    _selectedMode = widget.selectedMode;
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedPeriod = null;
      _selectedMode = null;
      _searchController.clear();
    });
  }

  void _applyFilters() {
    widget.onApply(
      _selectedPeriod,
      _selectedMode,
      _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSizes.paddingSm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtres',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingLg),

                // Recherche par ID
                Text(
                  'Recherche par ID',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Ex: DEL003',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingMd,
                      vertical: AppSizes.paddingSm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingLg),

                // Période
                Text(
                  'Période',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                Wrap(
                  spacing: AppSizes.spacingSm,
                  runSpacing: AppSizes.spacingSm,
                  children: _periods.map((period) {
                    final isSelected = _selectedPeriod == period;
                    return FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = selected ? period : null;
                        });
                      },
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.spacingLg),

                // Mode de livraison
                Text(
                  'Mode de livraison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeChip(
                        label: 'Standard',
                        mode: DeliveryMode.standard,
                        color: AppColors.standard,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacingMd),
                    Expanded(
                      child: _buildModeChip(
                        label: 'Express',
                        mode: DeliveryMode.express,
                        color: AppColors.express,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingXl),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMd),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Appliquer les filtres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildModeChip({
    required String label,
    required DeliveryMode mode,
    required Color color,
  }) {
    final isSelected = _selectedMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMode = isSelected ? null : mode;
        });
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMd,
          vertical: AppSizes.paddingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surface,
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? color : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSizes.spacingSm),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
