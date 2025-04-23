import 'package:flutter/material.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/movie_model.dart';

class SearchProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;
  List<MovieModel> _searchResults = [];
  String _query = '';
  int _currentPage = 1;
  bool _hasMoreResults = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MovieModel> get searchResults => _searchResults;
  String get query => _query;
  bool get hasMoreResults => _hasMoreResults;

  // Search movies
  Future<void> searchMovies(String query, {bool resetResults = true}) async {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    // If same query and not reset, return
    if (_query == query && !resetResults) {
      return;
    }

    _query = query;

    if (resetResults) {
      _searchResults = [];
      _currentPage = 1;
      _hasMoreResults = true;
    }

    _setLoading(true);
    _clearError();

    try {
      final movies = await _movieService.searchMovies(query, page: _currentPage);

      if (movies.isEmpty) {
        _hasMoreResults = false;
      }

      if (_currentPage == 1) {
        _searchResults = movies;
      } else {
        // Add new movies without duplicates
        final existingIds = _searchResults.map((m) => m.id).toSet();
        final newUniqueMovies = movies.where((m) => !existingIds.contains(m.id)).toList();
        _searchResults.addAll(newUniqueMovies);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to search movies. Please try again.');
      print('Error searching movies: $e');
    }
  }

  // Load more search results
  Future<void> loadMoreResults() async {
    if (_isLoading || !_hasMoreResults) {
      return;
    }

    _currentPage++;
    await searchMovies(_query, resetResults: false);
  }

  // Clear search
  void clearSearch() {
    _searchResults = [];
    _query = '';
    _currentPage = 1;
    _hasMoreResults = true;
    _error = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}