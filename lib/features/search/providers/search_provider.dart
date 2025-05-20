// lib/features/search/providers/search_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/movie_model.dart';

class SearchProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;
  // List<MovieModel> _searchResults = [];
  List<dynamic> _searchResults = [];
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
  List get searchResults => _searchResults;
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
      List<dynamic> results = [];

      switch (_contentType) {
        case 'movies':
        // Only search for movies
          final response = await http.get(
            Uri.parse(
              '${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$_currentPage&include_adult=false',
            ),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            results = (data['results'] as List).map((item) {
              // Add media_type to each item
              item['media_type'] = 'movie';
              return item;
            }).toList();
          }
          break;

        case 'tv':
        // Only search for TV shows
          final response = await http.get(
            Uri.parse(
              '${ApiConstants.searchTV}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$_currentPage',
            ),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            results = (data['results'] as List).map((item) {
              // Add media_type to each item
              item['media_type'] = 'tv';
              return item;
            }).toList();
          }
          break;

        default:
        // Search for both movies and TV shows using multi-search
          final response = await http.get(
            Uri.parse(
              '${ApiConstants.searchMulti}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$_currentPage&include_adult=false',
            ),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            results = (data['results'] as List).where((item) {
              final mediaType = item['media_type'] as String?;
              return mediaType == 'movie' || mediaType == 'tv';
            }).toList();
          }
          break;
      }

      // Apply filters
      results = _applyFilters(results);

      if (results.isEmpty) {
        _hasMoreResults = false;
      }

      if (_currentPage == 1) {
        _searchResults = results;
      } else {
        // Add new results
        _searchResults.addAll(results);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to search. Please try again.');
      print('Error searching content: $e');
    }
  }

  // Apply filters to search results
  List<dynamic> _applyFilters(List<dynamic> results) {
    return results.where((result) {
      // Get data fields regardless of whether result is a map or an object
      String? releaseDate;
      double voteAverage = 0.0;
      List<dynamic>? genreIds;

      if (result is Map<String, dynamic>) {
        releaseDate = result['release_date'] ?? result['first_air_date'] ?? '';
        voteAverage = (result['vote_average'] ?? 0.0).toDouble();
        genreIds = result['genre_ids'] as List<dynamic>?;
      } else {
        // Handle other types if necessary
        return false;
      }

      // Filter by year range
      if (releaseDate != null && releaseDate.isNotEmpty && releaseDate.length >= 4) {
        final year = int.tryParse(releaseDate.substring(0, 4)) ?? 0;
        if (year < _startYear || year > _endYear) {
          return false;
        }
      }

      // Filter by minimum rating
      if (voteAverage < _minRating) {
        return false;
      }

      // Filter by genre if specified
      if (_genre != null && _genre != 'all' && genreIds != null) {
        bool hasMatchingGenre = false;
        for (var genreId in genreIds) {
          final genreName = ApiConstants.genres[genreId as int];
          if (genreName != null &&
              genreName.toLowerCase() == _genre!.toLowerCase()) {
            hasMatchingGenre = true;
            break;
          }
        }
        if (!hasMatchingGenre) return false;
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

  bool _filterMovieModel(MovieModel movie) {
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
  }

  bool _filterMovieMap(Map<String, dynamic> movie) {
    // Filter by genre if specified
    if (_genre != null && _genre != 'all') {
      final genreIds = movie['genre_ids'] as List<dynamic>?;
      if (genreIds != null && genreIds.isNotEmpty) {
        bool hasMatchingGenre = false;
        for (var genreId in genreIds) {
          final genreName = ApiConstants.genres[genreId];
          if (genreName != null && genreName.toLowerCase() == _genre!.toLowerCase()) {
            hasMatchingGenre = true;
            break;
          }
        }
        if (!hasMatchingGenre) return false;
      }
    }

    // Filter by year range
    String releaseDate = movie['release_date'] ?? movie['first_air_date'] ?? '';
    if (releaseDate.isNotEmpty && releaseDate.length >= 4) {
      final movieYear = int.tryParse(releaseDate.substring(0, 4)) ?? 0;
      if (movieYear < _startYear || movieYear > _endYear) {
        return false;
      }
    }

    // Filter by minimum rating
    final voteAverage = (movie['vote_average'] ?? 0.0) as double;
    if (voteAverage < _minRating) {
      return false;
    }

    return true;
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