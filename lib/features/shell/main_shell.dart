import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/job_providers.dart';

/// Persistent four-tab navigation for the main application.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _labels = ['Home', 'Saved', 'Applications', 'Notifications'];

  static const _icons = [
    [Icons.home_rounded, Icons.home_outlined],
    [Icons.favorite_rounded, Icons.favorite_border_rounded],
    [Icons.assignment_rounded, Icons.assignment_outlined],
    [Icons.notifications_rounded, Icons.notifications_none_rounded],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref
        .watch(notificationsProvider)
        .where((notification) => notification.unread)
        .length;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 62,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: List.generate(_labels.length, (index) {
              final selected = navigationShell.currentIndex == index;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: _labels[index],
                  child: InkWell(
                    onTap: () => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              _icons[index][selected ? 0 : 1],
                              size: 22,
                              color: selected
                                  ? AppColors.brand500
                                  : AppColors.muted,
                            ),
                            if (index == 3 && unreadCount > 0)
                              Positioned(
                                right: -10,
                                top: -5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brand500,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: AppTypography.textTheme.labelSmall!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 9,
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _labels[index],
                          style: AppTypography.textTheme.labelSmall!.copyWith(
                            fontSize: 10.5,
                            color: selected
                                ? AppColors.brand500
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
