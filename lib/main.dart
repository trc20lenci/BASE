import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // firebase_options.dart генерируется командой `flutterfire configure`
  // локально (см. README, раздел "Подключение Firebase") — она создаёт
  // реальные ключи проекта для Android/iOS/Web и НЕ должна коммититься
  // с настоящими продовыми ключами в публичный репозиторий без review.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: BaseApp()));
}
