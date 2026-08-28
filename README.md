# BASE — мобильное приложение для монтажа видео (MVP)

Flutter-приложение для Android и iOS. Этот репозиторий развивается
поэтапно, строго по плану из ТЗ:

- [x] **Этап 1. Структура проекта** — Clean Architecture, Feature-First, Riverpod
- [x] **Этап 2. Все экраны (UI)** — Splash, Login/Register/Forgot Password, Home, Profile, Create Project, Editor, Export
- [x] **Этап 3. Навигация** — go_router с redirect по состоянию авторизации
- [x] **Этап 4. Подключение Supabase** — Auth, PostgreSQL Database, Storage (код готов, ключи проекта нужно сгенерировать — см. ниже)
- [x] **Этап 5. Работа с проектами** — создание/переименование/удаление/дублирование через PostgreSQL (Supabase)
- [x] **Этап 6. Редактор** — таймлайн (фото/видео), импорт из галереи, обрезка/разделение видео, холст (перемещение/масштаб/поворот/кадрирование), текст
- [~] **Этап 7. Экспорт** — UI, выбор качества (720p/1080p), сохранение в галерею готовы; сам движок рендера MP4 — см. раздел "Экспорт видео: важное ограничение" ниже

> **Бэкенд — только Supabase.** Firebase (Auth/Firestore/Storage) в проекте
> не используется и не подключён ни в коде, ни в зависимостях, ни в
> нативных конфигурациях Android/iOS.

## Архитектура

**Clean Architecture + Feature-First**, три слоя на каждую фичу:

```
lib/
  core/                      # общее для всего приложения
    config/                    # конфигурация подключения к Supabase
    constants/                 # цвета, размеры, текстовые стили, таблицы/бакеты Supabase
    theme/                      # единая тёмная тема (Material 3)
    routing/                    # go_router + redirect по авторизации
    widgets/                    # переиспользуемые UI-компоненты
  features/
    <feature>/
      domain/                   # entities, repository-контракты, usecases
                                 # — НЕ знает про Supabase
      data/                     # datasources (прямая работа с Supabase),
                                 # models (маппинг Postgres-строка <-> Entity),
                                 # repository-реализации
      presentation/             # pages (экраны), widgets, riverpod-провайдеры
```

Почему так:

- **domain не зависит от Supabase** — если в будущем понадобится сменить
  бэкенд, это не потребует переписывать usecases и экраны. Весь
  Supabase-специфичный код изолирован в `data/datasources`.
- **Riverpod** выбран из трёх вариантов (Provider/Riverpod/Bloc) как
  наиболее удобный для DI через провайдеры + встроенная поддержка
  `StreamProvider` для реактивных данных PostgreSQL через Supabase
  Realtime (список проектов, состояние авторизации) без ручного
  управления подписками.
- **Feature-First** — каждая фича самодостаточна и может развиваться/
  тестироваться независимо; это масштабируется на будущие функции
  (эффекты, переходы и т.д., когда придёт их черёд по ТЗ).

## Стек

- Flutter / Dart
- **Supabase**: Auth (email/пароль), PostgreSQL Database, Storage, Realtime
- flutter_riverpod — состояние и DI
- go_router — навигация
- image_picker — импорт фото/видео из галереи
- gal — сохранение экспортированного видео в галерею устройства

## Соответствие сервисов (если ранее ориентировались на Firebase)

| Было бы на Firebase     | В этом проекте — Supabase                                            |
|--------------------------|------------------------------------------------------------------------|
| Firebase Authentication  | **Supabase Auth** (email/пароль, `auth.users`)                        |
| Firestore                 | **PostgreSQL** (таблицы `profiles`, `projects`, `project_timelines`) |
| Firebase Storage          | **Supabase Storage** (бакеты `avatars`, `project-media`, `exports`)  |
| Firestore snapshots        | **Supabase Realtime** (`.stream()` на таблице `projects`)            |

## Подключение Supabase (для локального запуска)

1. Создайте проект на [supabase.com](https://supabase.com).
2. В **SQL Editor** выполните целиком файл [`supabase/schema.sql`](supabase/schema.sql)
   из этого репозитория — он создаёт все таблицы, RLS-политики и три
   Storage-бакета (`avatars`, `project-media`, `exports`) одной командой.
3. В **Project Settings → API** скопируйте `Project URL` и `anon public` ключ.
4. Передайте их в приложение одним из двух способов:

   **Вариант А — через `--dart-define` (рекомендуется, ключи не попадают в git):**
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJхxxxxx...
   ```

   **Вариант Б — напрямую в `lib/core/config/supabase_config.dart`:**
   замените значения `defaultValue` в `SupabaseConfig.url` и
   `SupabaseConfig.anonKey` на реальные (файл — заглушка, см. комментарий
   в нём про то, почему `anon key` не является секретом).
5. В **Authentication → Providers** убедитесь, что Email-провайдер включён
   (включён по умолчанию). Для восстановления пароля по email настройте
   SMTP или используйте встроенный (ограниченный по лимитам) почтовый
   сервис Supabase — раздел **Authentication → Email Templates**.

Приватность данных обеспечивается не секретностью `anon key`, а
политиками **Row Level Security**, уже прописанными в `schema.sql`:
каждый пользователь видит и меняет только свои профиль/проекты/таймлайны/
файлы.

## Экспорт видео: важное ограничение

Экран экспорта (выбор качества 720p/1080p, прогресс, сохранение в
галерею через пакет `gal`) полностью реализован. Единственное, что
сознательно оставлено подключаемым модулем — сам **движок рендера**
итогового MP4 (`VideoExportEngine` в
`lib/features/export/domain/repositories/video_export_engine.dart`).
Это решение не связано с выбором Supabase/Firebase — рендер видео
происходит на устройстве, а не на бэкенде.

Почему: наиболее очевидный кандидат для рендера видео на устройстве —
`ffmpeg_kit_flutter` — официально свёрнут автором (репозиторий
`arthenica/ffmpeg-kit` заброшен), поэтому закладывать его в архитектуру
нового проекта на старте — плохое решение. Вместо этого:

1. Зафиксирован чистый контракт `VideoExportEngine.render(...)`.
2. Весь остальной MVP (UI, таймлайн, трансформации, сохранение в
   галерею) уже вызывает этот контракт и полностью готов к работе.
3. Когда будет выбрана актуальная библиотека кодирования видео
   (актуальный форк ffmpeg-kit на момент разработки, либо нативный
   MediaCodec/AVFoundation-пайплайн), нужно реализовать интерфейс и
   подставить реализацию в `videoExportEngineProvider`
   (`lib/features/export/presentation/providers/export_providers.dart`)
   — без изменений в остальном коде.

Бакет `exports` в Supabase Storage зарезервирован на случай, если в
будущем рендер переедет на сервер (например, в Supabase Edge Function);
сейчас он не используется, т.к. экспорт сохраняется локально на
устройство через `gal`.

## Разрешения (Android/iOS)

Для импорта фото/видео из галереи и сохранения экспортированного видео
нужно добавить в нативные проекты:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>BASE нужен доступ к галерее для импорта фото и видео в проект</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>BASE сохраняет готовое видео в вашу галерею</string>
```

## Дефолтный аватар и шрифт

- Положите файл стандартного аватара в `assets/images/default_avatar.png`
  (путь уже подключён в `pubspec.yaml` и используется в
  `SupabaseConstants.defaultAvatarAsset`).
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
