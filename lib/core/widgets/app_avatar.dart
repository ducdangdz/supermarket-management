import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.radius = 24, this.imageUrl});
  final double radius;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.person_outline_rounded,
      color: AppColors.primary,
      size: radius,
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: ClipOval(
        child: imageUrl == null || imageUrl!.isEmpty
            ? fallback
            : Image.network(
                imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
