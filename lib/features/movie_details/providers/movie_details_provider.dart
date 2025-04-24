import 'package:flutter/material.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/movie_model.dart';

class MovieDetailsProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;
  MovieModel? _movie;
  bool _isInWatchlist = false;
  bool _isInFavorites = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  MovieModel? get movie => _movie;
  bool get isInWatchlist => _isInWatchlist;
  bool get isInFavorites => _isInFavorites;

  // Get movie or TV show details
  Future<void> getMovieDetails(String itemId, {bool isMovie = true}) async {
    _setLoading(true);
    _clearError();

    try {
      final movie = await _movieService.getMovieDetails(itemId, isMovie: isMovie);

      if (movie == null) {
        _setError('Failed to load details');
      } else {
        _movie = movie;
        _movie!.isMovie = isMovie;
        _isInWatchlist = await _movieService.isInWatchlist(itemId);
        _isInFavorites = await _movieService.isInFavorites(itemId);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load details: $e');
      print('Error getting details: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add/remove from watchlist
  Future<bool> toggleWatchlist() async {
    if (_movie == null) return false;

    _setLoading(true);

    try {
      final movieId = _movie!.id;
      bool success;

      if (_isInWatchlist) {
        success = await _movieService.removeFromWatchlist(movieId);
      } else {
        success = await _movieService.addToWatchlist(movieId, _movie!.isMovie);
      }

      if (success) {
        _isInWatchlist = !_isInWatchlist;
      }

      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _setError('Failed to update watchlist: $e');
      print('Error toggling watchlist: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Add/remove from favorites
  Future<bool> toggleFavorites() async {
    if (_movie == null) return false;

    _setLoading(true);

    try {
      final movieId = _movie!.id;
      bool success;

      if (_isInFavorites) {
        success = await _movieService.removeFromFavorites(movieId);
      } else {
        success = await _movieService.addToFavorites(movieId, _movie!.isMovie);
      }

      if (success) {
        _isInFavorites = !_isInFavorites;
      }

      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _setError('Failed to update favorites: $e');
      print('Error toggling favorites: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
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

  void clearMovie() {
    _movie = null;
    _isInWatchlist = false;
    _isInFavorites = false;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}