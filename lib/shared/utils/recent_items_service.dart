// Create a new file lib/shared/utils/recent_items_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/movie_model.dart';

class RecentItemsService {
  static const String recentlyViewedKey = 'recently_viewed';
  static const int maxRecentItems = 10;

  // Add an item to recently viewed
  static Future<void> addRecentItem(MovieModel movie) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing items
      final List<String> recentItems = prefs.getStringList(recentlyViewedKey) ?? [];

      // Convert movie to JSON
      final movieJson = jsonEncode({
        'id': movie.id,
        'title': movie.title,
        'posterPath': movie.posterPath,
        'isMovie': movie.isMovie,
        'releaseDate': movie.releaseDate,
        'voteAverage': movie.voteAverage,
      });

      // Remove item if it already exists to avoid duplicates
      recentItems.removeWhere((item) {
        final Map<String, dynamic> itemData = jsonDecode(item);
        return itemData['id'] == movie.id;
      });

      // Add to beginning of list
      recentItems.insert(0, movieJson);

      // Limit list size
      if (recentItems.length > maxRecentItems) {
        recentItems.removeLast();
      }

      // Save updated list
      await prefs.setStringList(recentlyViewedKey, recentItems);
    } catch (e) {
      print('Error saving recent item: $e');
    }
  }

  // Get recently viewed items
  static Future<List<MovieModel>> getRecentItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recentItems = prefs.getStringList(recentlyViewedKey) ?? [];

      return recentItems.map((item) {
        final Map<String, dynamic> itemData = jsonDecode(item);
        return MovieModel(
          id: itemData['id'],
          title: itemData['title'],
          posterPath: itemData['posterPath'] ?? '',
          backdropPath: '',
          overview: '',
          voteAverage: itemData['voteAverage'] ?? 0.0,
          voteCount: 0,
          releaseDate: itemData['releaseDate'] ?? '',
          genres: [],
          runtime: 0,
          isMovie: itemData['isMovie'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error getting recent items: $e');
      return [];
    }
  }

  // Clear recently viewed items
  static Future<void> clearRecentItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(recentlyViewedKey);
    } catch (e) {
      print('Error clearing recent items: $e');
    }
  }
}