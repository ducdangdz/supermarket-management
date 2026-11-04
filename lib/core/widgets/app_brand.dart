import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({super.key, this.light = false, this.compact = false});
  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: light
              ? Colors.white.withValues(alpha: .15)
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.storefront_rounded,
          color: light ? Colors.white : AppColors.primary,
          size: 24,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SmartMarket',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: light ? Colors.white : AppColors.primary,
                ),
              ),
              Text(
                'HUMAN RESOURCES',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: light ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
