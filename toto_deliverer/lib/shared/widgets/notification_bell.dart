import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Widget réutilisable pour l'icône de notification avec badge
class NotificationBell extends StatelessWidget {
  final int unreadCount;
  final Color? iconColor;
  final double? iconSize;

  const NotificationBell({
    super.key,
    this.unreadCount = 0,
    this.iconColor,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: iconColor ?? AppColors.secondary,
            size: iconSize,
          ),
          onPressed: () {
            // TODO: Navigate to notifications screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications à implémenter'),
              ),
            );
          },
        ),
        // Badge de notification
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
