import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_brand.dart';

class WorkspaceDestination {
  const WorkspaceDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Sidebar on desktop; bounded navigation plus a complete menu on phones.
class AppWorkspace extends StatelessWidget {
  const AppWorkspace({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.child,
    this.mobileIndices,
    this.onExit,
  });
  final String title;
  final List<WorkspaceDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget child;
  final List<int>? mobileIndices;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 1000) {
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                Container(
                  width: 248,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(right: BorderSide(color: AppColors.divider)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .025),
                        blurRadius: 18,
                        offset: const Offset(3, 0),
                      ),
                    ],
                  ),
                  child: Material(
                    color: AppColors.surface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(14, 18, 14, 24),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: .62),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const AppBrand(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              for (var i = 0; i < destinations.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 13),
                                    selected: i == selectedIndex,
                                    selectedTileColor: AppColors.primary,
                                    selectedColor: Colors.white,
                                    iconColor: i == selectedIndex ? Colors.white : AppColors.textSecondary,
                                    textColor: i == selectedIndex ? Colors.white : AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                                    leading: Icon(destinations[i].icon, size: 20),
                                    title: Text(destinations[i].label, style: TextStyle(fontSize: 13, fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500)),
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (onExit != null) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextButton.icon(
                              onPressed: onExit,
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                              ),
                              label: const Text('Trang chủ'),
                            ),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                          child: Text(
                            'SMARTMARKET HRM',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      final indices =
          mobileIndices ??
          List.generate(
            destinations.length > 5 ? 4 : destinations.length,
            (i) => i,
          );
      final hasMore = indices.length < destinations.length;
      final active = indices.indexOf(selectedIndex);
      return Scaffold(
        body: child,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: NavigationBar(
            selectedIndex: active < 0 ? indices.length : active,
            onDestinationSelected: (i) {
              if (i < indices.length) {
                onSelected(indices[i]);
              } else {
                _showMenu(context);
              }
            },
            destinations: [
              for (final i in indices)
                NavigationDestination(
                  icon: Icon(destinations[i].icon),
                  label: destinations[i].label,
                ),
              if (hasMore)
                const NavigationDestination(
                  icon: Icon(Icons.more_horiz_rounded),
                  label: 'Thêm',
                ),
            ],
          ),
        ),
      );
    },
  );

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (var i = 0; i < destinations.length; i++)
                  ListTile(
                    selected: selectedIndex == i,
                    selectedColor: AppColors.primary,
                    leading: Icon(destinations[i].icon),
                    title: Text(destinations[i].label),
                    trailing: selectedIndex == i
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSelected(i);
                    },
                  ),
                if (onExit != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: const Text('Trang chủ'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onExit!();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
