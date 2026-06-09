import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _lastSearchKey = 'last_search';
  static const String _sortOrderKey = 'sort_order';

  // Last Search Query
  Future<String> getLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSearchKey) ?? '';
  }

  Future<void> saveLastSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSearchKey, query);
  }

  // Sort Order for Favorites
  Future<String> getSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortOrderKey) ?? 'id';
  }

  Future<void> saveSortOrder(String order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOrderKey, order);
  }
}
