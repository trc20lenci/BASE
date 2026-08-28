import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/supabase_constants.dart';

/// Аватар пользователя. Если avatarUrl пуст или равен пути дефолтного
/// ассета — показываем стандартный аватар из assets/images.
///
/// Примечание: сам файл стандартного аватара пользователь загрузит
/// отдельно в assets/images/default_avatar.png (см. README).
class BaseAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final VoidCallback? onTap;

  const BaseAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 40,
    this.onTap,
  });

  bool get _isNetwork => avatarUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: _isNetwork
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _defaultAvatar(),
              )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Image.asset(
      SupabaseConstants.defaultAvatarAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.textSecondary),
    );
  }
}
