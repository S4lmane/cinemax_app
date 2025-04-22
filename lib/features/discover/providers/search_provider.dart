import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';

class SearchProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _searchResults = [];
  String _query = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get searchResults => _searchResults;
  String get query => _query;
  bool get hasResults => _searchResults.isNotEmpty;

  // Search movies by query
  Future<void> searchMovies(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _query = '';
      notifyListeners();
      return;
    }

    _query = query;
    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=1&include_adult=false'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _searchResults = data['results'];
        _setLoading(false);
      } else {
        _setError('Failed to load search results');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Clear search results
  void clearSearch() {
    _searchResults = [];
    _query = '';
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}