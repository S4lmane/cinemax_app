// lib/features/discover/providers/discover_provider.dart
import 'package:flutter/material.dart';
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
      final movies = await _movieService.getNowPlayingMovies(page: page);

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
  Future<void> fetchPopularMovies({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _popularMovies = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final movies = await _movieService.getPopularMovies(page: page);

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

  // Fetch upcoming movies
  Future<void> fetchUpcomingMovies({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _upcomingMovies = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final movies = await _movieService.getUpcomingMovies(page: page);

      if (page == 1) {
        _upcomingMovies = movies;
      } else {
        // Add new movies without duplicates
        final existingIds = _upcomingMovies.map((m) => m.id).toSet();
        final newUniqueMovies = movies.where((m) => !existingIds.contains(m.id)).toList();
        _upcomingMovies = [..._upcomingMovies, ...newUniqueMovies];
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
      final tvShows = await _movieService.getAiringTodayTVShows(page: page);

      if (page == 1) {
        _newTVShows = tvShows;
      } else {
        // Add new TV shows without duplicates
        final existingIds = _newTVShows.map((m) => m.id).toSet();
        final newUniqueShows = tvShows.where((m) => !existingIds.contains(m.id)).toList();
        _newTVShows = [..._newTVShows, ...newUniqueShows];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load new TV shows. Please try again.');
      print('Error fetching new TV shows: $e');
    }
  }

  // Fetch popular TV shows
  Future<void> fetchPopularTVShows({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _popularTVShows = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final tvShows = await _movieService.getPopularTVShows(page: page);

      if (page == 1) {
        _popularTVShows = tvShows;
      } else {
        // Add new TV shows without duplicates
        final existingIds = _popularTVShows.map((m) => m.id).toSet();
        final newUniqueShows = tvShows.where((m) => !existingIds.contains(m.id)).toList();
        _popularTVShows = [..._popularTVShows, ...newUniqueShows];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load popular TV shows. Please try again.');
      print('Error fetching popular TV shows: $e');
    }
  }

  // Fetch upcoming TV shows
  Future<void> fetchUpcomingTVShows({int page = 1, bool resetIfFirstPage = false}) async {
    if (page == 1 && resetIfFirstPage) {
      _upcomingTVShows = [];
    }

    _setLoading(true);
    _clearError();

    try {
      final tvShows = await _movieService.getUpcomingTVShows(page: page);

      if (page == 1) {
        _upcomingTVShows = tvShows;
      } else {
        // Add new TV shows without duplicates
        final existingIds = _upcomingTVShows.map((m) => m.id).toSet();
        final newUniqueShows = tvShows.where((m) => !existingIds.contains(m.id)).toList();
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