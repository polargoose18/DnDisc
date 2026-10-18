import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/settings_service.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../l10n/app_localizations.dart';
import '../../services/shortcut_service.dart';
import '../../theme/app_themes.dart';
import '../../theme/ds_theme.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_panel.dart';
import '../design/ds_slider.dart';
import '../design/toast.dart';
import '../shell/shell_scope.dart';
import '../shell/top_bar.dart';
import '../view_models/theme_view_model.dart';
import '../widgets/custom_theme_editor_dialog.dart';
import '../widgets/dndisc_logo.dart';
import '../widgets/theme_card.dart';

/// Settings: one column up to 880px wide with the panels Appearance, Audio,
/// Storage, Shortcuts and About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editTheme(BuildContext context, ThemeViewModel? vm, {CustomThemeModel? theme}) async {
    final result = await showDsDialog<CustomThemeModel>(
      context: context,
      builder: (_) => CustomThemeEditorDialog(initialTheme: theme),
    );
    if (result != null) await vm?.saveCustomTheme(result);
  }

  Future<void> _deleteTheme(BuildContext context, ThemeViewModel? vm, CustomThemeModel theme) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteThemeTitle,
      message: l10n.deleteThemeMessage(theme.name),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      closeLabel: l10n.close,
    );
    if (confirmed) await vm?.deleteCustomTheme(theme.id);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final themes = context.watch<ThemeViewModel?>();
    final shortcuts = context.watch<ShortcutService?>();
    final toasts = context.read<ToastController?>();

    String seconds(int ms) => '${(ms / 1000).toStringAsFixed(1)} ${l10n.seconds}';
    String millis(int ms) => '$ms ${l10n.milliseconds}';

    final presets = themes?.builtInPresets ?? AppThemes.presets;
    final customs = themes?.customThemes ?? const <CustomThemeModel>[];

    final themeCards = <Widget>[
      for (final theme in [...presets, ...customs])
        ThemeCard(
          key: ValueKey('theme_card_${theme.id}'),
          theme: theme,
          selected: themes?.activeThemeId == theme.id,
          onSelect: () => themes?.selectTheme(theme.id),
          onEdit: () => _editTheme(context, themes, theme: theme),
          onDuplicate: () => themes?.duplicateCustomTheme(theme.id),
          onDelete: () => _deleteTheme(context, themes, theme),
        ),
      ThemeAddCard(key: const ValueKey('create_theme_button'), onTap: () => _editTheme(context, themes)),
    ];

    final appearance = DsPanel(
      title: l10n.appearanceTitle,
      icon: 'palette',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.appearanceDesc, style: ds.caption),
          const SizedBox(height: Spacing.s4),
          LayoutBuilder(
            builder: (context, c) {
              const gap = Spacing.s3;
              final columns = ((c.maxWidth + gap) / (Sizes.themeCardMin + gap)).floor().clamp(1, 5);
              final width = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final card in themeCards)
                    SizedBox(width: width, height: Sizes.themePreviewHeight + Sizes.targetMin + Spacing.s3, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.s5),
          SizedBox(
            width: Sizes.dialogSm,
            child: DsSelect<String>(
              key: const ValueKey('language_selector_dropdown'),
              label: l10n.language,
              value: settings.appLanguage,
              options: [
                DsOption('system', l10n.languageSystem),
                DsOption('ru', l10n.languageRussian),
                DsOption('en', l10n.languageEnglish),
              ],
              onChanged: (v) {
                if (v != null) settings.setAppLanguage(v);
              },
            ),
          ),
        ],
      ),
    );

    final audio = DsPanel(
      title: l10n.audioTitle,
      icon: 'volume',
      trailing: DsButton(
        key: const ValueKey('reset_settings_button'),
        label: l10n.resetDefaultsBtn,
        icon: 'refresh',
        onPressed: () {
          settings.resetToDefaults();
          toasts?.show(title: l10n.toastSettingsReset);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SliderSetting(
            title: l10n.musicFadeTitle,
            value: settings.musicFadeMs.toDouble(),
            max: 5000,
            text: seconds(settings.musicFadeMs),
            onChanged: (v) => settings.setMusicFadeMs(v.round()),
            sliderKey: const ValueKey('music_fade_slider'),
          ),
          _SliderSetting(
            title: l10n.ambientFadeTitle,
            value: settings.ambientFadeMs.toDouble(),
            max: 5000,
            text: seconds(settings.ambientFadeMs),
            onChanged: (v) => settings.setAmbientFadeMs(v.round()),
            sliderKey: const ValueKey('ambient_fade_slider'),
          ),
          const SizedBox(height: Spacing.s3),
          Text(l10n.duckingTitle, style: ds.label),
          Text(l10n.duckingDesc, style: ds.caption),
          const SizedBox(height: Spacing.s2),
          _SliderSetting(
            title: l10n.duckAttackTitle,
            description: l10n.duckAttackSubtitle,
            value: settings.duckAttackMs.toDouble(),
            max: 2000,
            text: millis(settings.duckAttackMs),
            onChanged: (v) => settings.setDuckAttackMs(v.round()),
            sliderKey: const ValueKey('duck_attack_slider'),
          ),
          _SliderSetting(
            title: l10n.duckReleaseTitle,
            description: l10n.duckReleaseSubtitle,
            value: settings.duckReleaseMs.toDouble(),
            max: 5000,
            text: millis(settings.duckReleaseMs),
            onChanged: (v) => settings.setDuckReleaseMs(v.round()),
            sliderKey: const ValueKey('duck_release_slider'),
          ),
          _SliderSetting(
            title: l10n.duckMultiplierTitle,
            description: l10n.duckMultiplierSubtitle,
            value: settings.duckMultiplier * 100,
            max: 100,
            text: '${(settings.duckMultiplier * 100).round()}%',
            onChanged: (v) => settings.setDuckMultiplier(v / 100),
            sliderKey: const ValueKey('duck_depth_slider'),
          ),
        ],
      ),
    );

    final hasCustomDir = settings.customDownloadDirectory != null;
    final storage = DsPanel(
      title: l10n.storageTitle,
      icon: 'download',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.catalogStorageDesc, style: ds.caption),
          const SizedBox(height: Spacing.s3),
          Container(
            padding: const EdgeInsets.all(Spacing.s3),
            decoration: BoxDecoration(
              color: ds.surfaceRaised,
              borderRadius: Radii.mdAll,
              border: Border.all(color: ds.border, width: Sizes.borderWidth),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hasCustomDir ? l10n.customDirectory : l10n.defaultDirectory, style: ds.label),
                      Text(settings.customDownloadDirectory ?? l10n.defaultStoragePath, style: ds.code),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.s3),
                if (hasCustomDir)
                  DsButton.ghost(
                    key: const ValueKey('reset_download_dir_button'),
                    icon: 'refresh',
                    iconOnly: true,
                    label: l10n.resetDefaultDirTooltip,
                    onPressed: () {
                      settings.resetCustomDownloadDirectory();
                      toasts?.show(title: l10n.toastStoragePathReset);
                    },
                  ),
                DsButton(
                  key: const ValueKey('select_download_dir_button'),
                  label: l10n.chooseFolderBtn,
                  icon: 'edit',
                  onPressed: () async {
                    final dir = await FilePicker.platform.getDirectoryPath(dialogTitle: l10n.chooseFolderDialogTitle);
                    if (dir != null && dir.isNotEmpty) {
                      settings.setCustomDownloadDirectory(dir);
                      toasts?.success(l10n.toastStoragePathUpdated, message: dir);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final shortcutsPanel = DsPanel(
      title: l10n.hotkeysTitle,
      icon: 'keyboard',
      trailing: DsSwitch(
        key: const ValueKey('shortcuts_switch'),
        value: shortcuts?.isEnabled ?? true,
        onChanged: shortcuts?.setEnabled,
        label: l10n.hotkeysTitle,
      ),
      child: _ShortcutsTable(shortcuts: shortcuts),
    );

    final about = DsPanel(
      child: Wrap(
        spacing: Spacing.s4,
        runSpacing: Spacing.s3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const DnDiscLogo(size: Sizes.targetMin, wordmark: true),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.dialogSm),
            child: Text('${l10n.appVersion} · ${l10n.aboutDesc}', style: ds.caption),
          ),
          DsButton(
            key: const ValueKey('open_logs_button'),
            label: l10n.openLogs,
            icon: 'terminal',
            onPressed: ShellScope.maybeOf(context)?.openLogs ?? () => Scaffold.maybeOf(context)?.openEndDrawer(),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Palette.transparent,
      body: Column(
        children: [
          TopBar(title: l10n.tabSettings, navigationLabel: l10n.openNavigation),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.s4),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Sizes.settingsMaxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      appearance,
                      const SizedBox(height: Spacing.s4),
                      audio,
                      const SizedBox(height: Spacing.s4),
                      storage,
                      const SizedBox(height: Spacing.s4),
                      shortcutsPanel,
                      const SizedBox(height: Spacing.s4),
                      about,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Title, optional description and a slider with its value on the right.
class _SliderSetting extends StatelessWidget {
  final String title;
  final String? description;
  final double value;
  final double max;
  final String text;
  final ValueChanged<double> onChanged;
  final Key? sliderKey;

  const _SliderSetting({
    required this.title,
    this.description,
    required this.value,
    required this.max,
    required this.text,
    required this.onChanged,
    this.sliderKey,
  });

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s1),
      child: LayoutBuilder(
        builder: (context, c) {
          final labels = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ds.body),
              if (description != null) Text(description!, style: ds.caption),
            ],
          );
          final slider = SizedBox(
            width: c.maxWidth >= Sizes.dialogMd ? Sizes.dialogSm / 2 + Spacing.s7 : null,
            child: DsSlider(
              key: sliderKey,
              value: value.clamp(0, max),
              max: max,
              onChanged: onChanged,
              semanticLabel: title,
              format: (_) => text,
              valueWidth: Sizes.sliderValueWide,
            ),
          );
          if (c.maxWidth >= Sizes.dialogMd) {
            return Row(children: [Expanded(child: labels), const SizedBox(width: Spacing.s4), slider]);
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [labels, slider]);
        },
      ),
    );
  }
}

/// Shortcut rows in the groups Playback, Intensity and SFX slots.
class _ShortcutsTable extends StatelessWidget {
  final ShortcutService? shortcuts;

  const _ShortcutsTable({required this.shortcuts});

  static const _playback = {AppShortcutAction.playPauseMusic, AppShortcutAction.masterMute, AppShortcutAction.toggleFullscreen};
  static const _intensity = {
    AppShortcutAction.intensityCalm,
    AppShortcutAction.intensitySuspense,
    AppShortcutAction.intensityBattle,
    AppShortcutAction.intensityBoss,
  };

  List<String> _keys(String display) => display.split(' / ');

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final definitions = shortcuts?.allDefinitions ?? const <ShortcutDefinition>[];

    Widget group(String title, List<Widget> rows) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: Spacing.s4, bottom: Spacing.s1),
              child: Text(title.toUpperCase(), style: ds.caption),
            ),
            ...rows,
          ],
        );

    List<Widget> rowsFor(Set<AppShortcutAction> actions) {
      final defs = definitions.where((d) => actions.contains(d.action)).toList();
      return [
        for (final (i, d) in defs.indexed)
          ShortcutRow(
            action: d.getLocalizedTitle(l10n),
            description: _playback.contains(d.action) ? d.getLocalizedDescription(l10n) : null,
            keys: _keys(d.keyDisplay),
            last: i == defs.length - 1,
          ),
      ];
    }

    final sfx = definitions.where((d) => d.action == AppShortcutAction.sfx1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.hotkeysSubtitle, style: ds.caption),
        group(l10n.shortcutGroupPlayback, rowsFor(_playback)),
        group(l10n.shortcutGroupIntensity, rowsFor(_intensity)),
        if (sfx.isNotEmpty)
          group(l10n.shortcutGroupSfx, [
            ShortcutRow(
              action: sfx.first.getLocalizedTitle(l10n),
              description: l10n.shortcutSfxSlotsDesc,
              keys: _keys(sfx.first.keyDisplay),
              last: true,
            ),
          ]),
      ],
    );
  }
}
