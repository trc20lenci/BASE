/// Конфигурация подключения к Supabase.
///
/// ЗАГЛУШКА — заполните реальными значениями своего проекта из
/// Supabase Dashboard → Project Settings → API (см. README, раздел
/// "Подключение Supabase").
///
/// Важно: [anonKey] — это публичный ключ ("anon/public"), его наличие в
/// клиентском коде — штатная модель Supabase, а не утечка секрета: вся
/// защита данных обеспечивается политиками Row Level Security (RLS) на
/// стороне PostgreSQL, а не секретностью этого ключа. Приватный
/// "service_role" ключ, наоборот, никогда не должен попадать в
/// мобильное приложение.
///
/// Для реального продакшена рекомендуется передавать эти значения через
/// `--dart-define=SUPABASE_URL=...` и `--dart-define=SUPABASE_ANON_KEY=...`
/// вместо хардкода — заготовка для этого ниже (fromEnvironment с
/// дефолтом-заглушкой).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'REPLACE_WITH_YOUR_SUPABASE_PROJECT_URL',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'REPLACE_WITH_YOUR_SUPABASE_ANON_KEY',
  );
}
