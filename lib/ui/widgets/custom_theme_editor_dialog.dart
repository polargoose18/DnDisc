import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';

class CustomThemeEditorDialog extends StatefulWidget {
  final CustomThemeModel? initialTheme;

  const CustomThemeEditorDialog({super.key, this.initialTheme});

  @override
  State<CustomThemeEditorDialog> createState() => _CustomThemeEditorDialogState();
}

class _CustomThemeEditorDialogState extends State<CustomThemeEditorDialog> {
  late TextEditingController _nameController;
  late bool _isDark;
  late Color _primary;
  late Color _secondary;
  late Color _background;
  late Color _surface;
  late Color _card;
  late Color _accent;
  late Color _textPrimary;
  late Color _textSecondary;
  late Color _duckingBadge;
  late Color _battleIntensity;
  late Color _bossIntensity;

  final _formKey = GlobalKey<FormState>();

  final List<Color> _swatchPalette = const [
    Color(0xFF7C4DFF), // Purple
    Color(0xFF2563EB), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFE11D48), // Crimson
    Color(0xFFD4A373), // Ochre
    Color(0xFFFF9800), // Orange
    Color(0xFF00E5FF), // Cyan
    Color(0xFF9333EA), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF64748B), // Slate
    Color(0xFF121218), // Dark
    Color(0xFF181824), // Surface dark
    Color(0xFF1E1E2A), // Card dark
    Color(0xFF091E16), // Dark emerald
    Color(0xFF140B0E), // Dark crimson
    Color(0xFF1C1917), // Dark parchment
    Color(0xFFF8FAFC), // Light bg
    Color(0xFFFFFFFF), // White
    Color(0xFFB0B0C0), // Muted text
    Color(0xFFFAEDCD), // Warm text
  ];

  @override
  void initState() {
    super.initState();
    final base = widget.initialTheme ?? AppThemes.deepDark;
    _nameController = TextEditingController(
      text: widget.initialTheme != null ? widget.initialTheme!.name : 'New Theme',
    );
    _isDark = base.isDark;
    _primary = base.primary;
    _secondary = base.secondary;
    _background = base.background;
    _surface = base.surface;
    _card = base.card;
    _accent = base.accent;
    _textPrimary = base.textPrimary;
    _textSecondary = base.textSecondary;
    _duckingBadge = base.duckingBadge;
    _battleIntensity = base.battleIntensity;
    _bossIntensity = base.bossIntensity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPresetTemplate(CustomThemeModel preset) {
    setState(() {
      _isDark = preset.isDark;
      _primary = preset.primary;
      _secondary = preset.secondary;
      _background = preset.background;
      _surface = preset.surface;
      _card = preset.card;
      _accent = preset.accent;
      _textPrimary = preset.textPrimary;
      _textSecondary = preset.textSecondary;
      _duckingBadge = preset.duckingBadge;
      _battleIntensity = preset.battleIntensity;
      _bossIntensity = preset.bossIntensity;
    });
  }

  void _pickColor(String title, Color currentColor, ValueChanged<Color> onSelected) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E28),
          title: Text(l10n?.colorPickTitle(title) ?? 'Color Choice: $title', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _swatchPalette.map((c) {
                final isSelected = c.toARGB32() == currentColor.toARGB32();
                return GestureDetector(
                  onTap: () {
                    onSelected(c);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _primary,
                      child: const Icon(Icons.palette_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.initialTheme == null
                            ? (l10n?.createCustomThemeTitle ?? 'Create Custom Theme')
                            : (l10n?.editCustomThemeTitle ?? 'Edit Theme'),
                        style: TextStyle(color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: _textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name & Template Preset Selector
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: _textPrimary),
                        decoration: InputDecoration(
                          labelText: l10n?.themeNameLabel ?? 'Theme Name',
                          labelStyle: TextStyle(color: _textSecondary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _primary),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? (l10n?.themeNameRequired ?? 'Please specify theme name') : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PopupMenuButton<CustomThemeModel>(
                        tooltip: l10n?.baseOnPresetTooltip ?? 'Use preset as template',
                        onSelected: _applyPresetTemplate,
                        itemBuilder: (ctx) => AppThemes.presets.map((preset) {
                          return PopupMenuItem(
                            value: preset,
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: preset.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(preset.name),
                              ],
                            ),
                          );
                        }).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: _textSecondary.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n?.baseOnPreset ?? 'Base on Preset', style: TextStyle(color: _textPrimary, fontSize: 13)),
                              Icon(Icons.arrow_drop_down, color: _textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Preview Mockup Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n?.themePreviewTitle ?? 'Theme Preview',
                            style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _duckingBadge.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _duckingBadge),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volume_down, size: 14, color: _duckingBadge),
                                const SizedBox(width: 4),
                                Text(l10n?.duckingActive ?? 'Ducking Active', style: TextStyle(color: _duckingBadge, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: _primary.withValues(alpha: 0.15), blurRadius: 6, spreadRadius: 1),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text.isEmpty ? (l10n?.cardExampleTitle ?? 'Sample Card') : _nameController.text,
                                  style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n?.cardExampleDesc ?? 'Scene or track description in the selected color palette.',
                                  style: TextStyle(color: _textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    _buildIntensityChip('Calm', _secondary, true),
                                    _buildIntensityChip('Battle', _battleIntensity, false),
                                    _buildIntensityChip('Boss', _bossIntensity, false),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                      label: const Text('Play', style: TextStyle(fontSize: 12)),
                                      onPressed: () {},
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          activeTrackColor: _primary,
                                          thumbColor: _primary,
                                          inactiveTrackColor: _primary.withValues(alpha: 0.2),
                                        ),
                                        child: Slider(value: 0.65, onChanged: (_) {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 20),

                // Color Configuration Grid
                Text(
                  l10n?.colorPaletteConfig ?? 'Color Palette Settings',
                  style: TextStyle(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildColorButton('Primary', _primary, (c) => setState(() => _primary = c)),
                    _buildColorButton('Secondary', _secondary, (c) => setState(() => _secondary = c)),
                    _buildColorButton('Background', _background, (c) => setState(() => _background = c)),
                    _buildColorButton('Surface', _surface, (c) => setState(() => _surface = c)),
                    _buildColorButton('Card', _card, (c) => setState(() => _card = c)),
                    _buildColorButton('Accent', _accent, (c) => setState(() => _accent = c)),
                    _buildColorButton('Text Primary', _textPrimary, (c) => setState(() => _textPrimary = c)),
                    _buildColorButton('Text Secondary', _textSecondary, (c) => setState(() => _textSecondary = c)),
                    _buildColorButton('Ducking Badge', _duckingBadge, (c) => setState(() => _duckingBadge = c)),
                    _buildColorButton('Battle Intensity', _battleIntensity, (c) => setState(() => _battleIntensity = c)),
                    _buildColorButton('Boss Intensity', _bossIntensity, (c) => setState(() => _bossIntensity = c)),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n?.cancel ?? 'Cancel', style: TextStyle(color: _textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l10n?.saveThemeBtn ?? 'Save Theme'),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          final newTheme = CustomThemeModel(
                            id: widget.initialTheme?.id ?? const Uuid().v4(),
                            name: _nameController.text.trim(),
                            isDark: _isDark,
                            primaryColor: _primary.toARGB32(),
                            secondaryColor: _secondary.toARGB32(),
                            backgroundColor: _background.toARGB32(),
                            surfaceColor: _surface.toARGB32(),
                            cardColor: _card.toARGB32(),
                            accentColor: _accent.toARGB32(),
                            textPrimaryColor: _textPrimary.toARGB32(),
                            textSecondaryColor: _textSecondary.toARGB32(),
                            duckingBadgeColor: _duckingBadge.toARGB32(),
                            battleIntensityColor: _battleIntensity.toARGB32(),
                            bossIntensityColor: _bossIntensity.toARGB32(),
                            isBuiltIn: false,
                            createdAt: widget.initialTheme?.createdAt ?? DateTime.now(),
                          );
                          Navigator.of(context).pop(newTheme);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityChip(String label, Color color, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildColorButton(String label, Color color, ValueChanged<Color> onChanged) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () => _pickColor(label, color, onChanged),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _textSecondary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: _textPrimary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
