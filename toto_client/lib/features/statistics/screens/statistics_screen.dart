import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Ce mois';

  final List<String> _periods = [
    'Cette semaine',
    'Ce mois',
    '3 derniers mois',
    'Cette année',
  ];

  // Mock data - will be replaced with real data from provider
  final Map<String, Map<String, dynamic>> _mockData = {
    'Cette semaine': {
      'revenus': 28500,
      'courses': 8,
      'note': 4.7,
      'tauxReussite': 100,
      'tempsMoyen': '28 min',
      'distanceTotale': '42 km',
      'prixMoyen': 3562,
      'standard': 6,
      'express': 2,
      'destinations': [
        {'name': 'Plateau', 'count': 3},
        {'name': 'Cocody', 'count': 2},
        {'name': 'Marcory', 'count': 2},
      ],
    },
    'Ce mois': {
      'revenus': 89250,
      'courses': 25,
      'note': 4.8,
      'tauxReussite': 96,
      'tempsMoyen': '32 min',
      'distanceTotale': '156 km',
      'prixMoyen': 3570,
      'standard': 18,
      'express': 7,
      'destinations': [
        {'name': 'Plateau', 'count': 8},
        {'name': 'Cocody', 'count': 7},
        {'name': 'Yopougon', 'count': 5},
      ],
    },
    '3 derniers mois': {
      'revenus': 267800,
      'courses': 76,
      'note': 4.7,
      'tauxReussite': 95,
      'tempsMoyen': '31 min',
      'distanceTotale': '468 km',
      'prixMoyen': 3523,
      'standard': 54,
      'express': 22,
      'destinations': [
        {'name': 'Plateau', 'count': 24},
        {'name': 'Cocody', 'count': 18},
        {'name': 'Yopougon', 'count': 15},
      ],
    },
    'Cette année': {
      'revenus': 445600,
      'courses': 128,
      'note': 4.8,
      'tauxReussite': 94,
      'tempsMoyen': '30 min',
      'distanceTotale': '782 km',
      'prixMoyen': 3481,
      'standard': 92,
      'express': 36,
      'destinations': [
        {'name': 'Plateau', 'count': 38},
        {'name': 'Cocody', 'count': 32},
        {'name': 'Yopougon', 'count': 25},
      ],
    },
  };

  Map<String, dynamic> get _currentData => _mockData[_selectedPeriod]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Statistiques'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Selector
                _buildPeriodSelector(),

                const SizedBox(height: AppSizes.spacingXl),

                // KPI Cards
                _buildKPICards(),

                const SizedBox(height: AppSizes.spacingXl),

                // Detailed Statistics Section
                _buildDetailedStats(),

                const SizedBox(height: AppSizes.spacingXl),

                // Delivery Type Breakdown
                _buildDeliveryTypeBreakdown(),

                const SizedBox(height: AppSizes.spacingXl),

                // Top Destinations
                _buildTopDestinations(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: _periods.map((String period) {
            return DropdownMenuItem<String>(
              value: period,
              child: Text(
                period,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedPeriod = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        // Revenus Card
        Expanded(
          child: _buildKPICard(
            icon: Icons.account_balance_wallet,
            label: 'Revenus',
            value: '${_currentData['revenus']} FCFA',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSizes.spacingMd),
        // Courses Card
        Expanded(
          child: _buildKPICard(
            icon: Icons.local_shipping,
            label: 'Courses',
            value: '${_currentData['courses']}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.spacingMd),
        // Note Card
        Expanded(
          child: _buildKPICard(
            icon: Icons.star,
            label: 'Note',
            value: '${_currentData['note']}',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques détaillées',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          _buildStatRow(
            icon: Icons.check_circle,
            label: 'Taux de réussite',
            value: '${_currentData['tauxReussite']}%',
            progress: _currentData['tauxReussite'] / 100,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildStatRow(
            icon: Icons.access_time,
            label: 'Temps moyen',
            value: _currentData['tempsMoyen'],
            progress: 0.7,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildStatRow(
            icon: Icons.route,
            label: 'Distance totale',
            value: _currentData['distanceTotale'],
            progress: 0.65,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildStatRow(
            icon: Icons.attach_money,
            label: 'Prix moyen',
            value: '${_currentData['prixMoyen']} FCFA',
            progress: 0.8,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSizes.spacingSm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingXs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTypeBreakdown() {
    final total = _currentData['standard'] + _currentData['express'];
    final standardPercent = (_currentData['standard'] / total * 100).toInt();
    final expressPercent = (_currentData['express'] / total * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          Row(
            children: [
              Expanded(
                flex: standardPercent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusSm),
                      bottomLeft: Radius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: expressPercent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(AppSizes.radiusSm),
                      bottomRight: Radius.circular(AppSizes.radiusSm),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTypeItem(
                color: AppColors.primary,
                label: 'Standard',
                count: _currentData['standard'],
                percentage: standardPercent,
              ),
              _buildTypeItem(
                color: AppColors.secondary,
                label: 'Express',
                count: _currentData['express'],
                percentage: expressPercent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem({
    required Color color,
    required String label,
    required int count,
    required int percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.spacingSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            Text(
              '$count courses ($percentage%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopDestinations() {
    final destinations = _currentData['destinations'] as List<Map<String, dynamic>>;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSizes.spacingSm),
              Text(
                'Top 3 destinations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingLg),
          ...destinations.asMap().entries.map((entry) {
            final index = entry.key;
            final dest = entry.value;
            final isLast = index == destinations.length - 1;

            return Column(
              children: [
                _buildDestinationItem(
                  rank: index + 1,
                  name: dest['name'] as String,
                  count: dest['count'] as int,
                ),
                if (!isLast) const SizedBox(height: AppSizes.spacingMd),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDestinationItem({
    required int rank,
    required String name,
    required int count,
  }) {
    Color rankColor;
    if (rank == 1) {
      rankColor = AppColors.warning;
    } else if (rank == 2) {
      rankColor = AppColors.textSecondary;
    } else {
      rankColor = const Color(0xFFCD7F32); // Bronze
    }

    return Row(
      children: [
        // Rank badge
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: rankColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.spacingMd),
        // Destination name
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        // Count badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: AppSizes.paddingSm,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(
            '$count livraisons',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
          ),
        ),
      ],
    );
  }
}
