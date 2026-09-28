import 'package:flutter/material.dart';
import '../../data/services/theme_service.dart';
import '../../data/repositories/custom_theme_repository.dart';
import '../../domain/models/custom_theme_model.dart';
import '../../data/services/database_service.dart';

/// ThemeViewModel manages presentation state and custom theme interactions in compliance with MVVM architecture.
class ThemeViewModel extends ChangeNotifier {
  final ThemeService _service;

  ThemeViewModel({
    ThemeService? service,
    DatabaseService? dbService,
    CustomThemeRepository? repository,
    String? initialThemeId,
    bool autoLoad = false,
  }) : _service = service ??
            ThemeService(
              dbService: dbService,
              repository: repository,
              initialThemeId: initialThemeId,
              autoLoad: autoLoad,
            ) {
    _service.addListener(notifyListeners);
  }

  /// Underlying theme service reference
  ThemeService get service => _service;

  String get activeThemeId => _service.activeThemeId;
  List<CustomThemeModel> get builtInPresets => _service.builtInPresets;
  List<CustomThemeModel> get customThemes => _service.customThemes;
  bool get isLoading => _service.isLoading;
  CustomThemeModel get activeTheme => _service.activeTheme;
  ThemeData get currentThemeData => _service.currentThemeData;

  Future<void> loadThemes({bool force = false}) => _service.loadThemes(force: force);

  void selectTheme(String themeId) => _service.selectTheme(themeId);

  Future<void> saveCustomTheme(CustomThemeModel theme) => _service.saveCustomTheme(theme);

  Future<void> deleteCustomTheme(String id) => _service.deleteCustomTheme(id);

  Future<CustomThemeModel?> duplicateCustomTheme(String sourceThemeId, {String? newName}) =>
      _service.duplicateCustomTheme(sourceThemeId, newName: newName);

  @override
  void dispose() {
    _service.removeListener(notifyListeners);
    super.dispose();
  }
}
