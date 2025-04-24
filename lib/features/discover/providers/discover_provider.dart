// lib/features/discover/providers/discover_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as _client;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/movie_model.dart';

class DiscoverProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;

  // Movies
  List<MovieModel> _newMovies = [];
  List<MovieModel> _popularMovies = [];
  List<MovieModel> _upcomingMovies = [];

  // TV Shows
  List<MovieModel> _newTVShows = [];
  List<MovieModel> _popularTVShows = [];
  List<MovieModel> _upcomingTVShows = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Movies getters
  List<MovieModel> get newMovies => _newMovies;
  List<MovieModel> get popularMovies => _popularMovies;
  List<MovieModel> get upcomingMovies => _upcomingMovies;

  // TV Shows getters
  List<MovieModel> get newTVShows => _newTVShows;
  List<MovieModel> get popularTVShows => _popularTVShows;
  List<MovieModel> get upcomingTVShows => _upcomingTVShows;

  // MOVIE METHODS

  // Fetch new movies
  Future<void> fetchNewMovies({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _newMovies = [];
    }

    _setLoading(true);
    _clearError();

    try {
      // Use better filters to get truly "new" movies - past 3 months, sorted by release date
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      final endDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final startDate = "${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-${threeMonthsAgo.day.toString().padLeft(2, '0')}";

      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.nowPlayingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                '&primary_release_date.gte=$startDate&primary_release_date.lte=$endDate&sort_by=primary_release_date.desc'
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final results = data['results'] as List;

        // Filter for movies with at least decent ratings (>= 6.0)
        final qualityMovies = results
            .where((movie) => (movie['vote_average'] ?? 0.0) >= 6.0)
            .map((json) => MovieModel.fromMap(json))
            .toList();

        if (page == 1) {
          _newMovies = qualityMovies;
        } else {
          final existingIds = _newMovies.map((m) => m.id).toSet();
          final newUniqueMovies = qualityMovies.where((m) => !existingIds.contains(m.id)).toList();
          _newMovies = [..._newMovies, ...newUniqueMovies];
        }

        _setLoading(false);
      } else {
        throw Exception('Failed to load new movies');
      }
    } catch (e) {
      _setError('Failed to load new movies. Please try again.');
      print('Error fetching new movies: $e');
    }
  }

  // Fetch popular movies
// In lib/features/discover/providers/discover_provider.dart

  Future<void> fetchPopularMovies({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _popularMovies = [];
    }

    _setLoading(true);
    _clearError();

    try {
      // Focus on truly popular and well-rated movies
      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.popularMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                '&sort_by=popularity.desc&vote_count.gte=1000'
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        // Convert to MovieModel objects
        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Sort by popularity and vote average to ensure we get the best content first
        movies.sort((a, b) {
          // First by vote average (high to low)
          final ratingCompare = b.voteAverage.compareTo(a.voteAverage);
          if (ratingCompare != 0) return ratingCompare;

          // Then by vote count (high to low) as a proxy for popularity
          return b.voteCount.compareTo(a.voteCount);
        });

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        if (page == 1) {
          _popularMovies = movies;
        } else {
          // Add new movies without duplicates
          final existingIds = _popularMovies.map((m) => m.id).toSet();
          final newUniqueMovies = movies.where((m) => !existingIds.contains(m.id)).toList();
          _popularMovies = [..._popularMovies, ...newUniqueMovies];
        }

        _setLoading(false);
      } else {
        throw Exception('Failed to load popular movies');
      }
    } catch (e) {
      _setError('Failed to load popular movies. Please try again.');
      print('Error fetching popular movies: $e');
    }
  }

  Future<void> fetchUpcomingMovies({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _upcomingMovies = [];
    }

    _setLoading(true);
    _clearError();

    try {
      // Ensure we're only getting future releases (from today to 6 months in the future)
      final now = DateTime.now();
      final sixMonthsLater = DateTime(now.year, now.month + 6, now.day);

      final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final futureDate = "${sixMonthsLater.year}-${sixMonthsLater.month.toString().padLeft(2, '0')}-${sixMonthsLater.day.toString().padLeft(2, '0')}";

      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.upcomingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                '&primary_release_date.gte=$todayDate&primary_release_date.lte=$futureDate&sort_by=primary_release_date.asc'
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        // Convert to MovieModel objects
        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Further filter to ensure all dates are in the future
        final filteredMovies = movies.where((movie) {
          if (movie.releaseDate.isEmpty) return false;

          try {
            final releaseDate = DateTime.parse(movie.releaseDate);
            return releaseDate.isAfter(DateTime.now());
          } catch (_) {
            return false;
          }
        }).toList();

        // Sort by release date (soonest first)
        filteredMovies.sort((a, b) {
          try {
            final dateA = DateTime.parse(a.releaseDate);
            final dateB = DateTime.parse(b.releaseDate);
            return dateA.compareTo(dateB);
          } catch (_) {
            return 0;
          }
        });

        // Set isMovie flag
        for (var movie in filteredMovies) {
          movie.isMovie = true;
        }

        if (page == 1) {
          _upcomingMovies = filteredMovies;
        } else {
          // Add new movies without duplicates
          final existingIds = _upcomingMovies.map((m) => m.id).toSet();
          final newUniqueMovies = filteredMovies.where((m) => !existingIds.contains(m.id)).toList();
          _upcomingMovies = [..._upcomingMovies, ...newUniqueMovies];
        }

        _setLoading(false);
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      _setError('Failed to load upcoming movies. Please try again.');
      print('Error fetching upcoming movies: $e');
    }
  }

  // TV SHOW METHODS

  // Fetch new TV shows
  Future<void> fetchNewTVShows({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _newTVShows = [];
    }

    _setLoading(true);
    _clearError();

    try {
      // Use better filters to get truly "new" TV shows - past 3 months, sorted by first air date
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      final endDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final startDate = "${threeMonthsAgo.year}-${threeMonthsAgo.month.toString().padLeft(2, '0')}-${threeMonthsAgo.day.toString().padLeft(2, '0')}";

      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.airingTodayTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                '&air_date.gte=$startDate&air_date.lte=$endDate&sort_by=first_air_date.desc'
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final results = data['results'] as List;

        // Filter for shows with at least decent ratings (>= 6.5)
        final qualityShows = results
            .where((show) => (show['vote_average'] ?? 0.0) >= 6.5)
            .map((json) => MovieModel.fromMap(json))
            .toList();

        for (var show in qualityShows) {
          show.isMovie = false;
        }

        if (page == 1) {
          _newTVShows = qualityShows;
        } else {
          final existingIds = _newTVShows.map((m) => m.id).toSet();
          final newUniqueShows = qualityShows.where((m) => !existingIds.contains(m.id)).toList();
          _newTVShows = [..._newTVShows, ...newUniqueShows];
        }

        _setLoading(false);
      } else {
        throw Exception('Failed to load new TV shows');
      }
    } catch (e) {
      _setError('Failed to load new TV shows. Please try again.');
      print('Error fetching new TV shows: $e');
    }
  }

  Future<void> fetchPopularTVShows({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _popularTVShows = [];
    }

    _setLoading(true);
    _clearError();

    try {
      // Focus on truly popular and well-rated TV shows
      final response = await _client.get(
        Uri.parse(
            '${ApiConstants.popularTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                '&sort_by=popularity.desc&vote_count.gte=500'
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        // Convert to MovieModel objects
        final shows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Sort by popularity and vote average to ensure we get the best content first
        shows.sort((a, b) {
          // First by vote average (high to low)
          final ratingCompare = b.voteAverage.compareTo(a.voteAverage);
          if (ratingCompare != 0) return ratingCompare;

          // Then by vote count (high to low) as a proxy for popularity
          return b.voteCount.compareTo(a.voteCount);
        });

        // Set isMovie flag
        for (var show in shows) {
          show.isMovie = false;
        }

        // Take at least 10 shows if available
        final minCount = 10;
        final availableShows = shows.length;

        if (page == 1) {
          _popularTVShows = shows;

          // If we didn't get enough shows, try to get more
          if (availableShows < minCount && page < 5) {
            await fetchPopularTVShows(page: page + 1, resetIfFirstPage: false);
          }
        } else {
          // Add new shows without duplicates
          final existingIds = _popularTVShows.map((m) => m.id).toSet();
          final newUniqueShows = shows.where((m) => !existingIds.contains(m.id)).toList();
          _popularTVShows = [..._popularTVShows, ...newUniqueShows];
        }

        _setLoading(false);
      } else {
        throw Exception('Failed to load popular TV shows');
      }
    } catch (e) {
      _setError('Failed to load popular TV shows. Please try again.');
      print('Error fetching popular TV shows: $e');
    }
  }

  Future<void> fetchUpcomingTVShows({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _upcomingTVShows = [];
    }

    _setLoading(true);
    _clearError();

    try {
      // For upcoming TV shows, we'll use on_the_air with future filter
      final now = DateTime.now();
      final sixMonthsLater = DateTime(now.year, now.month + 6, now.day);

      final todayDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final futureDate = "${sixMonthsLater.year}-${sixMonthsLater.month.toString().padLeft(2, '0')}-${sixMonthsLater.day.toString().padLeft(2, '0')}";

      // Multiple requests to ensure we get enough shows
      List<MovieModel> allShows = [];

      // Start with on_the_air
      final responseOnAir = await _client.get(
        Uri.parse(
            '${ApiConstants.onTheAirTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                '&air_date.gte=$todayDate&sort_by=first_air_date.asc'
        ),
      );

      if (responseOnAir.statusCode == 200) {
        final data = json.decode(responseOnAir.body);
        final results = data['results'] as List;

        final shows = results.map((json) => MovieModel.fromMap(json)).toList();
        for (var show in shows) {
          show.isMovie = false;
        }

        allShows.addAll(shows);
      }

      // Also get shows from the discover endpoint to ensure we get enough
      if (allShows.length < 10 || page > 1) {
        final responseDiscover = await _client.get(
          Uri.parse(
              '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page' +
                  '&first_air_date.gte=$todayDate&first_air_date.lte=$futureDate&sort_by=first_air_date.asc'
          ),
        );

        if (responseDiscover.statusCode == 200) {
          final data = json.decode(responseDiscover.body);
          final results = data['results'] as List;

          final shows = results.map((json) => MovieModel.fromMap(json)).toList();
          for (var show in shows) {
            show.isMovie = false;
          }

          // Add without duplicates
          final existingIds = allShows.map((s) => s.id).toSet();
          allShows.addAll(shows.where((s) => !existingIds.contains(s.id)));
        }
      }

      // Sort by release date
      allShows.sort((a, b) {
        if (a.releaseDate.isEmpty) return 1;
        if (b.releaseDate.isEmpty) return -1;

        try {
          final dateA = DateTime.parse(a.releaseDate);
          final dateB = DateTime.parse(b.releaseDate);
          return dateA.compareTo(dateB);
        } catch (_) {
          return 0;
        }
      });

      // Only include future shows
      final futureShows = allShows.where((show) {
        if (show.releaseDate.isEmpty) return false;

        try {
          final releaseDate = DateTime.parse(show.releaseDate);
          return releaseDate.isAfter(DateTime.now());
        } catch (_) {
          return false;
        }
      }).toList();

      if (page == 1) {
        _upcomingTVShows = futureShows;

        // If we didn't get enough shows, try to get more
        if (futureShows.length < 10 && page < 3) {
          await fetchUpcomingTVShows(page: page + 1, resetIfFirstPage: false);
        }
      } else {
        // Add new shows without duplicates
        final existingIds = _upcomingTVShows.map((m) => m.id).toSet();
        final newUniqueShows = futureShows.where((m) => !existingIds.contains(m.id)).toList();
        _upcomingTVShows = [..._upcomingTVShows, ...newUniqueShows];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load upcoming TV shows. Please try again.');
      print('Error fetching upcoming TV shows: $e');
    }
  }

  // Fetch all content
  Future<void> fetchAllContent() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        // Movies
        fetchNewMovies(resetIfFirstPage: true),
        fetchPopularMovies(resetIfFirstPage: true),
        fetchUpcomingMovies(resetIfFirstPage: true),

        // TV Shows
        fetchNewTVShows(resetIfFirstPage: true),
        fetchPopularTVShows(resetIfFirstPage: true),
        fetchUpcomingTVShows(resetIfFirstPage: true),
      ]);
    } catch (e) {
      _setError('Failed to load content. Please try again.');
      print('Error fetching all content: $e');
    }

    _setLoading(false);
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

  // Clear all data when logging out
  void clearData() {
    // Movies
    _newMovies = [];
    _popularMovies = [];
    _upcomingMovies = [];

    // TV Shows
    _newTVShows = [];
    _popularTVShows = [];
    _upcomingTVShows = [];

    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}