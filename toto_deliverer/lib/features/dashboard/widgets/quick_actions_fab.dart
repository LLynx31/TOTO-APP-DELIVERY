import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class QuickActionsFab extends StatefulWidget {
  const QuickActionsFab({super.key});

  @override
  State<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends State<QuickActionsFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons
        if (_isExpanded) ...[
          _buildActionButton(
            label: 'Scanner QR',
            icon: Icons.qr_code_scanner,
            onTap: () {
              _toggle();
              // TODO: Navigate to QR scanner
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanner QR...')),
              );
            },
          ),
          const SizedBox(height: AppSizes.spacingSm),
          _buildActionButton(
            label: 'Appeler support',
            icon: Icons.headset_mic,
            onTap: () {
              _toggle();
              // TODO: Call support
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appel support...')),
              );
            },
          ),
          const SizedBox(height: AppSizes.spacingSm),
          _buildActionButton(
            label: 'Ma position',
            icon: Icons.my_location,
            onTap: () {
              _toggle();
              // TODO: Show current location
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Localisation...')),
              );
            },
          ),
          const SizedBox(height: AppSizes.spacingMd),
        ],

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandAnimation.value * 0.785, // 45 degrees
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                  color: AppColors.textWhite,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _expandAnimation,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Material(
            color: AppColors.background,
            elevation: 2,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMd,
                vertical: AppSizes.paddingSm,
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spacingSm),

          // Button
          FloatingActionButton.small(
            onPressed: onTap,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primary,
            elevation: 2,
            heroTag: label, // Unique tag for each button
            child: Icon(icon),
          ),
        ],
      ),
    );
  }
}
