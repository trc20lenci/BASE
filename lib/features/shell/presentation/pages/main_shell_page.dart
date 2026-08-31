import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/pages/projects_tab_page.dart';
import '../../../learning/presentation/pages/learning_tab_page.dart';
import '../../../profile/presentation/pages/profile_tab_page.dart';
import '../../../subscription/presentation/pages/subscription_tab_page.dart';
import '../../../templates/presentation/pages/templates_tab_page.dart';

/// Корневой экран приложения после авторизации — нижняя навигация с
/// 5 вкладками, как в референсных макетах: Проекты, Шаблоны, Обучение,
/// Подписка, Я.
///
/// Архитектурное решение: вкладки держим через IndexedStack (а не через
/// StatefulShellRoute go_router), потому что ни одна вкладка сейчас не
/// нуждается в собственном глубоком стеке маршрутов — это самый простой
/// вариант, дающий сохранение состояния каждой вкладки при переключении.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  static const _pages = [
    ProjectsTabPage(),
    TemplatesTabPage(),
    LearningTabPage(),
    SubscriptionTabPage(),
    ProfileTabPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BaseBottomNav(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BaseBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BaseBottomNav({required this.currentIndex, required this.onChanged});

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Проекты'),
    (icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Шаблоны'),
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Обучение'),
    (icon: Icons.workspace_premium_outlined, activeIcon: Icons.workspace_premium, label: 'Подписка'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Я'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(child: _NavItem(item: _items[i], selected: i == currentIndex, onTap: () => onChanged(i))),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ({IconData icon, IconData activeIcon, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
