import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';
import '../../services/shortcut_service.dart';
import '../../services/preset_service.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../ui/view_models/media_library_view_model.dart';
import '../../ui/view_models/scene_view_model.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';
import '../widgets/custom_theme_editor_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final themeViewModel = context.watch<ThemeViewModel?>();
    final shortcutService = context.watch<ShortcutService?>();
    final mediaLibrary = context.watch<MediaLibraryViewModel>();
    final sceneViewModel = context.watch<SceneViewModel>();
    final activeTheme = themeViewModel?.activeTheme ?? AppThemes.deepDark;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: activeTheme.primary,
                        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.settingsTitle ?? 'Настройки звукового движка',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: activeTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.settingsSubtitle ?? 'Темы оформления, горячие клавиши, звуковой движок и управление пресетами',
                              style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Themes & Styling (Presets + Custom Themes)
              _buildThemesSection(context, themeViewModel, activeTheme, l10n),
              const SizedBox(height: 16),

              // Section 2: Centralized Hotkeys Reference
              _buildHotkeysSection(context, shortcutService, activeTheme, l10n),
              const SizedBox(height: 16),

              // Section 3: Fade Engine Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, color: activeTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.fadeEngineTitle ?? 'Плавные переходы (Fade Engine)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Music Fade
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.musicFadeTitle ?? 'Длительность нарастания/затухания музыки', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.musicFadeMs} мс (${(settings.musicFadeMs / 1000).toStringAsFixed(1)} сек)', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.musicFadeMs.toDouble(),
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            label: '${settings.musicFadeMs} ms',
                            onChanged: (val) => settings.setMusicFadeMs(val.toInt()),
                          ),
                        ),
                      ),

                      // Ambient Fade
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.ambientFadeTitle ?? 'Длительность плавного включения/выключения эмбиента', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.ambientFadeMs} мс (${(settings.ambientFadeMs / 1000).toStringAsFixed(1)} сек)', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.ambientFadeMs.toDouble(),
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            label: '${settings.ambientFadeMs} ms',
                            onChanged: (val) => settings.setAmbientFadeMs(val.toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 4: Ducking Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_down_rounded, color: activeTheme.duckingBadge),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.duckingTitle ?? 'Авто-приглушение музыки при SFX (Ducking)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Duck Attack
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.duckAttackTitle ?? 'Время атаки (Duck Attack Time)', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.duckAttackMs} ms — ${l10n?.duckAttackSubtitle ?? 'скорость затухания музыки при ударе SFX'}', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.duckAttackMs.toDouble(),
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: '${settings.duckAttackMs} ms',
                            onChanged: (val) => settings.setDuckAttackMs(val.toInt()),
                          ),
                        ),
                      ),

                      // Duck Release
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.duckReleaseTitle ?? 'Время восстановления (Duck Release Time)', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.duckReleaseMs} ms — ${l10n?.duckReleaseSubtitle ?? 'скорость возврата музыки на полную громкость'}', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.duckReleaseMs.toDouble(),
                            min: 200,
                            max: 4000,
                            divisions: 38,
                            label: '${settings.duckReleaseMs} ms',
                            onChanged: (val) => settings.setDuckReleaseMs(val.toInt()),
                          ),
                        ),
                      ),

                      // Duck Multiplier
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.duckMultiplierTitle ?? 'Глубина приглушения (Ducking Depth)', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${(settings.duckMultiplier * 100).toInt()}% ${l10n?.duckMultiplierSubtitle ?? 'от исходной громкости музыки'}', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.duckMultiplier,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: '${(settings.duckMultiplier * 100).toInt()}%',
                            onChanged: (val) => settings.setDuckMultiplier(val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 5: Preset Packs Import / Export
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.archive_rounded, color: activeTheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.presetPacksTitle ?? 'Пакеты Пресетов (ZIP Архивы)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        l10n?.presetPacksSubtitle ?? 'Экспортируйте созданные сцены и аудиодорожки в единый архив для обмена с другими мастерами или импортируйте готовые пакеты приключений.',
                        style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_download_rounded),
                            label: Text(l10n?.importPresetBtn ?? 'Импорт пресета (ZIP)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['zip'],
                              );

                              if (result != null && result.files.single.path != null) {
                                try {
                                  final docsDir = await getApplicationDocumentsDirectory();
                                  final audioDir = p.join(docsDir.path, 'imported_audio');

                                  final presetService = PresetService();
                                  final importResult = await presetService.importPreset(
                                    zipFilePath: result.files.single.path!,
                                    destinationAudioDir: audioDir,
                                  );

                                  await mediaLibrary.loadTracks(force: true);
                                  await sceneViewModel.loadScenes(force: true);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.teal,
                                        content: Text(
                                          'Пресет «${importResult.title}» успешно импортирован! Загружено: ${importResult.importedTracks.length} треков, ${importResult.importedScenes.length} сцен.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text('Ошибка импорта пресета: $e'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_upload_rounded),
                            label: Text(l10n?.exportPresetBtn ?? 'Экспорт пресета в ZIP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () async {
                              final titleController = TextEditingController(text: 'Мой TTRPG Пресет');
                              final descController = TextEditingController(text: 'Набор сцен и звуков для партии');

                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: activeTheme.surface,
                                  title: Text('Экспорт пресета', style: TextStyle(color: activeTheme.textPrimary)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: titleController,
                                        style: TextStyle(color: activeTheme.textPrimary),
                                        decoration: InputDecoration(
                                          labelText: 'Название пака',
                                          labelStyle: TextStyle(color: activeTheme.textSecondary),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: descController,
                                        style: TextStyle(color: activeTheme.textPrimary),
                                        decoration: InputDecoration(
                                          labelText: 'Описание пака',
                                          labelStyle: TextStyle(color: activeTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: Text('Отмена', style: TextStyle(color: activeTheme.textSecondary)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Экспортировать'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  final docsDir = await getApplicationDocumentsDirectory();
                                  final sanitized = titleController.text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
                                  final outZipPath = p.join(docsDir.path, '${sanitized}_preset.zip');

                                  final presetService = PresetService();
                                  await presetService.exportPreset(
                                    exportZipPath: outZipPath,
                                    title: titleController.text.trim(),
                                    description: descController.text.trim(),
                                    scenes: sceneViewModel.scenes,
                                    tracks: mediaLibrary.tracks,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text('Пресет успешно сохранен в файл: $outZipPath'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.redAccent,
                                        content: Text('Ошибка экспорта: $e'),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 6: Language & Interface Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.language_rounded, color: activeTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.language ?? 'Язык интерфейса',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      DropdownButtonFormField<String>(
                        key: const ValueKey('language_selector_dropdown'),
                        initialValue: settings.appLanguage,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: activeTheme.surface,
                        ),
                        dropdownColor: activeTheme.surface,
                        style: TextStyle(color: activeTheme.textPrimary),
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text(l10n?.languageSystem ?? 'Системный', style: TextStyle(color: activeTheme.textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'ru',
                            child: Text(l10n?.languageRussian ?? 'Русский', style: TextStyle(color: activeTheme.textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n?.languageEnglish ?? 'English', style: TextStyle(color: activeTheme.textPrimary)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            settings.setAppLanguage(val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.display_settings_rounded, color: activeTheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.interfaceTitle ?? 'Интерфейс и панель управления',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.showLogConsoleTitle ?? 'Отображать иконку консоли логов', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text(
                          l10n?.showLogConsoleSubtitle ?? 'Показывать кнопку быстрого открытия консоли логов в верхней панели мастера',
                          style: TextStyle(color: activeTheme.textSecondary),
                        ),
                        value: settings.showLogConsoleIcon,
                        onChanged: (val) => settings.setShowLogConsoleIcon(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 7: Defaults
              Center(
                child: TextButton.icon(
                  icon: Icon(Icons.restore_rounded, color: activeTheme.textSecondary),
                  label: Text(l10n?.resetDefaultsBtn ?? 'Сбросить все настройки по умолчанию', style: TextStyle(color: activeTheme.textSecondary)),
                  onPressed: () {
                    settings.resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n?.settingsResetToast ?? 'Настройки звукового движка сброшены.')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemesSection(
    BuildContext context,
    ThemeViewModel? themeService,
    CustomThemeModel activeTheme,
    AppLocalizations? l10n,
  ) {
    final presets = themeService?.builtInPresets ?? AppThemes.presets;
    final activeThemeId = themeService?.activeThemeId ?? AppThemes.deepDarkId;
    final customThemes = themeService?.customThemes ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_rounded, color: activeTheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n?.themesTitle ?? 'Темы оформления (Themes)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: activeTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Subsection 1: Built-in Presets
            Text(
              l10n?.builtinThemes ?? 'Встроенные пресеты (5 вариантов)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: activeTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presets.map((preset) {
                final isSelected = activeThemeId == preset.id;
                return InkWell(
                  onTap: () => themeService?.selectTheme(preset.id),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 155,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(preset.surfaceColor),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Color(preset.primaryColor) : Colors.white12,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(preset.primaryColor).withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Color(preset.primaryColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Color(preset.secondaryColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Color(preset.duckingBadgeColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, size: 16, color: Color(preset.primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(preset.textPrimaryColor),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Subsection 2: Visual Divider & Custom Themes Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Divider(color: activeTheme.textSecondary.withValues(alpha: 0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.brush_rounded, size: 16, color: activeTheme.secondary),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n?.customThemes ?? "Пользовательские темы"} (${customThemes.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: activeTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: Divider(color: activeTheme.textSecondary.withValues(alpha: 0.2))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Custom Themes List or Empty State + "+ Create Theme" Button
            if (customThemes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: activeTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: activeTheme.textSecondary.withValues(alpha: 0.15)),
                ),
                child: Center(
                  child: Text(
                    l10n?.noCustomThemes ?? 'У вас пока нет кастомных тем. Создайте свою тему с уникальной палитрой цветов!',
                    style: TextStyle(color: activeTheme.textSecondary, fontSize: 12),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: customThemes.map((custom) {
                  final isSelected = activeThemeId == custom.id;
                  return InkWell(
                    onTap: () => themeService?.selectTheme(custom.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 190,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(custom.surfaceColor),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Color(custom.primaryColor) : Colors.white12,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(custom.primaryColor).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(custom.primaryColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(custom.secondaryColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n?.edit ?? 'Редактировать',
                                onPressed: () async {
                                  final edited = await showDialog<CustomThemeModel>(
                                    context: context,
                                    builder: (_) => CustomThemeEditorDialog(initialTheme: custom),
                                  );
                                  if (edited != null) {
                                    await themeService?.saveCustomTheme(edited);
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n?.duplicate ?? 'Дублировать',
                                onPressed: () async {
                                  await themeService?.duplicateCustomTheme(custom.id);
                                },
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n?.delete ?? 'Удалить',
                                onPressed: () async {
                                  await themeService?.deleteCustomTheme(custom.id);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            custom.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(custom.textPrimaryColor),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n?.createThemeBtn ?? '+ Создать новую тему'),
              style: ElevatedButton.styleFrom(
                backgroundColor: activeTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                final newTheme = await showDialog<CustomThemeModel>(
                  context: context,
                  builder: (_) => const CustomThemeEditorDialog(),
                );
                if (newTheme != null) {
                  await themeService?.saveCustomTheme(newTheme);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotkeysSection(
    BuildContext context,
    ShortcutService? shortcutService,
    CustomThemeModel activeTheme,
    AppLocalizations? l10n,
  ) {
    final shortcuts = shortcutService?.allDefinitions ?? const [
      ShortcutDefinition(
        action: AppShortcutAction.playPauseMusic,
        title: 'Воспроизведение / Пауза',
        description: 'Старт или пауза текущего музыкального трека',
        keyDisplay: 'Space',
      ),
      ShortcutDefinition(
        action: AppShortcutAction.masterMute,
        title: 'Глушение звука (Mute)',
        description: 'Быстрое глушение или включение общего звука',
        keyDisplay: 'M',
      ),
      ShortcutDefinition(
        action: AppShortcutAction.manualDucking,
        title: 'Ручной Ducking',
        description: 'Принудительное приглушение музыки на время речи',
        keyDisplay: 'D',
      ),
      ShortcutDefinition(
        action: AppShortcutAction.panicStopSfx,
        title: 'Экстренная остановка (Panic Stop)',
        description: 'Мгновенная остановка всех играющих SFX звуков',
        keyDisplay: 'Escape',
      ),
      ShortcutDefinition(
        action: AppShortcutAction.toggleFullscreen,
        title: 'Полноэкранный режим',
        description: 'Переключение отображения во весь экран',
        keyDisplay: 'F11',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.keyboard_rounded, color: activeTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  l10n?.hotkeysTitle ?? 'Централизованные горячие клавиши',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: activeTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: shortcutService?.isEnabled ?? true,
                  activeTrackColor: activeTheme.primary,
                  onChanged: (val) => shortcutService?.setEnabled(val),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              l10n?.hotkeysSubtitle ?? 'Управляйте звуковым окружением во время игровой сессии не отвлекаясь от книги правил:',
              style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),

            // Hotkeys Table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(4),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: activeTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(l10n?.actionCol ?? 'Действие', style: TextStyle(fontWeight: FontWeight.bold, color: activeTheme.textPrimary, fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(l10n?.descriptionCol ?? 'Описание', style: TextStyle(fontWeight: FontWeight.bold, color: activeTheme.textPrimary, fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(l10n?.keyCol ?? 'Клавиша', style: TextStyle(fontWeight: FontWeight.bold, color: activeTheme.textPrimary, fontSize: 12)),
                    ),
                  ],
                ),
                ...shortcuts.map((sc) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(sc.title, style: TextStyle(color: activeTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(sc.description, style: TextStyle(color: activeTheme.textSecondary, fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: activeTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: activeTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            sc.keyDisplay,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: activeTheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
