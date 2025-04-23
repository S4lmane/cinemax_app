import 'package:flutter/material.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/movie_model.dart';

class MoviesProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;

  List<MovieModel> _newMovies = [];
  List<MovieModel> _popularMovies = [];
  List<MovieModel> _upcomingMovies = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MovieModel> get newMovies => _newMovies;
  List<MovieModel> get popularMovies => _popularMovies;
  List<MovieModel> get upcomingMovies => _upcomingMovies;

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

  // Fetch all movie categories
  Future<void> fetchAllMovies() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        fetchNewMovies(resetIfFirstPage: true),
        fetchPopularMovies(resetIfFirstPage: true),
        fetchUpcomingMovies(resetIfFirstPage: true),
      ]);
    } catch (e) {
      _setError('Failed to load movies. Please try again.');
      print('Error fetching all movies: $e');
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
    _newMovies = [];
    _popularMovies = [];
    _upcomingMovies = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}