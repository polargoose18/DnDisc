import '../../domain/models/custom_theme_model.dart';
import '../services/database_service.dart';

abstract class CustomThemeRepository {
  Future<List<CustomThemeModel>> getAllCustomThemes();
  Future<CustomThemeModel?> getCustomThemeById(String id);
  Future<void> insertCustomTheme(CustomThemeModel theme);
  Future<void> updateCustomTheme(CustomThemeModel theme);
  Future<void> deleteCustomTheme(String id);
}

class SqliteCustomThemeRepository implements CustomThemeRepository {
  final DatabaseService _db;

  SqliteCustomThemeRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<List<CustomThemeModel>> getAllCustomThemes() => _db.getAllCustomThemes();

  @override
  Future<CustomThemeModel?> getCustomThemeById(String id) => _db.getCustomThemeById(id);

  @override
  Future<void> insertCustomTheme(CustomThemeModel theme) => _db.insertCustomTheme(theme);

  @override
  Future<void> updateCustomTheme(CustomThemeModel theme) => _db.updateCustomTheme(theme);

  @override
  Future<void> deleteCustomTheme(String id) => _db.deleteCustomTheme(id);
}
