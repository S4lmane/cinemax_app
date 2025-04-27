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
      // Use the movie service
      final movies = await _movieService.getNowPlayingMovies(page: page);

      if (movies.isEmpty) {
        print("No new movies returned from movie_service");
      } else {
        print("Fetched ${movies.length} new movies from movie_service");
      }

      if (page == 1) {
        _newMovies = movies;
      } else {
        // Add new movies without duplicates
        final existingIds = _newMovies.map((m) => m.id).toSet();
        final newUniqueMovies = movies.where((m) => !existingIds.contains(m.id)).toList();
        _newMovies = [..._newMovies, ...newUniqueMovies];
      }

      _setLoading(false);
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
      // Use the movie service
      final movies = await _movieService.getPopularMovies(page: page);

      if (movies.isEmpty) {
        print("No popular movies returned from movie_service");
      } else {
        print("Fetched ${movies.length} popular movies from movie_service");
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
      // Use the movie service
      final movies = await _movieService.getUpcomingMovies(page: page);

      if (movies.isEmpty) {
        print("No upcoming movies returned from movie_service");
      } else {
        print("Fetched ${movies.length} upcoming movies from movie_service");
      }

      // If we don't have enough upcoming movies, make additional API calls
      if (movies.length < 10 && page == 1) {
        print("Not enough upcoming movies, trying next page...");

        // Try fetching page 2 as well
        final page2Movies = await _movieService.getUpcomingMovies(page: 2);

        // Add without duplicates
        final allIds = movies.map((m) => m.id).toSet();
        final uniquePage2Movies = page2Movies.where((m) => !allIds.contains(m.id)).toList();

        // Combine the results
        final combinedMovies = [...movies, ...uniquePage2Movies];
        _upcomingMovies = combinedMovies;
      } else {
        if (page == 1) {
          _upcomingMovies = movies;
        } else {
          // Add new movies without duplicates
          final existingIds = _upcomingMovies.map((m) => m.id).toSet();
          final newUniqueMovies = movies.where((m) => !existingIds.contains(m.id)).toList();
          _upcomingMovies = [..._upcomingMovies, ...newUniqueMovies];
        }
      }

      _setLoading(false);
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
      // Use the MovieService method
      final tvShows = await _movieService.getAiringTodayTVShows(page: page);

      if (tvShows.isEmpty) {
        print("No new TV shows returned from movie_service");
      } else {
        print("Fetched ${tvShows.length} new TV shows from movie_service");
      }

      if (page == 1) {
        _newTVShows = tvShows;
      } else {
        // Add new shows without duplicates
        final existingIds = _newTVShows.map((s) => s.id).toSet();
        final newUniqueShows = tvShows.where((s) => !existingIds.contains(s.id)).toList();
        _newTVShows = [..._newTVShows, ...newUniqueShows];
      }

      _setLoading(false);
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
      // Use the MovieService method
      final shows = await _movieService.getPopularTVShows(page: page);

      if (shows.isEmpty) {
        print("No popular TV shows returned from movie_service");
      } else {
        print("Fetched ${shows.length} popular TV shows from movie_service");
      }

      if (page == 1) {
        _popularTVShows = shows;
      } else {
        // Add new shows without duplicates
        final existingIds = _popularTVShows.map((s) => s.id).toSet();
        final newUniqueShows = shows.where((s) => !existingIds.contains(s.id)).toList();
        _popularTVShows = [..._popularTVShows, ...newUniqueShows];
      }

      _setLoading(false);
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
      // Use the MovieService method
      final shows = await _movieService.getUpcomingTVShows(page: page);

      if (shows.isEmpty) {
        print("No upcoming TV shows returned from movie_service");
      } else {
        print("Fetched ${shows.length} upcoming TV shows from movie_service");
      }

      // If we don't have enough upcoming shows, try multiple pages
      if (shows.length < 10 && page == 1) {
        print("Not enough upcoming TV shows, trying next page and fallback method...");

        // Try additional pages
        List<MovieModel> additionalShows = [];

        // Try page 2
        final page2Shows = await _movieService.getUpcomingTVShows(page: 2);
        additionalShows.addAll(page2Shows);

        // If still not enough, try a backup approach - get trending shows
        if (shows.length + additionalShows.length < 10) {
          try {
            final now = DateTime.now();
            final oneMonthAgo = now.subtract(const Duration(days: 30));
            final startDateStr = oneMonthAgo.toString().substring(0, 10);

            // Network IDs for major streaming platforms
            final streamingNetworks = '213,49,1024,2739,2552,453';

            // Get upcoming and recent shows with fallback
            final _client.Client client = _movieService.client;
            final response = await client.get(
              Uri.parse(
                '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_networks=$streamingNetworks&first_air_date.gte=$startDateStr&sort_by=first_air_date.desc&vote_count.gte=10&page=1',
              ),
            );

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final results = data['results'] as List;

              // Convert to MovieModel and set isMovie flag
              final fallbackShows = results.map((json) => MovieModel.fromMap(json)).toList();
              for (var show in fallbackShows) {
                show.isMovie = false;
              }

              // Filter out non-narrative content
              final filteredShows = fallbackShows.where((show) {
                final title = show.title.toLowerCase();
                return !title.contains('talk') &&
                    !title.contains('tonight') &&
                    !title.contains('late night') &&
                    !title.contains('news') &&
                    !title.contains('daily');
              }).toList();

              additionalShows.addAll(filteredShows);
            }
          } catch (e) {
            print('Error in fallback upcoming TV shows approach: $e');
          }
        }

        // Combine all results and remove duplicates
        final allIds = shows.map((s) => s.id).toSet();
        final uniqueAdditionalShows = additionalShows.where((s) => !allIds.contains(s.id)).toList();

        _upcomingTVShows = [...shows, ...uniqueAdditionalShows];
      } else {
        if (page == 1) {
          _upcomingTVShows = shows;
        } else {
          // Add new shows without duplicates
          final existingIds = _upcomingTVShows.map((s) => s.id).toSet();
          final newUniqueShows = shows.where((s) => !existingIds.contains(s.id)).toList();
          _upcomingTVShows = [..._upcomingTVShows, ...newUniqueShows];
        }
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