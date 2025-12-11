import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NotificationBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onPressed;

  const NotificationBadge({
    super.key,
    required this.icon,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.background,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textWhite,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
