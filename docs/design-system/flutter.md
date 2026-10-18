# Flutter

Как перенести систему в `lib/domain/models/custom_theme_model.dart` и `lib/theme/app_themes.dart`. Названия токенов совпадают с токенами этой системы.

## Поля `CustomThemeModel`

| Сейчас | Токен | Действие |
| --- | --- | --- |
| `backgroundColor` | `bg` | оставить |
| `surfaceColor` | `surface` | оставить |
| `cardColor` | `surface-raised` | переименовать |
| нет | `surface-hover`, `border`, `border-strong` | добавить, в редакторе вычислять из `surface` |
| `textPrimaryColor` | `text` | оставить |
| `textSecondaryColor` | `text-muted` | оставить |
| `primaryColor` | `primary` | оставить |
| `accentColor`, `secondaryColor` | нет | убрать: акцент один; миграция копирует `primary`, остальные цвета игнорируются |
| нет | `on-primary`, `primary-subtle`, `focus-ring` | добавить, вычислять |
| `duckingBadgeColor` | нет | убрать: ducking показывается иконкой и текстом нейтрального цвета |
| `battleIntensityColor`, `bossIntensityColor` | `intensity-battle`, `intensity-boss` | оставить; добавить `intensity-calm`, `intensity-suspense` |
| нет | `danger`, `success` | добавить с общими значениями по умолчанию для светлой и тёмной тем |

SQLite-схема хранит поля темы; добавление колонок требует миграции `database_service.dart` и значений по умолчанию, как сейчас в `fromMap`.

## `toThemeData()`

- `onPrimary` и `ElevatedButton.foregroundColor` берут `on-primary`, не `Colors.white`.
- `ColorScheme.surfaceContainerHighest` = `surface-raised`, `outline` = `border-strong`, `outlineVariant` = `border`.
- `cardTheme` и `dialogTheme`: радиус 12, рамка `border`, `elevation: 0`. Тень только у `PopupMenu` и диалогов.
- `TextTheme` строится из одного семейства IBM Plex Sans (шрифты в `assets/fonts/`, объявлены в `pubspec.yaml`); удалить все `fontFamilyFallback: ['Georgia', …]`.
- Размеры текста по стилям: `displaySmall` 28, `titleLarge` 20, `titleMedium` 16, `bodyMedium` 14, `labelLarge` 13, `bodySmall` 12.

## Константы

Токены `space-*`, `radius-*` и `size` завести как `abstract class Spacing`, `Radii`, `Sizes` рядом с темой; значения 1:1 с этой системой. Виджеты не используют числа в `EdgeInsets` и `BorderRadius`.

## Иконки, обложки, визуализатор и логотип

- Иконки: все значки приложения из `assets/Icons/<ключ>.svg` этой системы (положить в `assets/icons/` проекта) и показывать через `flutter_svg` с `ColorFilter.mode(color, BlendMode.srcIn)`. Реестр `DnDiscIcons` (`Map<String, String>` ключ → путь) рядом с темой; `Icons.*_rounded` заменить. В таблицу звуков и слоёв добавить текстовое поле `icon` (миграция, по умолчанию `bolt` для SFX и `waves` для эмбиентов); неизвестный ключ показывает значок по умолчанию.
- Размеры: 24 в плитке SFX, 22 в кнопке эмбиента, 20 в навигации и кнопках, 16 в строках. Цвет `text-muted`, у играющего звука и включённого слоя `primary`.
- Обложки: `assets/Covers/<ключ>.svg` (1600×400, `BoxFit.cover`), реестр `SceneCovers`. Колонка `cover` (nullable) в таблице сцен: ключ набора; своя картинка пользователя хранится как раньше и приоритетнее. `SceneCoverService.pickRandom()` вызывается при создании сцены и сохраняет ключ; существующим сценам без картинки ключ назначается при миграции по хэшу id.
- Визуализатор: виджет `EqualizerBars(active, bars, height, levels)` на одном `AnimationController`; если `AudioEngineService` отдаёт амплитуду, передаём `levels`, иначе имитация. При `MediaQuery.disableAnimations` полосы статичны.
- Логотип: `assets/Logo/logo-mark.svg` (и `logo-mark-light.svg` для светлых тем) в шапке и на экране «О программе», виджет `DnDiscLogo(size, wordmark)`; значок приложения для платформ собрать из `assets/Logo/app-icon.svg`.

## Формы, слои и экраны

- Поля: одна `InputDecorationTheme` на всё приложение: заливка `surface-raised`, `OutlineInputBorder` радиус 8 цветом `border-strong`, при ошибке `danger`, фокус кольцом `focus-ring` (обёртка `Focus` + `DecoratedBox`), высота 40, отступы 12. `TextField`, `DropdownButtonFormField` и поиск используют её без локальных переопределений.
- `Checkbox`: `CheckboxThemeData` с `primary`/`on-primary`, радиус 4, обводка `border-strong` 1.5.
- Диалоги: `showDialog` с `barrierColor` = `bg` 72%, `Dialog` с `surface`, рамкой `border`, радиус 12, ширина 440/560/720. Подвал отдельной строкой с границей сверху, главное действие справа. Удаление подтверждается диалогом `sm` с кнопкой `danger`.
- Меню: `MenuAnchor` / `PopupMenuButton` с `surface-raised`, радиус 8, высота пункта 40; удаление последним через разделитель.
- Уведомления: один `ToastController` (overlay внизу справа над микшером), не больше трёх, 5 секунд для нейтральных и успешных; ошибки до закрытия. `SnackBar` не используем.
- Подсказки: `TooltipThemeData` — фон `text`, текст `bg`, 12px, `waitDuration` 400ms.
- Слои и движение: константы `Durations` (120/200/320/400 ms), `Curves` (`easing-standard` = `Cubic(0.2, 0, 0, 1)`, `easing-exit` = `Cubic(0.4, 0, 1, 1)`) и порядок слоёв из токенов `zIndex` (в Flutter — порядок оверлеев).
- Медиатека: строка `TrackRow` вместо `ListTile` с цветными кружками; путь к файлу только в `Tooltip`. Каталог: `CatalogCard` в `GridView` с `maxCrossAxisExtent` 320. Настройки: `ThemeCard` в `Wrap`, таблица клавиш из `ShortcutRow`.

## Редактор темы

- Пользователь задаёт 8 цветов: `bg`, `surface`, `text`, `primary` и четыре `intensity-*`. Остальные вычисляются в OKLCH от `surface` и `primary`:
  - `surface-raised` = `surface` светлее на 0.04 L (тёмная тема) или темнее на 0.02 L (светлая); `surface-hover` = на 0.08 / 0.05;
  - `border` = `surface` ±0.10 L; `border-strong` подбирается до контраста 3:1 к `surface`;
  - `text-muted` = смесь `text` и `surface` 65/35, затем подбор до 4.5:1 к `surface-hover`; `text-disabled` 40/60;
  - `primary-hover` = `primary` ±0.06 L; `primary-subtle` = 18% `primary` поверх `surface` (тёмная) или 10% (светлая);
  - `on-primary` = чёрный или белый, у кого контраст к `primary` выше; `focus-ring` = `primary`, осветлённый или затемнённый до 3:1 к `bg`, `surface`, `surface-raised`, `surface-hover`;
  - `danger`, `success` берутся из ближайшего пресета (тёмного или светлого).
- Тёмная или светлая тема определяется по светлоте `bg` (L < 0.5 — тёмная).
- Справа в редакторе живой предпросмотр: шапка сцены, строка слоя, плитка SFX, кнопки. Под ним список проверок контраста: каждая пара «текст на фоне» с числом и пометкой; пары ниже порога подсвечены `danger`, рядом кнопка «Fix», которая сдвигает светлоту, пока порог не выполнен. Сохранять тему с предупреждениями можно.
- Пресеты (Deep Dark, Clean Light, Ancient Parchment) заданы вручную, а не формулой; формула нужна только для пользовательских тем.

## Порядок работ

1. Токены и `toThemeData()`, миграция БД, проверка контраста пресетов тестами.
2. Нижний микшер и верхняя панель; убрать громкости из карточек; кнопку, действие и клавишу Panic Stop (Esc) удалить, они в приложении больше не нужны.
3. Шапка сцены и переключатель интенсивности; убрать дубль из Music.
4. Строка Ambient, плитка SFX, строка сцены; реестр значков и поле `icon` в БД; обложки и `EqualizerBars`.
5. Навигационный рейл, затем экраны Library, Catalog, Settings по доскам дизайн-проекта; поля, диалоги, меню, уведомления и редактор темы.
