# BASE — мобильное приложение для монтажа видео (MVP)

Flutter-приложение для Android и iOS. Этот репозиторий развивается
поэтапно, строго по плану из ТЗ:

- [x] **Этап 1. Структура проекта** — Clean Architecture, Feature-First, Riverpod
- [x] **Этап 2. Все экраны (UI)** — Splash, Login/Register/Forgot Password, Home, Profile, Create Project, Editor (заготовка), Export (заготовка)
- [x] **Этап 3. Навигация** — go_router с redirect по состоянию авторизации
- [x] **Этап 4. Подключение Firebase** — Auth, Firestore, Storage (код готов, ключи проекта нужно сгенерировать — см. ниже)
- [x] **Этап 5. Работа с проектами** — создание/переименование/удаление/дублирование через Firestore
- [ ] **Этап 6. Редактор** — таймлайн, импорт медиа, обрезка/разделение, холст, текст — *в разработке*
- [ ] **Этап 7. Экспорт** — рендер MP4 720p/1080p, сохранение в галерею — *в разработке*

## Архитектура

**Clean Architecture + Feature-First**, три слоя на каждую фичу:

```
lib/
  core/                      # общее для всего приложения
    constants/                # цвета, размеры, текстовые стили, ключи Firebase
    theme/                     # единая тёмная тема (Material 3)
    routing/                   # go_router + redirect по авторизации
    widgets/                   # переиспользуемые UI-компоненты
  features/
    <feature>/
      domain/                  # entities, repository-контракты, usecases
                                # — НЕ знает про Firebase
      data/                    # datasources (прямая работа с Firebase),
                                # models (маппинг Firestore <-> Entity),
                                # repository-реализации
      presentation/            # pages (экраны), widgets, riverpod-провайдеры
```

Почему так:

- **domain не зависит от Firebase** — если в будущем понадобится сменить
  бэкенд (например, добавить offline-first кэш), это не потребует
  переписывать usecases и экраны.
- **Riverpod** выбран из трёх вариантов (Provider/Riverpod/Bloc) как
  наиболее удобный для DI через провайдеры + встроенная поддержка
  `StreamProvider` для реактивных данных Firestore (список проектов,
  состояние авторизации) без ручного управления подписками.
- **Feature-First** — каждая фича самодостаточна и может развиваться/
  тестироваться независимо; это масштабируется на будущие функции
  (эффекты, переходы и т.д., когда придёт их черёд по ТЗ).

## Стек

- Flutter / Dart
- Firebase Authentication, Cloud Firestore, Firebase Storage
- flutter_riverpod — состояние и DI
- go_router — навигация
- image_picker — импорт фото/видео из галереи
- gal — сохранение экспортированного видео в галерею устройства

## Подключение Firebase (для локального запуска)

`lib/firebase_options.dart` в репозитории — это **заглушка**. Чтобы
запустить проект:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Команда подключится к Firebase-проекту и перезапишет
`lib/firebase_options.dart` реальными ключами, а также положит
`google-services.json` / `GoogleService-Info.plist` в нужные папки
(они в `.gitignore` и не должны коммититься с реальными ключами
в публичный репозиторий).

Также нужно включить в Firebase Console:
- Authentication → Email/Password
- Firestore Database (коллекции `users`, `projects` создаются
  автоматически при первом использовании)
- Storage (пути `avatars/{userId}.jpg`, `exports/{userId}/{projectId}.mp4`)

## Дефолтный аватар и шрифт

- Положите файл стандартного аватара в `assets/images/default_avatar.png`
  (путь уже подключён в `pubspec.yaml` и используется в
  `FirebaseConstants.defaultAvatarAsset`).
- Для единственного шрифта текстового инструмента в редакторе (этап 6)
  положите `.ttf` в `assets/fonts/` — константа шрифта будет добавлена
  вместе с реализацией инструмента "Текст".

## Установка зависимостей

```bash
flutter pub get
```

## Логотип

Оба варианта логотипа (для тёмного и светлого фона) уже добавлены в
`assets/images/logo_black_bg.jpg` и `assets/images/logo_white_bg.jpg`
и используются на Splash Screen и экране входа.
