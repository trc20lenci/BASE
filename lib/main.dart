import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase — единственный бэкенд приложения (Auth,
  // PostgreSQL Database, Storage). SupabaseConfig — заглушка с реальными
  // значениями проекта, см. README, раздел "Подключение Supabase".
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: BaseApp()));
}
