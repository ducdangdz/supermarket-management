import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 148),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class AppStatGrid extends StatelessWidget {
  const AppStatGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 4
          : constraints.maxWidth >= 650
          ? 3
          : 2;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
