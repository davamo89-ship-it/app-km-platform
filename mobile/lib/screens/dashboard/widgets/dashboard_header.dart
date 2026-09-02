import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.displayName,
    required this.onNotificationsPressed,
    this.unreadNotificationCount = 0,
  });

  final String displayName;
  final VoidCallback onNotificationsPressed;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Sigue sumando kilómetros',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _NotificationBell(
            unreadCount: unreadNotificationCount,
            onPressed: onNotificationsPressed,
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      tooltip: unreadCount > 0
          ? 'Tiene notificaciones sin revisar'
          : 'Notificaciones',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.16),
      ),
      icon: Icon(
        unreadCount > 0
            ? Icons.notifications_rounded
            : Icons.notifications_none_rounded,
        color: Colors.white,
      ),
    );

    if (unreadCount <= 0) {
      return button;
    }

    return Badge(
      label: Text(
        unreadCount > 9 ? '9+' : '$unreadCount',
      ),
      child: button,
    );
  }
}
