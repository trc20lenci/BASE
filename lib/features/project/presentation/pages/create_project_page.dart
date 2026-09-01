import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/routing/route_names.dart';

/// Экран "Создайте" — открывается по кнопке "+" с вкладки "Проекты".
/// Верстка повторяет референсный макет: вкладки "Создайте/Ваше", баннер,
/// крупная кнопка "Новое видео", промо-плашка BASE PRO, три карточки
/// быстрых действий, сетка инструментов, блок "Обучение".
///
/// Рабочая кнопка здесь одна — "Новое видео" (ведёт в подбор медиа и
/// дальше в редактор). Остальные карточки и инструменты — заглушки
/// ("Скоро"), как и написано в задаче: "пока большинство функций
/// заглушки, но потом добавим".
class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  bool _bannerDismissed = false;

  void _soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скоро')));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close)),
                  const Spacer(),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textDisabled,
              indicatorColor: AppColors.textPrimary,
              tabs: const [Tab(text: 'Создайте'), Tab(text: 'Ваше')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CreateTab(bannerDismissed: _bannerDismissed, onDismissBanner: () => setState(() => _bannerDismissed = true), onSoon: _soon),
                  Center(child: Text('Пока пусто', style: AppTextStyles.bodySecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTab extends StatelessWidget {
  final bool bannerDismissed;
  final VoidCallback onDismissBanner;
  final VoidCallback onSoon;

  const _CreateTab({required this.bannerDismissed, required this.onDismissBanner, required this.onSoon});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.lg),
      children: [
        if (!bannerDismissed) ...[
          _InfoBanner(onClose: onDismissBanner),
          const SizedBox(height: AppSizes.md),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          onTap: () => context.push(RouteNames.mediaPicker),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2B5CE0), Color(0xFF5B8CFF)]),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              children: [
                const Icon(Icons.content_cut, color: Colors.white, size: 32),
                const SizedBox(height: AppSizes.sm),
                Text('Новое видео', style: AppTextStyles.h2.copyWith(color: Colors.white)),
                Text('Выберите фото и видео', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: onSoon,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(color: const Color(0xFFFFF6D8), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: Color(0xFFC9971F)),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.body.copyWith(color: const Color(0xFF6B5417)),
                      children: const [
                        TextSpan(text: 'Повысьте до ', ),
                        TextSpan(text: 'BASE PRO', style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ', чтобы разблокировать неограниченное количество проектов.'),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF6B5417)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            Expanded(child: _QuickCard(icon: Icons.image_outlined, label: 'Редактировать фото', onTap: onSoon)),
            const SizedBox(width: AppSizes.sm),
            Expanded(child: _QuickCard(icon: Icons.dashboard_outlined, label: 'Коллаж', onTap: onSoon)),
            const SizedBox(width: AppSizes.sm),
            Expanded(child: _QuickCard(icon: Icons.auto_awesome, label: 'Автомонтаж', onTap: onSoon)),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        Text('Инструменты', style: AppTextStyles.h3),
        const SizedBox(height: AppSizes.sm),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.sm,
          crossAxisSpacing: AppSizes.sm,
          childAspectRatio: 0.85,
          children: [
            _ToolCell(icon: Icons.subject, label: 'Телесуфлер', onTap: onSoon),
            _ToolCell(icon: Icons.bolt_outlined, label: 'Бит-клипы', onTap: onSoon),
            _ToolCell(icon: Icons.palette_outlined, label: 'Создать шаблоны', onTap: onSoon),
            _ToolCell(icon: Icons.crop_outlined, label: 'Захват кадра', onTap: onSoon, badge: 'New'),
            _ToolCell(icon: Icons.layers_outlined, label: 'Наложение', onTap: onSoon),
            _ToolCell(icon: Icons.view_agenda_outlined, label: 'Сторис', onTap: onSoon),
            _ToolCell(icon: Icons.desktop_windows_outlined, label: 'Редактор для компьютера', onTap: onSoon, badge: 'New'),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        Text('Обучение', style: AppTextStyles.h3),
        const SizedBox(height: AppSizes.sm),
        Text('Использовано хранилища: —', style: AppTextStyles.caption),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final VoidCallback onClose;

  const _InfoBanner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2B5CE0), Color(0xFF5B8CFF)]),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text('Быстрый гайд, чтобы начать', style: AppTextStyles.body.copyWith(color: Colors.white)),
          ),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white70, size: 18)),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(height: AppSizes.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const _ToolCell({required this.icon, required this.label, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            padding: const EdgeInsets.all(AppSizes.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.textSecondary),
                const SizedBox(height: 4),
                Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(4)),
                child: Text(badge!, style: const TextStyle(fontSize: 9, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
