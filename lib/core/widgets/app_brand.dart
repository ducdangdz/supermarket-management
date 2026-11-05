import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppBrand extends StatelessWidget {
  const AppBrand({
    super.key,
    this.light = false,
    this.compact = false,
    this.large = false,
  });
  final bool light;
  final bool compact;
  final bool large;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: large ? 48 : 38,
        height: large ? 48 : 38,
        decoration: BoxDecoration(
          color: light
              ? Colors.white.withValues(alpha: .18)
              : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(large ? 14 : 10),
        ),
        child: Icon(
          Icons.storefront_rounded,
          color: light ? Colors.white : AppColors.primary,
          size: large ? 28 : 22,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SmartMarket',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: large ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: light ? Colors.white : AppColors.primary,
                ),
              ),
              Text(
                'HUMAN RESOURCES',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: large ? 10 : 8.5,
                  letterSpacing: 1.0,
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
