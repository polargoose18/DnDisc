import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/repositories/custom_theme_repository.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../theme/app_themes.dart';
import 'database_service.dart';
import '../../services/logger_service.dart';

class ThemeService extends ChangeNotifier {
  String _activeThemeId = AppThemes.deepDarkId;
  final List<CustomThemeModel> _customThemes = [];
  final CustomThemeRepository? _repository;
  final DatabaseService? _dbService;
  bool _isLoading = false;

  static const String _kActiveThemeKey = 'active_theme_id';

  ThemeService({
    DatabaseService? dbService,
    CustomThemeRepository? repository,
    String? initialThemeId,
    bool autoLoad = false,
  })  : _repository = repository ?? (dbService != null ? SqliteCustomThemeRepository(db: dbService) : null),
        _dbService = dbService,
        _activeThemeId = initialThemeId ?? AppThemes.deepDarkId {
    if (autoLoad && _repository != null) {
      loadThemes();
    }
  }

  String get activeThemeId => _activeThemeId;
  List<CustomThemeModel> get builtInPresets => AppThemes.presets;
  List<CustomThemeModel> get customThemes => List.unmodifiable(_customThemes);
  bool get isLoading => _isLoading;

  CustomThemeModel get activeTheme {
    // Check built-in presets first
    for (final preset in AppThemes.presets) {
      if (preset.id == _activeThemeId) {
        return preset;
      }
    }
    // Check custom themes
    for (final custom in _customThemes) {
      if (custom.id == _activeThemeId) {
        return custom;
      }
    }
    return AppThemes.deepDark;
  }

  ThemeData get currentThemeData => activeTheme.toThemeData();

  /// Loads persisted activeThemeId from the database. Call once on startup.
  Future<void> loadActiveThemeId() async {
    final db = _dbService;
    if (db == null) return;
    try {
      final saved = await db.getSetting(_kActiveThemeKey);
      if (saved != null && AppThemes.removedPresetIds.contains(saved)) {
        _activeThemeId = AppThemes.deepDarkId;
        LoggerService().info('ThemeService: Saved theme "$saved" was removed, falling back to Deep Dark');
        await db.setSetting(_kActiveThemeKey, _activeThemeId);
        notifyListeners();
      } else if (saved != null && saved.isNotEmpty) {
        _activeThemeId = saved;
        LoggerService().info('ThemeService: Restored active theme "$saved" from storage');
        notifyListeners();
      }
    } catch (e) {
      LoggerService().warning('ThemeService: Could not restore active theme: $e');
    }
  }

  Future<void> loadThemes({bool force = false}) async {
    final repo = _repository;
    if (repo == null) return;
    _isLoading = true;
    try {
      final dbThemes = await repo.getAllCustomThemes();
      _customThemes.clear();
      _customThemes.addAll(dbThemes);
      LoggerService().info('ThemeService: Loaded ${_customThemes.length} custom themes');
    } catch (e) {
      LoggerService().warning('ThemeService: Could not load custom themes from DB: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTheme(String themeId) {
    if (_activeThemeId == themeId) return;
    _activeThemeId = themeId;
    LoggerService().info('ThemeService: Switched active theme to "$themeId"');
    _dbService?.setSetting(_kActiveThemeKey, themeId).catchError((e) {
      LoggerService().warning('ThemeService: Could not persist active theme: $e');
    });
    notifyListeners();
  }

  Future<void> saveCustomTheme(CustomThemeModel theme) async {
    final existingIndex = _customThemes.indexWhere((t) => t.id == theme.id);
    final repo = _repository;
    if (existingIndex != -1) {
      _customThemes[existingIndex] = theme;
      if (repo != null) {
        try {
          await repo.updateCustomTheme(theme);
        } catch (_) {}
      }
      LoggerService().info('ThemeService: Updated custom theme "${theme.name}" (${theme.id})');
    } else {
      _customThemes.add(theme);
      if (repo != null) {
        try {
          await repo.insertCustomTheme(theme);
        } catch (_) {}
      }
      LoggerService().info('ThemeService: Created new custom theme "${theme.name}" (${theme.id})');
    }
    _activeThemeId = theme.id;
    notifyListeners();
  }

  Future<void> deleteCustomTheme(String id) async {
    _customThemes.removeWhere((t) => t.id == id);
    final repo = _repository;
    if (repo != null) {
      try {
        await repo.deleteCustomTheme(id);
      } catch (_) {}
    }
    LoggerService().info('ThemeService: Deleted custom theme ($id)');
    if (_activeThemeId == id) {
      _activeThemeId = AppThemes.deepDarkId;
    }
    notifyListeners();
  }

  Future<CustomThemeModel?> duplicateCustomTheme(String sourceThemeId, {String? newName}) async {
    CustomThemeModel? source;
    for (final p in AppThemes.presets) {
      if (p.id == sourceThemeId) {
        source = p;
        break;
      }
    }
    if (source == null) {
      for (final c in _customThemes) {
        if (c.id == sourceThemeId) {
          source = c;
          break;
        }
      }
    }

    if (source == null) return null;

    final newTheme = source.copyWith(
      id: const Uuid().v4(),
      name: newName ?? '${source.name} (Copy)',
      isBuiltIn: false,
      createdAt: DateTime.now(),
    );

    await saveCustomTheme(newTheme);
    return newTheme;
  }
}
