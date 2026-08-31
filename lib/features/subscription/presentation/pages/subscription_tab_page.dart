import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Вкладка "Подписка" — визуальный макет пейвола, БЕЗ реальной оплаты.
///
/// Важно: исходное ТЗ явно исключало платные тарифы/подписки из MVP.
/// Этот экран добавлен по прямому запросу как статический UI-макет
/// (все кнопки — заглушки со "Скоро"), реальная интеграция с
/// App Store/Google Play Billing НЕ подключена и не входит в этот этап.
class SubscriptionTabPage extends StatefulWidget {
  const SubscriptionTabPage({super.key});

  @override
  State<SubscriptionTabPage> createState() => _SubscriptionTabPageState();
}

class _SubscriptionTabPageState extends State<SubscriptionTabPage> {
  int _selectedPlan = 0; // 0 = месяц, 1 = год

  void _soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скоро')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: _soon, child: const Text('Связаться с нами')),
                  ),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.h1.copyWith(fontSize: 34),
                      children: const [
                        TextSpan(text: 'BASE '),
                        TextSpan(text: 'PRO', style: TextStyle(color: AppColors.accent)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text('Разблокируйте все премиум-функции.', style: AppTextStyles.h3),
                  const SizedBox(height: AppSizes.lg),
                  Row(
                    children: const [
                      Expanded(
                        child: _FeatureTile(
                          icon: Icons.block,
                          title: 'Без рекламы',
                          subtitle: 'Удалить все рекламные материалы',
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: _FeatureTile(
                          icon: Icons.share_outlined,
                          title: 'Поделиться проектом',
                          subtitle: 'Неограниченное использование',
                        ),
                      ),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: _FeatureTile(
                          icon: Icons.lock_outline,
                          title: 'Только чтение',
                          subtitle: 'Защитить безопасность',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const _CheckRow('Разблокируй все премиум-материалы, шаблоны и шрифты'),
                  const _CheckRow('Неограниченные проекты'),
                  const _CheckRow('Неограниченное создание шаблонов BASE'),
                  const _CheckRow('Зашифрованный обмен проектами'),
                  const _CheckRow('100 ежемесячных кредитов'),
                  const SizedBox(height: AppSizes.lg),
                  _PlanCard(
                    selected: _selectedPlan == 0,
                    title: 'USD 9.99 / Month',
                    subtitle: '7 days free trial, automatic renewal.',
                    onTap: () => setState(() => _selectedPlan = 0),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _PlanCard(
                    selected: _selectedPlan == 1,
                    title: 'USD 83.99 / Year',
                    subtitle: '6,99 \$ / Month',
                    onTap: () => setState(() => _selectedPlan = 1),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    'Подписка, оформленная в этом приложении, действует только '
                    'в рамках одной платформы (App Store или Google Play) и не '
                    'переносится на другие.',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(onPressed: _soon, child: const Text('Конфиденциальность')),
                      TextButton(onPressed: _soon, child: const Text('Условия использования')),
                      TextButton(onPressed: _soon, child: const Text('Восстановить покупку')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSizes.lg,
            right: AppSizes.lg,
            bottom: AppSizes.lg,
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF4C842), foregroundColor: Colors.black),
                onPressed: _soon,
                child: const Text('Начать 7-дневный бесплатный пробный период'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF4C842)),
          const SizedBox(height: AppSizes.xs),
          Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;

  const _CheckRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Color(0xFFF4C842), size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlanCard({required this.selected, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: selected ? const Color(0xFFF4C842) : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? const Color(0xFFF4C842) : AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
