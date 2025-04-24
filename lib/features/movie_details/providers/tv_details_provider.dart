// Create a new file lib/features/movie_details/providers/tv_details_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/season_model.dart';
import '../../../models/episode_model.dart';

class TvDetailsProvider extends ChangeNotifier {
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get season details
  Future<SeasonModel?> getSeasonDetails(String tvId, int seasonNumber) async {
    _setLoading(true);
    _clearError();

    try {
      final endpoint = '${ApiConstants.baseUrl}/tv/$tvId/season/$seasonNumber';
      final response = await _movieService.getSeasonDetails(tvId, seasonNumber);

      if (response == null) {
        _setError('Failed to load season details');
        return null;
      }

      _setLoading(false);
      return response;
    }  catch (e) {
      _setError('Failed to load season details: $e');
      print('Error getting season details: $e');
      return null;
    }
  }

  // Get episode details
  Future<EpisodeModel?> getEpisodeDetails(
      String tvId,
      int seasonNumber,
      int episodeNumber,
      ) async {
    _setLoading(true);
    _clearError();

    try {
      final endpoint = '${ApiConstants.baseUrl}/tv/$tvId/season/$seasonNumber/episode/$episodeNumber';
      final response = await _movieService.client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US',
        ),
      );

      if (response.statusCode != 200) {
        _setError('Failed to load episode details');
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      final episode = EpisodeModel.fromMap(data);

      _setLoading(false);
      return episode;
    } catch (e) {
      _setError('Failed to load episode details: $e');
      print('Error getting episode details: $e');
      return null;
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
}