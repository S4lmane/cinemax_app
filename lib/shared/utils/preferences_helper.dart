import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static const String skipWatchlistConfirmKey = 'skip_watchlist_confirm';
  static const String skipFavoritesConfirmKey = 'skip_favorites_confirm';
  static const String skipListItemConfirmKey = 'skip_list_item_confirm';

  // Save boolean preference
  static Future<void> saveBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Get boolean preference
  static Future<bool> getBoolPref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }
}