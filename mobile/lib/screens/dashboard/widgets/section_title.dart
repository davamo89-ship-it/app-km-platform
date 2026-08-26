import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.actionText,
  });

  final String title;
  final String actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          actionText,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
