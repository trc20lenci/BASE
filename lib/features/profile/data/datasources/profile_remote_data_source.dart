import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/constants/supabase_constants.dart';

/// Работа с профилем на уровне Supabase: обновление username в таблице
/// `profiles` и загрузка/смена аватара в Supabase Storage (бакет `avatars`).
class ProfileRemoteDataSource {
  final sb.SupabaseClient _client;

  ProfileRemoteDataSource({sb.SupabaseClient? client})
      : _client = client ?? sb.Supabase.instance.client;

  /// Загружает файл аватара в бакет `avatars` по пути {userId}.jpg
  /// (с перезаписью — upsert), затем сохраняет публичный URL в строку
  /// профиля пользователя, и возвращает этот URL.
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final path = SupabaseConstants.avatarPath(userId);

    await _client.storage.from(SupabaseConstants.avatarsBucket).upload(
          path,
          imageFile,
          fileOptions: const sb.FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    final publicUrl = _client.storage.from(SupabaseConstants.avatarsBucket).getPublicUrl(path);

    // Добавляем query-параметр с меткой времени, чтобы обойти кэш CDN/
    // Image.network при смене аватара по тому же пути.
    final cacheBustedUrl = '$publicUrl?updated=${DateTime.now().millisecondsSinceEpoch}';

    await _client
        .from(SupabaseConstants.profilesTable)
        .update({'avatar_url': cacheBustedUrl})
        .eq('id', userId);

    return cacheBustedUrl;
  }

  Future<void> updateUsername({
    required String userId,
    required String username,
  }) {
    return _client
        .from(SupabaseConstants.profilesTable)
        .update({'username': username})
        .eq('id', userId);
  }
}
