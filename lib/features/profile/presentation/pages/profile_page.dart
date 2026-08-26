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

/// Экран профиля: фото, имя пользователя, уникальный ID, смена аватара.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar(String userId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      await ref.read(uploadAvatarUseCaseProvider).call(
            userId: userId,
            imageFile: File(picked.path),
          );
      // authStateChangesProvider перечитает документ пользователя и
      // обновит avatarUrl во всём приложении автоматически.
      ref.invalidate(authStateChangesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить аватар: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Вы не авторизованы'));
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  Stack(
                    children: [
                      BaseAvatar(avatarUrl: user.avatarUrl, size: AppSizes.avatarSizeLarge),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.overlay,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: _isUploadingAvatar
                              ? null
                              : () => _pickAndUploadAvatar(user.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(user.username.isEmpty ? user.email : user.username,
                      style: AppTextStyles.h2),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'ID: ${user.id}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                    title: Text(user.email, style: AppTextStyles.body),
                    subtitle: Text('Email', style: AppTextStyles.caption),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(signOutUseCaseProvider).call(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}
