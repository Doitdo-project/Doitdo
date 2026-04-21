import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 하단 탭 아이템 정의. 아이콘/라벨은 임시값이며
/// 실제 아트워크가 오면 교체한다.
class DoitdoTabItem {
  const DoitdoTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// 3-탭(할 일 / 다마고치 / 설정) 하단 네비게이션.
///
/// `StatefulShellRoute.indexedStack` 의 `navigationShell.currentIndex` 를
/// `currentIndex` 로, `navigationShell.goBranch` 를 `onTap` 으로 연결해
/// 사용한다.
class DoitdoBottomNav extends StatelessWidget {
  const DoitdoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DoitdoTabItem> items;

  /// 실제 아이콘은 추후 교체. 라벨은 `AppTextStyles.labelSmall` 규격.
  static const List<DoitdoTabItem> defaultItems = [
    DoitdoTabItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: '캘린더',
    ),
    DoitdoTabItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '홈',
    ),
    DoitdoTabItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: '설정',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colors.bottomNavBg,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textHint,
      selectedLabelStyle: AppTextStyles.labelSmall,
      unselectedLabelStyle: AppTextStyles.labelSmall,
      showUnselectedLabels: true,
      items: [
        for (final item in items)
          BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          ),
      ],
    );
  }
}