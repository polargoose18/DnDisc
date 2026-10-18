Карточка каталога: сцена, медиапак или набор из подключённого репозитория.

**Передаёшь:** `kind` (`scene`, `media`, `bundle`), `title`, `author`, `description`, `count`, `size`, `status` (`available`, `installed`, `update`, `downloading`), `progress`, `cover` / `src` / `seed`, `onAction`.

- Сверху обложка 112px (`SceneCover`; без своей картинки выбирается по названию), ниже тип со значком, название `title`, автор, описание в две строки.
- Подвал один на все состояния: доступно — размер и кнопка `secondary` «Install»; обновление — `primary` «Update»; загрузка — `ProgressBar`; установлено — «Installed» цветом `success` со значком и меню.
- Цвет типа не используется: фиолетовые и бежевые шапки заменены обложками, тип читается по значку и слову.
- Сетка карточек `repeat(auto-fill, minmax(240px, 1fr))`, зазор `space-4`.
