import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../delivery/screens/qr_code_screen.dart';
import '../../delivery/screens/tracking_screen.dart';

enum NotificationFilter { all, tracking, qrCode }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationModel> _notifications = [];
  NotificationFilter _selectedFilter = NotificationFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotifications() {
    // Mock data with more variety
    // Delivery IDs match TrackingScreen data: 1=deliveryInProgress, 2=pickupInProgress, 3/4=delivered
    _notifications.addAll([
      // Recent tracking notifications
      NotificationModel(
        id: '1',
        userId: 'user123',
        type: NotificationType.delivererOnWayToDestination,
        title: 'Livreur en route vers vous',
        message: 'Kouassi arrive dans 3 min • Cocody → Plateau',
        deliveryId: '1', // Corresponds to deliveryInProgress in TrackingScreen
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      // QR Code notification (urgent)
      NotificationModel(
        id: '2',
        userId: 'user123',
        type: NotificationType.deliveryAccepted,
        title: 'Code de réception prêt',
        message: 'Montrez ce code au livreur pour confirmer la livraison #DEL001',
        deliveryId: '1', // Same delivery as above
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      NotificationModel(
        id: '3',
        userId: 'user123',
        type: NotificationType.delivererOnWayToPickup,
        title: 'Livreur en route vers A',
        message: 'Arrivée estimée dans 8 min • Marcory → Yopougon',
        deliveryId: '2', // Corresponds to pickupInProgress in TrackingScreen
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: '4',
        userId: 'user123',
        type: NotificationType.packageDelivered,
        title: 'Colis livré avec succès',
        message: 'Évaluez votre livreur Kouassi Yao',
        deliveryId: '3', // Corresponds to delivered in TrackingScreen
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      // Yesterday
      NotificationModel(
        id: '5',
        userId: 'user123',
        type: NotificationType.packagePickedUp,
        title: 'Colis récupéré',
        message: 'Le livreur a pris votre colis au point A',
        deliveryId: '2', // Same delivery as notification #3
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      NotificationModel(
        id: '6',
        userId: 'user123',
        type: NotificationType.deliveryAccepted,
        title: 'Code de réception disponible',
        message: 'Préparez le code QR pour la livraison #DEL004',
        deliveryId: '4', // Corresponds to delivered in TrackingScreen
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      ),
      // Older
      NotificationModel(
        id: '7',
        userId: 'user123',
        type: NotificationType.delivererOnWayToPickup,
        title: 'Livreur assigné',
        message: 'Jean Kouadio se dirige vers le point de retrait',
        deliveryId: '3', // Corresponds to delivered in TrackingScreen
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      NotificationModel(
        id: '8',
        userId: 'user123',
        type: NotificationType.packageDelivered,
        title: 'Livraison terminée',
        message: 'Votre colis a été livré avec succès',
        deliveryId: '4', // Corresponds to delivered in TrackingScreen
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ]);
  }

  void _markAllAsRead() {
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications marquées comme lues'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _markAsRead(NotificationModel notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  List<NotificationModel> get _filteredNotifications {
    var filtered = _notifications;

    // Filter by type
    if (_selectedFilter == NotificationFilter.qrCode) {
      filtered = filtered
          .where((n) => n.type == NotificationType.deliveryAccepted)
          .toList();
    } else if (_selectedFilter == NotificationFilter.tracking) {
      filtered = filtered
          .where((n) => n.type != NotificationType.deliveryAccepted)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            n.message.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Map<String, List<NotificationModel>> get _groupedNotifications {
    final filtered = _filteredNotifications;
    final Map<String, List<NotificationModel>> grouped = {
      'Aujourd\'hui': [],
      'Hier': [],
      'Plus ancien': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var notification in filtered) {
      final notifDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (notifDate == today) {
        grouped['Aujourd\'hui']!.add(notification);
      } else if (notifDate == yesterday) {
        grouped['Hier']!.add(notification);
      } else {
        grouped['Plus ancien']!.add(notification);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final hasUnread = unreadCount > 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Text(AppStrings.notifications),
            if (hasUnread) ...[
              const SizedBox(width: AppSizes.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  '$unreadCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (hasUnread)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tout lire'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'Aucune notification',
              message: 'Vous n\'avez pas encore de notifications',
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingMd),
                  color: AppColors.background,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: AppStrings.searchNotifications,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.backgroundGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingMd,
                        vertical: AppSizes.paddingSm,
                      ),
                    ),
                  ),
                ),

                // Filter Tabs
                _buildFilterTabs(),

                // Notifications List with Grouping
                Expanded(
                  child: _filteredNotifications.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: 'Aucun résultat',
                          message: _searchQuery.isNotEmpty
                              ? 'Aucune notification ne correspond à "$_searchQuery"'
                              : 'Aucune notification dans cette catégorie',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSizes.paddingMd),
                          itemCount: _groupedNotifications.length,
                          itemBuilder: (context, index) {
                            final groupTitle =
                                _groupedNotifications.keys.elementAt(index);
                            final groupNotifications =
                                _groupedNotifications[groupTitle]!;

                            return _buildNotificationGroup(
                              groupTitle,
                              groupNotifications,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMd,
        vertical: AppSizes.paddingSm,
      ),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Toutes',
            filter: NotificationFilter.all,
            icon: Icons.notifications,
          ),
          const SizedBox(width: AppSizes.spacingSm),
          _buildFilterChip(
            label: 'Suivi',
            filter: NotificationFilter.tracking,
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(width: AppSizes.spacingSm),
          _buildFilterChip(
            label: 'Codes QR',
            filter: NotificationFilter.qrCode,
            icon: Icons.qr_code_2,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required NotificationFilter filter,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMd,
            vertical: AppSizes.paddingSm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.textWhite : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.spacingXs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.textWhite
                          : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(
    String groupTitle,
    List<NotificationModel> notifications,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.paddingSm,
            top: AppSizes.paddingMd,
            bottom: AppSizes.paddingSm,
          ),
          child: Text(
            groupTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
          ),
        ),

        // Notifications in this group
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSizes.spacingMd),
          itemBuilder: (context, index) {
            return _buildNotificationTile(notifications[index]);
          },
        ),

        const SizedBox(height: AppSizes.spacingLg),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final isQRCode = notification.type == NotificationType.deliveryAccepted;
    final isUrgent = _isUrgent(notification);

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSizes.paddingLg),
        child: const Icon(
          Icons.done,
          color: AppColors.textWhite,
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.paddingLg),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.textWhite,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as read/unread
          _markAsRead(notification);
          return false;
        } else {
          // Delete
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer la notification'),
              content: const Text(
                'Voulez-vous vraiment supprimer cette notification ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Supprimer',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification supprimée'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          decoration: BoxDecoration(
            gradient: isQRCode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withValues(alpha: notification.isRead ? 0.05 : 0.15),
                      const Color(0xFF8B5CF6).withValues(alpha: notification.isRead ? 0.05 : 0.15),
                    ],
                  )
                : null,
            color: isQRCode
                ? null
                : notification.isRead
                    ? AppColors.background
                    : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: isQRCode
                  ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                  : isUrgent
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : notification.isRead
                          ? AppColors.border
                          : AppColors.primary.withValues(alpha: 0.3),
              width: isQRCode || isUrgent ? 2 : 1,
            ),
            boxShadow: !notification.isRead
                ? [
                    BoxShadow(
                      color: isQRCode
                          ? const Color(0xFF6366F1).withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(AppSizes.paddingSm),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: AppSizes.iconSizeMd,
                      ),
                    ),

                    const SizedBox(width: AppSizes.spacingMd),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // QR Code Badge
                              if (isQRCode) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingSm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.qr_code_2,
                                        size: 12,
                                        color: AppColors.textWhite,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'QR CODE',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.textWhite,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSizes.spacingSm),
                              ],

                              // Urgent Badge
                              if (isUrgent) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingSm,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusSm,
                                    ),
                                  ),
                                  child: Text(
                                    'URGENT',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: AppSizes.spacingSm),
                              ],

                              // Unread indicator
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: AppSizes.spacingXs),

                          Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                ),
                          ),

                          const SizedBox(height: AppSizes.spacingXs),

                          Text(
                            notification.message,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),

                          const SizedBox(height: AppSizes.spacingSm),

                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(notification.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                              if (isUrgent && notification.deliveryId != null) ...[
                                const SizedBox(width: AppSizes.spacingSm),
                                Icon(
                                  Icons.circle,
                                  size: 4,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: AppSizes.spacingSm),
                                _buildRealTimeTimer(notification),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow indicator
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (!notification.isRead ||
                  notification.type == NotificationType.deliveryAccepted)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSizes.radiusMd),
                      bottomRight: Radius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSizes.paddingSm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isQRCode)
                        TextButton.icon(
                          onPressed: () => _showQRCode(notification),
                          icon: const Icon(Icons.qr_code_2, size: 16),
                          label: const Text('Voir le QR'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingSm,
                              vertical: AppSizes.paddingXs,
                            ),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: () => _trackDelivery(notification),
                          icon: const Icon(Icons.navigation, size: 16),
                          label: const Text('Suivre'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.paddingSm,
                              vertical: AppSizes.paddingXs,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRealTimeTimer(NotificationModel notification) {
    // Extract minutes from message if exists (e.g., "3 min")
    final minutesMatch = RegExp(r'(\d+)\s*min').firstMatch(notification.message);
    if (minutesMatch == null) {
      return const SizedBox.shrink();
    }

    final minutes = int.parse(minutesMatch.group(1)!);
    final eta = notification.createdAt.add(Duration(minutes: minutes));
    final remaining = eta.difference(DateTime.now());

    if (remaining.isNegative) {
      return Text(
        'Arrivé',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Text(
        '⏱ ${remaining.inMinutes} min restantes',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  bool _isUrgent(NotificationModel notification) {
    // Notification is urgent if created within last 5 minutes and is tracking-related
    final diff = DateTime.now().difference(notification.createdAt);
    return diff.inMinutes < 5 &&
        (notification.type == NotificationType.delivererOnWayToPickup ||
            notification.type == NotificationType.delivererOnWayToDestination);
  }

  void _handleNotificationTap(NotificationModel notification) {
    _markAsRead(notification);

    if (notification.type == NotificationType.deliveryAccepted) {
      _showQRCode(notification);
    } else if (notification.deliveryId != null) {
      _trackDelivery(notification);
    }
  }

  void _showQRCode(NotificationModel notification) {
    if (notification.deliveryId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRCodeScreen(
            deliveryId: notification.deliveryId!,
            qrCode: 'delivery_${notification.deliveryId}_qr',
          ),
        ),
      );
    }
  }

  void _trackDelivery(NotificationModel notification) {
    if (notification.deliveryId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackingScreen(
            deliveryId: notification.deliveryId!,
          ),
        ),
      );
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.deliveryAccepted:
        return Icons.qr_code_2_rounded;
      case NotificationType.delivererOnWayToPickup:
        return Icons.directions_bike;
      case NotificationType.packagePickedUp:
        return Icons.inventory_2_outlined;
      case NotificationType.delivererOnWayToDestination:
        return Icons.local_shipping_outlined;
      case NotificationType.packageDelivered:
        return Icons.done_all;
      case NotificationType.deliveryCancelled:
        return Icons.cancel_outlined;
      case NotificationType.other:
        return Icons.info_outline;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.deliveryAccepted:
        return const Color(0xFF6366F1); // Indigo for QR codes
      case NotificationType.packageDelivered:
        return AppColors.success;
      case NotificationType.deliveryCancelled:
        return AppColors.error;
      case NotificationType.delivererOnWayToPickup:
      case NotificationType.delivererOnWayToDestination:
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd MMM yyyy', 'fr_FR').format(dateTime);
    }
  }
}
