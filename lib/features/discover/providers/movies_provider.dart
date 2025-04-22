import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';

class MoviesProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _newMovies = [];
  List<dynamic> _popularMovies = [];
  List<dynamic> _upcomingMovies = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get newMovies => _newMovies;
  List<dynamic> get popularMovies => _popularMovies;
  List<dynamic> get upcomingMovies => _upcomingMovies;

  // Fetch new movies (now playing)
  Future<void> fetchNewMovies() async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.nowPlayingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _newMovies = data['results'];
        _setLoading(false);
      } else {
        _setError('Failed to load new movies');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Fetch popular movies
  Future<void> fetchPopularMovies() async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.popularMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _popularMovies = data['results'];
        _setLoading(false);
      } else {
        _setError('Failed to load popular movies');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Fetch upcoming movies
  Future<void> fetchUpcomingMovies() async {
    _setLoading(true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.upcomingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=1'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _upcomingMovies = data['results'];
        _setLoading(false);
      } else {
        _setError('Failed to load upcoming movies');
      }
    } catch (e) {
      _setError('Network error: $e');
    }
  }

  // Fetch all movie categories
  Future<void> fetchAllMovies() async {
    _setLoading(true);
    _clearError();

    await Future.wait([
      fetchNewMovies(),
      fetchPopularMovies(),
      fetchUpcomingMovies(),
    ]);

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
}