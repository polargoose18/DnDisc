import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../services/settings_service.dart';
import '../../services/preset_service.dart';
import '../../services/media_library_service.dart';
import '../../services/scene_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final mediaLibrary = context.watch<MediaLibraryService>();
    final sceneService = context.watch<SceneService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.tune_rounded, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Настройки звукового движка',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Плавные переходы, параметры приглушения и управление пресетами',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 1: Fade Engine Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, color: Colors.deepPurpleAccent),
                          SizedBox(width: 8),
                          Text(
                            'Плавные переходы (Fade Engine)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Music Fade
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Длительность нарастания/затухания музыки'),
                        subtitle: Text('${settings.musicFadeMs} мс (${(settings.musicFadeMs / 1000).toStringAsFixed(1)} сек)'),
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
                        title: const Text('Длительность плавного включения/выключения эмбиента'),
                        subtitle: Text('${settings.ambientFadeMs} мс (${(settings.ambientFadeMs / 1000).toStringAsFixed(1)} сек)'),
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

              // Section 2: Ducking Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volume_down_rounded, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text(
                            'Авто-приглушение музыки при SFX (Ducking)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Duck Attack
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Время атаки (Duck Attack Time)'),
                        subtitle: Text('${settings.duckAttackMs} мс — скорость затухания музыки при ударе SFX'),
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
                        title: const Text('Время восстановления (Duck Release Time)'),
                        subtitle: Text('${settings.duckReleaseMs} мс — скорость возврата музыки на полную громкость'),
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
                        title: const Text('Глубина приглушения (Ducking Depth)'),
                        subtitle: Text('${(settings.duckMultiplier * 100).toInt()}% от исходной громкости музыки'),
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

              // Section 3: Preset Packs Import / Export
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.archive_rounded, color: Colors.tealAccent),
                          SizedBox(width: 8),
                          Text(
                            'Пакеты Пресетов (ZIP Архивы)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Экспортируйте созданные сцены и аудиодорожки в единый архив для обмена с другими мастерами или импортируйте готовые пакеты приключений.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_download_rounded),
                            label: const Text('Импорт пресета (ZIP)'),
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
                                  await sceneService.loadScenes(force: true);

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
                            label: const Text('Экспорт пресета в ZIP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F51B5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () async {
                              final titleController = TextEditingController(text: 'Мой TTRPG Пресет');
                              final descController = TextEditingController(text: 'Набор сцен и звуков для партии');

                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E2C),
                                  title: const Text('Экспорт пресета'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: titleController,
                                        decoration: const InputDecoration(labelText: 'Название пака'),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: descController,
                                        decoration: const InputDecoration(labelText: 'Описание пака'),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Отмена'),
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
                                    scenes: sceneService.scenes,
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
              // Section 4: Interface Options
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.display_settings_rounded, color: Colors.amberAccent),
                          SizedBox(width: 8),
                          Text(
                            'Интерфейс и панель управления',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Отображать иконку консоли логов'),
                        subtitle: const Text('Показывать кнопку быстрого открытия консоли логов в верхней панели мастера'),
                        value: settings.showLogConsoleIcon,
                        onChanged: (val) => settings.setShowLogConsoleIcon(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section 5: Defaults
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.restore_rounded, color: Colors.grey),
                  label: const Text('Сбросить все настройки по умолчанию', style: TextStyle(color: Colors.grey)),
                  onPressed: () {
                    settings.resetToDefaults();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Настройки звукового движка сброшены.')),
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
}
