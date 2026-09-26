# TTRPG Audio Master (Cross-Platform TTRPG Audio Player)

Аудио-плеер и микшер фоновых звуков, музыки и SFX эффектов для мастеров настольно-ролевых игр (D&D, Pathfinder, Call of Cthulhu и др.).

## Ключевой функционал (Milestone 1 Core)

* **3-Уровневый аудио-микшер:**
  * **Music Bus:** Динамическая музыка с уровнем интенсивности (*CALM / SUSPENSE / BATTLE / BOSS*), плавными перепадами и фадином.
  * **Ambient Bus:** Параллельное воспроизведение нескольких слоев фоновых звуков (дождь, костёр, шум толпы) с индивидуальными уровнями громкости.
  * **SFX Bus / Soundboard:** Быстрые триггеры звуковых эффектов (удары меча, фаерболы, рык дракона) с подвязаными горячими клавишами.
* **Auto-Ducking:** Автоматическое приглушение музыки при проигрывании громких звуковых эффектов.

---

## Запуск приложения

Для запуска необходим [Flutter SDK](https://flutter.dev/docs/get-started/install):

```bash
# Получить зависимости
flutter pub get

# Запуск на ПК (Windows / Linux)
flutter run -d windows
# или
flutter run -d linux

# Запуск на Android / Google TV
flutter run -d android
```

---

## Архитектура проекта

```
lib/
├── main.dart
├── models/
│   ├── audio_track.dart       # Модель музыкальных треков и уровней интенсивности
│   ├── ambient_layer.dart     # Модель слоев фоновых звуков
│   └── sfx_trigger.dart       # Модель быстрых эффектов саундборда
├── audio/
│   ├── audio_engine_service.dart   # Главный фасад аудио-движка
│   ├── music_bus_controller.dart   # Управление музыкой и кроссфейдами
│   ├── ambient_bus_controller.dart # Управление параллельным эмбиентом
│   ├── sfx_bus_controller.dart     # Управление низкой задержкой SFX
│   └── ducking_controller.dart     # Контроллер авто-приглушения
└── ui/
    ├── screens/
    │   └── main_dashboard_screen.dart # Главная панель управления ГМа
    └── widgets/
        ├── music_player_panel.dart    # Панель музыки и интенсивности
        ├── ambient_mixer_panel.dart   # Панель фоновых звуков
        └── soundboard_grid.dart       # Сетка SFX саундборда
```
