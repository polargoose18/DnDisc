import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/audio_track.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_themes.dart';
import '../../theme/color_math.dart' as cm;
import '../../theme/ds_theme.dart';
import '../../theme/swatches.dart';
import '../../theme/tokens.dart';
import '../design/ds_button.dart';
import '../design/ds_controls.dart';
import '../design/ds_dialog.dart';
import '../design/ds_field.dart';
import '../design/ds_icon.dart';
import '../design/ds_interactive.dart';
import '../design/ds_slider.dart';

/// Colours the user sets in the editor; everything else is derived.
class _Palette {
  int background;
  int surface;
  int text;
  int primary;
  int calm;
  int suspense;
  int battle;
  int boss;

  _Palette({
    required this.background,
    required this.surface,
    required this.text,
    required this.primary,
    required this.calm,
    required this.suspense,
    required this.battle,
    required this.boss,
  });

  factory _Palette.of(CustomThemeModel m) => _Palette(
        background: m.backgroundColor,
        surface: m.surfaceColor,
        text: m.textPrimaryColor,
        primary: m.primaryColor,
        calm: m.calmIntensityColor,
        suspense: m.suspenseIntensityColor,
        battle: m.battleIntensityColor,
        boss: m.bossIntensityColor,
      );

  CustomThemeModel derive({String id = 'editor', String name = '', DateTime? createdAt}) => CustomThemeModel.derive(
        id: id,
        name: name,
        background: background,
        surface: surface,
        text: text,
        primary: primary,
        calm: calm,
        suspense: suspense,
        battle: battle,
        boss: boss,
        createdAt: createdAt,
      );
}

/// One "colour on background" pair with its minimum contrast and a way to
/// move the colour until the minimum is met.
class _Check {
  final String label;
  final int Function(_Palette) fg;
  final int Function(_Palette) bg;
  final double min;
  final void Function(_Palette, int) apply;

  const _Check(this.label, this.fg, this.bg, this.min, this.apply);
}

/// Create or edit a custom theme: eight colours, a live preview and a
/// contrast check list. A theme with warnings can still be saved.
class CustomThemeEditorDialog extends StatefulWidget {
  final CustomThemeModel? initialTheme;

  const CustomThemeEditorDialog({super.key, this.initialTheme});

  @override
  State<CustomThemeEditorDialog> createState() => _CustomThemeEditorDialogState();
}

class _CustomThemeEditorDialogState extends State<CustomThemeEditorDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.initialTheme?.name ?? '');
  late _Palette _palette = _Palette.of(widget.initialTheme ?? AppThemes.deepDark);
  bool _nameError = false;
  double _previewVolume = 0.6;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _applyPreset(CustomThemeModel preset) => setState(() => _palette = _Palette.of(preset));

  Future<void> _pick(String title, int current, ValueChanged<int> onPicked) async {
    final picked = await showDsDialog<int>(
      context: context,
      builder: (_) => _ColorPickerDialog(title: title, initial: current),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    Navigator.of(context).pop(
      _palette.derive(
        id: widget.initialTheme?.id ?? const Uuid().v4(),
        name: name,
        createdAt: widget.initialTheme?.createdAt ?? DateTime.now(),
      ),
    );
  }

  List<_Check> _checks(AppLocalizations l10n) => [
        _Check(l10n.contrastTextBg, (p) => p.text, (p) => p.background, 4.5, (p, c) => p.text = c),
        _Check(l10n.contrastTextSurface, (p) => p.text, (p) => p.surface, 4.5, (p, c) => p.text = c),
        _Check(l10n.contrastPrimaryBg, (p) => p.primary, (p) => p.background, 4.5, (p, c) => p.primary = c),
        _Check(l10n.contrastPrimarySurface, (p) => p.primary, (p) => p.surface, 4.5, (p, c) => p.primary = c),
        for (final level in MusicIntensity.values)
          _Check(
            l10n.contrastIntensityOnSurface(level.getLocalizedName(l10n)),
            (p) => switch (level) {
                  MusicIntensity.calm => p.calm,
                  MusicIntensity.suspense => p.suspense,
                  MusicIntensity.battle => p.battle,
                  MusicIntensity.boss => p.boss,
                },
            (p) => p.surface,
            3,
            (p, c) {
              switch (level) {
                case MusicIntensity.calm:
                  p.calm = c;
                case MusicIntensity.suspense:
                  p.suspense = c;
                case MusicIntensity.battle:
                  p.battle = c;
                case MusicIntensity.boss:
                  p.boss = c;
              }
            },
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final editing = widget.initialTheme != null;
    final derived = _palette.derive(name: _name.text);
    final checks = _checks(l10n);
    final failing = checks.where((c) => cm.contrastRatio(c.fg(_palette), c.bg(_palette)) < c.min).length;

    Widget colorRow(String key, String label, int value, ValueChanged<int> onPicked) => DsInteractive(
          key: ValueKey('theme_color_$key'),
          onTap: () => _pick(label, value, onPicked),
          semanticLabel: label,
          builder: (context, s) => Container(
            constraints: const BoxConstraints(minHeight: Sizes.targetMin),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s2),
            decoration: BoxDecoration(
              color: s.hovered ? ds.surfaceHover : Palette.transparent,
              borderRadius: Radii.mdAll,
            ),
            child: Row(
              children: [
                Container(
                  width: Spacing.s5,
                  height: Spacing.s5,
                  decoration: BoxDecoration(
                    color: Color(value),
                    borderRadius: Radii.smAll,
                    border: Border.all(color: ds.borderStrong, width: Sizes.borderWidth),
                  ),
                ),
                const SizedBox(width: Spacing.s3),
                Expanded(child: Text(label, style: ds.body)),
                Text('#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}', style: ds.code),
              ],
            ),
          ),
        );

    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsTextField(
          key: const ValueKey('theme_name_field'),
          label: l10n.themeNameLabel,
          controller: _name,
          autofocus: !editing,
          error: _nameError && _name.text.trim().isEmpty ? l10n.themeNameRequired : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: Spacing.s4),
        DsSelect<String>(
          key: const ValueKey('theme_preset_select'),
          label: l10n.baseOnPreset,
          options: [for (final p in AppThemes.presets) DsOption(p.id, p.name)],
          value: null,
          placeholder: l10n.choosePreset,
          onChanged: (id) {
            if (id != null) _applyPreset(AppThemes.getPresetById(id));
          },
        ),
        const SizedBox(height: Spacing.s4),
        colorRow('background', l10n.colorNameBackground, _palette.background, (c) => _palette.background = c),
        colorRow('surface', l10n.colorNameSurface, _palette.surface, (c) => _palette.surface = c),
        colorRow('text', l10n.colorNameText, _palette.text, (c) => _palette.text = c),
        colorRow('primary', l10n.colorNamePrimary, _palette.primary, (c) => _palette.primary = c),
        colorRow('calm', l10n.intensityCalm, _palette.calm, (c) => _palette.calm = c),
        colorRow('suspense', l10n.intensitySuspense, _palette.suspense, (c) => _palette.suspense = c),
        colorRow('battle', l10n.intensityBattle, _palette.battle, (c) => _palette.battle = c),
        colorRow('boss', l10n.intensityBoss, _palette.boss, (c) => _palette.boss = c),
      ],
    );

    final preview = Theme(
      data: derived.toThemeData(),
      child: Builder(
        builder: (context) {
          final p = context.ds;
          return Container(
            padding: const EdgeInsets.all(Spacing.s4),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: Radii.lgAll,
              border: Border.all(color: p.border, width: Sizes.borderWidth),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.s3),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: Radii.mdAll,
                    border: Border.all(color: p.border, width: Sizes.borderWidth),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name.text.trim().isEmpty ? l10n.newThemeDefaultName : _name.text.trim(), style: p.title),
                      const SizedBox(height: Spacing.s3),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DsSegmentedControl<MusicIntensity>(
                          label: l10n.musicIntensityLabel,
                          compact: true,
                          value: MusicIntensity.suspense,
                          onChanged: (_) {},
                          options: [
                            for (final (i, level) in MusicIntensity.values.indexed)
                              DsSegment(id: level, label: level.getLocalizedName(l10n), color: p.intensityColor(level.name), key: '${i + 1}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.s3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.s3),
                        decoration: BoxDecoration(
                          color: p.surfaceRaised,
                          borderRadius: Radii.mdAll,
                          border: Border.all(color: p.border, width: Sizes.borderWidth),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: Sizes.targetMin,
                              height: Sizes.targetMin,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: p.primarySubtle,
                                borderRadius: Radii.mdAll,
                                border: Border.all(color: p.primary, width: Sizes.borderWidth),
                              ),
                              child: DsIcon('waves', color: p.primary),
                            ),
                            const SizedBox(width: Spacing.s3),
                            Text(l10n.ambient, style: p.body.copyWith(fontWeight: FontWeight.w500)),
                            Expanded(
                              child: DsSlider(
                                value: _previewVolume,
                                onChanged: (v) => setState(() => _previewVolume = v),
                                semanticLabel: l10n.ambient,
                                ringColor: p.surfaceRaised,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.s3),
                      Row(
                        children: [
                          Container(
                            width: Sizes.sfxTileMin,
                            height: Sizes.sfxTileMin - Spacing.s4,
                            padding: const EdgeInsets.all(Spacing.s3),
                            decoration: BoxDecoration(
                              color: p.primarySubtle,
                              borderRadius: Radii.mdAll,
                              border: Border.all(color: p.primary, width: Sizes.borderWidth),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DsIcon('bolt', size: Sizes.iconLg, color: p.primary),
                                const Spacer(),
                                Text(l10n.sfx, style: p.label),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.s3),
                      Wrap(
                        spacing: Spacing.s2,
                        runSpacing: Spacing.s2,
                        children: [
                          DsButton.primary(label: l10n.playTooltip, icon: 'play', onPressed: () {}),
                          DsButton(label: l10n.cancel, onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final checksList = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.contrastChecksTitle, style: ds.title),
        const SizedBox(height: Spacing.s2),
        for (final (index, check) in checks.indexed)
          Builder(
            builder: (context) {
              final ratio = cm.contrastRatio(check.fg(_palette), check.bg(_palette));
              final ok = ratio >= check.min;
              return Container(
                key: ValueKey('contrast_check_$index'),
                constraints: const BoxConstraints(minHeight: Sizes.targetMin),
                child: Row(
                  children: [
                    Expanded(child: Text(check.label, style: ds.body.copyWith(color: ok ? ds.text : ds.danger))),
                    Text('${ratio.toStringAsFixed(1)}:1', style: ds.tabular(ds.caption.copyWith(color: ok ? ds.textMuted : ds.danger))),
                    const SizedBox(width: Spacing.s2),
                    if (ok)
                      DsBadge(l10n.contrastOk, tone: DsTone.success)
                    else
                      DsButton.ghost(
                        key: ValueKey('contrast_fix_$index'),
                        label: l10n.contrastFix,
                        onPressed: () => setState(() {
                          final fixed = cm.adjustToContrast(
                            check.fg(_palette),
                            [check.bg(_palette)],
                            check.min,
                            lighter: derived.isDark,
                          );
                          check.apply(_palette, fixed);
                        }),
                      ),
                  ],
                ),
              );
            },
          ),
        if (failing > 0) ...[
          const SizedBox(height: Spacing.s2),
          Text(l10n.contrastWarning, style: ds.caption.copyWith(color: ds.danger)),
        ],
      ],
    );

    return DsDialog(
      title: editing ? l10n.editCustomThemeTitle : l10n.createCustomThemeTitle,
      description: l10n.themeEditorDesc,
      icon: 'palette',
      size: DsDialogSize.lg,
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(key: const ValueKey('save_theme_btn'), label: l10n.saveThemeBtn, icon: 'check', onPressed: _save),
      ],
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= Sizes.dialogMd;
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [editor, const SizedBox(height: Spacing.s5), preview, const SizedBox(height: Spacing.s5), checksList],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: editor),
              const SizedBox(width: Spacing.s5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [preview, const SizedBox(height: Spacing.s5), checksList],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Hex field and swatches for one colour.
class _ColorPickerDialog extends StatefulWidget {
  final String title;
  final int initial;

  const _ColorPickerDialog({required this.title, required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final TextEditingController _hex = TextEditingController(
    text: '#${(widget.initial & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
  );

  int? get _value {
    final text = _hex.text.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(text)) return null;
    return 0xFF000000 | int.parse(text, radix: 16);
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context)!;
    final value = _value;

    return DsDialog(
      title: l10n.colorPickTitle(widget.title),
      size: DsDialogSize.sm,
      closeLabel: l10n.close,
      actions: [
        DsButton.ghost(label: l10n.cancel, onPressed: () => Navigator.of(context).pop()),
        DsButton.primary(
          key: const ValueKey('apply_color_btn'),
          label: l10n.saveBtn,
          icon: 'check',
          onPressed: value == null ? null : () => Navigator.of(context).pop(value),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsTextField(
            key: const ValueKey('color_hex_field'),
            label: l10n.hexLabel,
            controller: _hex,
            autofocus: true,
            error: value == null ? l10n.hexInvalid : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Spacing.s4),
          Wrap(
            spacing: Spacing.s2,
            runSpacing: Spacing.s2,
            children: [
              for (final swatch in ThemeSwatches.all)
                DsInteractive(
                  onTap: () => setState(() => _hex.text = '#${(swatch & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}'),
                  semanticLabel: '#${(swatch & 0xFFFFFF).toRadixString(16)}',
                  builder: (context, s) => Container(
                    width: Sizes.targetMin,
                    height: Sizes.targetMin,
                    decoration: BoxDecoration(
                      color: Color(swatch),
                      borderRadius: Radii.mdAll,
                      border: Border.all(
                        color: value == swatch ? ds.primary : ds.borderStrong,
                        width: value == swatch ? Sizes.focusRing : Sizes.borderWidth,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
