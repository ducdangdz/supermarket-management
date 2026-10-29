import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_brand.dart';

/// Same frame for credentials and Google; authentication stays with callers.
class AppAuthLayout extends StatelessWidget {
  const AppAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.demo = false,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final bool demo;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 960 && constraints.maxHeight >= 560;
        return Row(
          children: [
            if (wide)
              Expanded(
                child: Container(
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppBrand(light: true),
                          const Spacer(),
                          const Icon(
                            Icons.people_alt_outlined,
                            size: 64,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Cùng đội ngũ,\nvận hành tốt hơn.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Lịch làm việc, chấm công và nhân sự\ntrong một không gian thống nhất.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.7,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'SMARTMARKET HRM',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 40 : 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!wide) ...[
                            const AppBrand(),
                            const SizedBox(height: 32),
                          ],
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              constraints.maxWidth < 400 ? 20 : 28,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Chip(
                                    avatar: Icon(
                                      demo
                                          ? Icons.science_outlined
                                          : Icons.verified_user_outlined,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    label: Text(
                                      demo
                                          ? 'Không gian trải nghiệm'
                                          : 'Tài khoản hệ thống',
                                    ),
                                    backgroundColor: AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                child,
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'SmartMarket HRM · Quản lý nhân sự',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
