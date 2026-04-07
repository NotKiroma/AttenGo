# AttenGo — Refactored Structure v2

## Принцип: оригинальный код + новая структура

Все экраны и сервисы **сохранены без изменений** — тот же дизайн, та же логика, те же данные.
Изменения только в:
1. **Структура папок** — `screens/`, `services/`, `utils/`, `core/`
2. **Секреты** — `db_service.dart` теперь использует `envied` вместо хардкода
3. **N+1 fix** — `student_service.dart` batch-запрос для аватарок
4. **RLS** — SQL-скрипт для Supabase

## Структура

```
lib/
├── core/
│   ├── env.dart              — envied (обфускация ключей)
│   └── providers.dart        — Riverpod провайдеры (для будущей миграции)
│
├── services/                  — ⚡ ОРИГИНАЛЬНЫЕ сервисы (без изменений)
│   ├── db_service.dart        — обновлён: envied вместо хардкода
│   ├── auth_service.dart
│   ├── group_service.dart
│   ├── schedule_service.dart
│   ├── attendance_service.dart
│   ├── student_service.dart   — обновлён: N+1 fix
│   ├── announcement_service.dart
│   ├── notification_service.dart
│   ├── realtime_service.dart
│   └── app_cache.dart
│
├── screens/                   — ⚡ ОРИГИНАЛЬНЫЕ экраны (без изменений!)
│   ├── home_screen.dart
│   ├── schedule_screen.dart
│   ├── attendance_screen.dart
│   ├── stats_screen.dart
│   ├── profile_screen.dart
│   ├── notification_screen.dart
│   ├── student_profile_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── auth_wrapper.dart
│
├── utils/                     — ⚡ ОРИГИНАЛЬНЫЕ утилиты
│   ├── app_colors.dart
│   ├── app_snackbar.dart
│   ├── dark_page_route.dart
│   └── plural_utils.dart
│
├── features/                  — 🆕 Riverpod-версии (для постепенной миграции)
│   ├── schedule/              — domain, data, application, presentation
│   ├── group/
│   ├── auth/
│   ├── attendance/
│   ├── announcements/
│   └── notifications/
│
├── main_screen.dart           — ⚡ ОРИГИНАЛ
└── main.dart                  — обновлён: DatabaseService.init()
```

## Что НЕ изменилось
- Весь UI / дизайн
- Вся бизнес-логика экранов
- Realtime-подписки
- Навигация
- Все данные работают как раньше

## Что изменилось
1. `main.dart` — вместо `Supabase.initialize(url: '...', anonKey: '...')` → `DatabaseService.init()`
2. `db_service.dart` — ключи из `envied` вместо хардкода
3. `student_service.dart` — 1 batch-запрос вместо N запросов для аватарок
4. Папки организованы: `screens/`, `services/`, `utils/`, `core/`

## Быстрый старт

1. Скопируйте `lib/` в ваш Flutter-проект
2. `cp .env.example .env` → заполните ключи Supabase
3. Добавьте в pubspec.yaml:
   ```yaml
   dependencies:
     envied: ^1.1.1
   dev_dependencies:
     envied_generator: ^1.1.1
     build_runner: ^2.4.13
   ```
4. `dart run build_runner build --delete-conflicting-outputs`
5. Выполните `supabase_rls_migration.sql` в Supabase SQL Editor
6. `flutter run`

## Постепенная миграция на Riverpod

Папка `features/` содержит Riverpod-версии (репозитории, провайдеры, контроллеры).
Можно мигрировать экран за экраном, не ломая работающий код:

1. Добавить `flutter_riverpod` в pubspec
2. Обернуть `MyApp` в `ProviderScope`
3. Один за одним переводить экраны на `ConsumerWidget`
4. Когда все экраны мигрированы — удалить `services/` и `screens/`
