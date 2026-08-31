import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/base_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

/// Вкладка "Я" — профиль пользователя, редизайн по референсному макету:
/// шапка с аватаром/именем + список пунктов (Центр кредитования,
/// Шаблоны, Бит-клипы, Бренд-кит, Корзина проекта, Help center).
/// Реальным функционалом наполнены аватар/имя/выход — остальные пункты
/// пока заглушки ("Скоро"), как и в исходном макете.
class ProfileTabPage extends ConsumerStatefulWidget {
  const ProfileTabPage({super.key});

  @override
  ConsumerState<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends ConsumerState<ProfileTabPage> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(String userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(uploadAvatarUseCaseProvider).call(userId: userId, imageFile: File(picked.path));
      ref.invalidate(authStateChangesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось загрузить аватар: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _soon() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Скоро')));

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(signOutUseCaseProvider).call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) return const Center(child: Text('Вы не авторизованы'));

            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.xxl),
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        BaseAvatar(avatarUrl: user.avatarUrl, size: AppSizes.avatarSizeLarge, onTap: () => _pickAndUploadAvatar(user.id)),
                        if (_isUploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.overlay),
                              child: const Center(
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _isUploadingAvatar ? null : () => _pickAndUploadAvatar(user.id),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                              child: const Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.username.isEmpty ? user.email : user.username, style: AppTextStyles.h2),
                          Text('ID: ${user.id}', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(onPressed: _soon, icon: const Icon(Icons.qr_code_scanner_outlined)),
                    IconButton(onPressed: _soon, icon: const Icon(Icons.settings_outlined)),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                const Divider(),
                _ProfileListItem(icon: Icons.attach_money, title: 'Центр кредитования', trailing: '0,00', onTap: _soon),
                _ProfileListItem(icon: Icons.grid_view_outlined, title: 'Шаблоны', onTap: _soon),
                _ProfileListItem(icon: Icons.bolt_outlined, title: 'Бит-клипы', onTap: _soon),
                _ProfileListItem(icon: Icons.wallet_outlined, title: 'Бренд-кит', trailing: '0', onTap: _soon),
                _ProfileListItem(icon: Icons.delete_outline, title: 'Корзина проекта', onTap: _soon),
                _ProfileListItem(icon: Icons.help_outline, title: 'Help center', onTap: _soon),
                const SizedBox(height: AppSizes.lg),
                _ProfileListItem(
                  icon: Icons.logout,
                  title: 'Выйти',
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  onTap: _handleSignOut,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
        ),
      ),
    );
  }
}

class _ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback onTap;

  const _ProfileListItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.body.copyWith(color: titleColor)),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trailing!, style: AppTextStyles.bodySecondary),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
