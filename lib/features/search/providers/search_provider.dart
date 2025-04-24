// lib/features/search/providers/search_provider.dart
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

  // Filter parameters
  String _contentType = 'all'; // 'all', 'movies', 'tv'
  String? _genre;
  int _startYear = 1900;
  int _endYear = DateTime.now().year;
  double _minRating = 0.0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MovieModel> get searchResults => _searchResults;
  String get query => _query;
  bool get hasMoreResults => _hasMoreResults;

  // Set filters for search
  void setFilters({
    String? contentType,
    String? genre,
    int? startYear,
    int? endYear,
    double? minRating,
  }) {
    if (contentType != null) _contentType = contentType;
    _genre = genre;
    if (startYear != null) _startYear = startYear;
    if (endYear != null) _endYear = endYear;
    if (minRating != null) _minRating = minRating;
  }

  // Search movies with filters
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
      // Determine whether to search for movies, TV shows, or both
      List<MovieModel> movies = [];

      switch (_contentType) {
        case 'movies':
        // Only search for movies
          movies = await _movieService.searchMovies(query, page: _currentPage, includeAdult: false);
          // Filter out TV shows
          movies = movies.where((item) => item.isMovie).toList();
          break;

        case 'tv':
        // Only search for TV shows
          movies = await _movieService.searchTVShows(query, page: _currentPage);
          break;

        default:
        // Search for both movies and TV shows
          final movieResults = await _movieService.searchMovies(query, page: _currentPage, includeAdult: false);
          final tvResults = await _movieService.searchTVShows(query, page: _currentPage);
          movies = [...movieResults, ...tvResults];
          break;
      }

      // Apply additional filters
      movies = _applyFilters(movies);

      // Sort by rating (highest first)
      movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

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
      _setError('Failed to search. Please try again.');
      print('Error searching content: $e');
    }
  }

  // Apply filters to search results
  List<MovieModel> _applyFilters(List<MovieModel> movies) {
    return movies.where((movie) {
      // Filter by genre if specified
      if (_genre != null && _genre != 'all') {
        final hasGenre = movie.genres.any(
                (genre) => genre.toLowerCase() == _genre!.toLowerCase()
        );
        if (!hasGenre) return false;
      }

      // Filter by year range
      final year = movie.getYear();
      if (year.isNotEmpty) {
        final movieYear = int.tryParse(year) ?? 0;
        if (movieYear < _startYear || movieYear > _endYear) {
          return false;
        }
      }

      // Filter by minimum rating
      if (movie.voteAverage < _minRating) {
        return false;
      }

      return true;
    }).toList();
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