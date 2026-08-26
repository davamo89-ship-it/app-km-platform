import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class StravaCardHeader extends StatelessWidget {
  const StravaCardHeader({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
