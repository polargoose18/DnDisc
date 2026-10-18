import '../../theme/ds_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../data/services/settings_service.dart';
import '../../services/shortcut_service.dart';
import '../../ui/view_models/theme_view_model.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';
import '../widgets/custom_theme_editor_dialog.dart';
import '../widgets/dndisc_logo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final themeViewModel = context.watch<ThemeViewModel?>();
    final shortcutService = context.watch<ShortcutService?>();
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
                              l10n?.settingsTitle ?? 'Audio Engine Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: activeTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.settingsSubtitle ?? 'Themes, shortcuts, audio engine and preset management',
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
                            l10n?.fadeEngineTitle ?? 'Fade Engine',
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
                        title: Text(l10n?.musicFadeTitle ?? 'Music fade in/out duration', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.musicFadeMs} ${l10n?.milliseconds ?? 'ms'} (${(settings.musicFadeMs / 1000).toStringAsFixed(1)} ${l10n?.seconds ?? 's'})', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.musicFadeMs.toDouble(),
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            label: '${settings.musicFadeMs} ${l10n?.milliseconds ?? 'ms'}',
                            onChanged: (val) => settings.setMusicFadeMs(val.toInt()),
                          ),
                        ),
                      ),

                      // Ambient Fade
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.ambientFadeTitle ?? 'Ambient fade in/out duration', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.ambientFadeMs} ${l10n?.milliseconds ?? 'ms'} (${(settings.ambientFadeMs / 1000).toStringAsFixed(1)} ${l10n?.seconds ?? 's'})', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.ambientFadeMs.toDouble(),
                            min: 0,
                            max: 5000,
                            divisions: 50,
                            label: '${settings.ambientFadeMs} ${l10n?.milliseconds ?? 'ms'}',
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
                          Icon(Icons.volume_down_rounded, color: activeTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.duckingTitle ?? 'Auto-ducking music during SFX (Ducking)',
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
                        title: Text(l10n?.duckAttackTitle ?? 'Duck Attack Time', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.duckAttackMs} ${l10n?.milliseconds ?? 'ms'} — ${l10n?.duckAttackSubtitle ?? 'music fade-down speed when SFX triggers'}', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.duckAttackMs.toDouble(),
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: '${settings.duckAttackMs} ${l10n?.milliseconds ?? 'ms'}',
                            onChanged: (val) => settings.setDuckAttackMs(val.toInt()),
                          ),
                        ),
                      ),

                      // Duck Release
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.duckReleaseTitle ?? 'Duck Release Time', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${settings.duckReleaseMs} ${l10n?.milliseconds ?? 'ms'} — ${l10n?.duckReleaseSubtitle ?? 'music fade-up speed to full volume'}', style: TextStyle(color: activeTheme.textSecondary)),
                        trailing: SizedBox(
                          width: 250,
                          child: Slider(
                            value: settings.duckReleaseMs.toDouble(),
                            min: 200,
                            max: 4000,
                            divisions: 38,
                            label: '${settings.duckReleaseMs} ${l10n?.milliseconds ?? 'ms'}',
                            onChanged: (val) => settings.setDuckReleaseMs(val.toInt()),
                          ),
                        ),
                      ),

                      // Duck Multiplier
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n?.duckMultiplierTitle ?? 'Ducking Depth', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text('${(settings.duckMultiplier * 100).toInt()}% ${l10n?.duckMultiplierSubtitle ?? 'of original music volume'}', style: TextStyle(color: activeTheme.textSecondary)),
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

              // Section 5: Catalog & Download Directory Settings
              Card(
                key: const ValueKey('catalog_storage_settings_card'),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_special_rounded, color: activeTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.catalogStorageTitle ?? 'Catalog & Audio File Storage',
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
                        l10n?.catalogStorageDesc ?? 'Folder for downloading and unpacking audio files from online repository catalog:',
                        style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: activeTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activeTheme.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              settings.customDownloadDirectory != null
                                  ? Icons.folder_open_rounded
                                  : Icons.folder_shared_rounded,
                              color: settings.customDownloadDirectory != null
                                  ? activeTheme.primary
                                  : activeTheme.textSecondary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.customDownloadDirectory != null
                                        ? (l10n?.customDirectory ?? 'Custom Directory')
                                        : (l10n?.defaultDirectory ?? 'Default Directory'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: settings.customDownloadDirectory != null
                                          ? activeTheme.primary
                                          : activeTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    settings.customDownloadDirectory ?? (l10n?.defaultStoragePath ?? 'Default: Documents/audio_library'),
                                    key: const ValueKey('download_directory_display_path'),
                                    style: TextStyle(fontFamily: DsTheme.monoFamily, 
                                      color: activeTheme.textPrimary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (settings.customDownloadDirectory != null)
                              IconButton(
                                key: const ValueKey('reset_download_dir_button'),
                                icon: const Icon(Icons.restore_rounded, size: 20),
                                tooltip: l10n?.resetDefaultDirTooltip ?? 'Reset to default',
                                onPressed: () {
                                  settings.resetCustomDownloadDirectory();
                                  _showNotification(context, l10n?.storagePathReset ?? 'Download path reset to default.');
                                },
                              ),
                            ElevatedButton.icon(
                              key: const ValueKey('select_download_dir_button'),
                              icon: const Icon(Icons.folder_open_rounded, size: 18),
                              label: Text(l10n?.chooseFolderBtn ?? 'Choose Folder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activeTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: () async {
                                final selectedDirectory = await FilePicker.platform.getDirectoryPath(
                                  dialogTitle: l10n?.chooseFolderDialogTitle ?? 'Select folder to store catalog audio files',
                                );
                                if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
                                  settings.setCustomDownloadDirectory(selectedDirectory);
                                  if (context.mounted) {
                                    _showNotification(context, l10n?.storagePathUpdated(selectedDirectory) ?? 'Catalog download directory updated: $selectedDirectory');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                            l10n?.language ?? 'Interface Language',
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
                            child: Text(l10n?.languageSystem ?? 'System', style: TextStyle(color: activeTheme.textPrimary)),
                          ),
                          DropdownMenuItem(
                            value: 'ru',
                            child: Text(l10n?.languageRussian ?? 'Russian', style: TextStyle(color: activeTheme.textPrimary)),
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
                          Icon(Icons.display_settings_rounded, color: activeTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.interfaceTitle ?? 'Interface & Control Panel',
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
                        title: Text(l10n?.showLogConsoleTitle ?? 'Show log console icon', style: TextStyle(color: activeTheme.textPrimary)),
                        subtitle: Text(
                          l10n?.showLogConsoleSubtitle ?? 'Show quick toggle button for log console in top header',
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
                  label: Text(l10n?.resetDefaultsBtn ?? 'Reset all settings to defaults', style: TextStyle(color: activeTheme.textSecondary)),
                  onPressed: () {
                    settings.resetToDefaults();
                    _showNotification(context, l10n?.settingsResetToast ?? 'Audio engine settings reset.');
                  },
                ),
              ),
              const SizedBox(height: 24),

              // About DnDisc Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: activeTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: activeTheme.primary.withValues(alpha: 0.4), width: 1.0),
                        ),
                        child: const DnDiscLogo(size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n?.aboutTitle ?? 'About DnDisc',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: activeTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: activeTheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Text(
                                    l10n?.appVersion ?? 'Version 1.0.0',
                                    style: TextStyle(fontSize: 10, color: activeTheme.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n?.aboutDesc ?? 'Atmospheric audio engine, scene mixer, and soundboard player for TTRPG Game Masters.',
                              style: TextStyle(color: activeTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotification(BuildContext context, String message) {
    try {
      if (context.mounted && Scaffold.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
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
                  l10n?.themesTitle ?? 'App Themes',
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
              l10n?.builtinThemes ?? 'Built-in Presets (3 variants)',
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
                        color: isSelected
                            ? Color(preset.primaryColor)
                            : (activeTheme.isDark ? Colors.white12 : Colors.black12),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(preset.primaryColor).withValues(alpha: 0.15),
                                blurRadius: 4,
                                spreadRadius: 0,
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
                                color: Color(preset.surfaceRaisedColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Color(preset.primaryColor),
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
                            fontWeight: FontWeight.w600,
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
                        Icon(Icons.brush_rounded, size: 16, color: activeTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${l10n?.customThemes ?? "Custom Themes"} (${customThemes.length})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: activeTheme.primary,
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
                    l10n?.noCustomThemes ?? 'You don\'t have custom themes yet. Create your own theme with a custom palette!',
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
                          color: isSelected
                              ? Color(custom.primaryColor)
                              : (activeTheme.isDark ? Colors.white12 : Colors.black12),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(custom.primaryColor).withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  spreadRadius: 0,
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
                                  color: Color(custom.surfaceRaisedColor),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n?.edit ?? 'Edit',
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
                                tooltip: l10n?.duplicate ?? 'Duplicate',
                                onPressed: () async {
                                  await themeService?.duplicateCustomTheme(custom.id);
                                },
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: l10n?.delete ?? 'Delete',
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
                              fontWeight: FontWeight.w600,
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
              label: Text(l10n?.createThemeBtn ?? '+ Create new theme'),
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
        title: 'Play / Pause',
        description: 'Start or pause current music track',
        keyDisplay: 'Space',
      ),
      ShortcutDefinition(
        action: AppShortcutAction.masterMute,
        title: 'Mute',
        description: 'Quick mute or unmute master volume',
        keyDisplay: 'M',
      ),
      ShortcutDefinition(
        action: AppShortcutAction.toggleFullscreen,
        title: 'Fullscreen',
        description: 'Toggle fullscreen display mode',
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
                Icon(Icons.keyboard_rounded, color: activeTheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n?.hotkeysTitle ?? 'Centralized Shortcuts',
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
              l10n?.hotkeysSubtitle ?? 'Control soundscape during game session without distraction:',
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
                      child: Text(l10n?.actionCol ?? 'Action', style: TextStyle(fontWeight: FontWeight.bold, color: activeTheme.textPrimary, fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(l10n?.descriptionCol ?? 'Description', style: TextStyle(fontWeight: FontWeight.bold, color: activeTheme.textPrimary, fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(l10n?.keyCol ?? 'Key', style: TextStyle(fontWeight: FontWeight.bold, color: activeTheme.textPrimary, fontSize: 12)),
                    ),
                  ],
                ),
                ...shortcuts.map((sc) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(sc.getLocalizedTitle(l10n), style: TextStyle(color: activeTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Text(sc.getLocalizedDescription(l10n), style: TextStyle(color: activeTheme.textSecondary, fontSize: 11)),
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
