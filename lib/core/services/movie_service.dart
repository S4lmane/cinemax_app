// lib/core/services/movie_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie_model.dart';
import '../../models/cast_model.dart';
import '../../models/crew_model.dart';
import '../../models/season_model.dart';
import '../../models/video_model.dart';
import '../constants/api_constants.dart';

class MovieService {
  final http.Client _client = http.Client();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  http.Client get client => _client;

  // TMDB API methods

  // Get now playing movies
  Future<List<MovieModel>> getNowPlayingMovies({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.nowPlayingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load now playing movies');
      }
    } catch (e) {
      print('Error fetching now playing movies: $e');
      return [];
    }
  }

  // Get airing today TV shows (equivalent to now playing movies)
  Future<List<MovieModel>> getAiringTodayTVShows({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.airingTodayTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        return tvShows;
      } else {
        throw Exception('Failed to load airing today TV shows');
      }
    } catch (e) {
      print('Error fetching airing today TV shows: $e');
      return [];
    }
  }

  // Get popular movies
  Future<List<MovieModel>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.popularMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load popular movies');
      }
    } catch (e) {
      print('Error fetching popular movies: $e');
      return [];
    }
  }

  // Get popular TV shows
  Future<List<MovieModel>> getPopularTVShows({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.popularTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        return tvShows;
      } else {
        throw Exception('Failed to load popular TV shows');
      }
    } catch (e) {
      print('Error fetching popular TV shows: $e');
      return [];
    }
  }

  // Get upcoming movies
  Future<List<MovieModel>> getUpcomingMovies({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.upcomingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      print('Error fetching upcoming movies: $e');
      return [];
    }
  }

  // Get upcoming TV shows (equivalent to upcoming movies)
  Future<List<MovieModel>> getUpcomingTVShows({int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.onTheAirTVShows}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        return tvShows;
      } else {
        throw Exception('Failed to load upcoming TV shows');
      }
    } catch (e) {
      print('Error fetching upcoming TV shows: $e');
      return [];
    }
  }

  // Get movie details
  Future<MovieModel?> getMovieDetails(String movieId, {bool isMovie = true}) async {
    try {
      final String endpoint = isMovie
          ? '${ApiConstants.baseUrl}/movie/$movieId'
          : '${ApiConstants.baseUrl}/tv/$movieId';

      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US&append_to_response=credits,videos,similar,recommendations',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final movie = MovieModel.fromMap(data);

        // Set isMovie flag
        movie.isMovie = isMovie;

        // Parse credits to get cast and crew
        if (data.containsKey('credits')) {
          final credits = data['credits'];

          if (credits.containsKey('cast')) {
            movie.cast = (credits['cast'] as List)
                .map((castData) => CastModel.fromMap(castData))
                .toList();

            // Limit to top cast members
            if (movie.cast.length > 10) {
              movie.cast = movie.cast.sublist(0, 10);
            }
          }

          if (credits.containsKey('crew')) {
            movie.crew = (credits['crew'] as List)
                .map((crewData) => CrewModel.fromMap(crewData))
                .toList();

            // Extract director for movies or creator for TV shows
            if (isMovie) {
              movie.director = movie.crew
                  .firstWhere((crew) => crew.job == 'Director',
                  orElse: () => CrewModel(
                    id: '0',
                    name: 'Unknown',
                    job: 'Director',
                    profilePath: '',
                  ))
                  .name;
            } else {
              if (data.containsKey('created_by') && (data['created_by'] as List).isNotEmpty) {
                movie.creator = (data['created_by'] as List).first['name'];
              } else {
                movie.creator = 'Unknown';
              }
            }
          }
        }

        // Parse videos to get trailers
        if (data.containsKey('videos') && data['videos'].containsKey('results')) {
          movie.videos = (data['videos']['results'] as List)
              .map((videoData) => VideoModel.fromMap(videoData))
              .toList();

          // Filter to get only trailers and teasers
          movie.videos = movie.videos
              .where((video) =>
          video.type == 'Trailer' ||
              video.type == 'Teaser')
              .toList();
        }

        // Parse similar movies/shows
        if (data.containsKey('similar') && data['similar'].containsKey('results')) {
          movie.similar = (data['similar']['results'] as List)
              .map((similarData) => MovieModel.fromMap(similarData))
              .toList();

          // Limit to 10 similar items
          if (movie.similar.length > 10) {
            movie.similar = movie.similar.sublist(0, 10);
          }

          // Set isMovie flag for similar items
          for (var item in movie.similar) {
            item.isMovie = isMovie;
          }
        }

        // Parse recommendations
        if (data.containsKey('recommendations') && data['recommendations'].containsKey('results')) {
          movie.recommendations = (data['recommendations']['results'] as List)
              .map((recData) => MovieModel.fromMap(recData))
              .toList();

          // Limit to 10 recommendations
          if (movie.recommendations.length > 10) {
            movie.recommendations = movie.recommendations.sublist(0, 10);
          }

          // Set isMovie flag for recommendations
          for (var item in movie.recommendations) {
            item.isMovie = isMovie;
          }
        }

        return movie;
      } else {
        throw Exception('Failed to load item details');
      }
    } catch (e) {
      print('Error fetching item details: $e');
      return null;
    }
  }

  // Search movies
  Future<List<MovieModel>> searchMovies(String query, {int page = 1, bool includeAdult = false}) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$page&include_adult=$includeAdult',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }

  // Search TV shows
  Future<List<MovieModel>> searchTVShows(String query, {int page = 1}) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.searchTV}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        return tvShows;
      } else {
        throw Exception('Failed to search TV shows');
      }
    } catch (e) {
      print('Error searching TV shows: $e');
      return [];
    }
  }

  // Get movies by genre
  Future<List<MovieModel>> getMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverMovie}?api_key=${ApiConstants.apiKey}&language=en-US&with_genres=$genreId&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load movies by genre');
      }
    } catch (e) {
      print('Error fetching movies by genre: $e');
      return [];
    }
  }

  // Get TV shows by genre
  Future<List<MovieModel>> getTVShowsByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.discoverTV}?api_key=${ApiConstants.apiKey}&language=en-US&with_genres=$genreId&page=$page',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final tvShows = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var tvShow in tvShows) {
          tvShow.isMovie = false;
        }

        return tvShows;
      } else {
        throw Exception('Failed to load TV shows by genre');
      }
    } catch (e) {
      print('Error fetching TV shows by genre: $e');
      return [];
    }
  }

  // Watchlist methods
  Future<bool> addToWatchlist(String itemId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final watchlistItem = {
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .add(watchlistItem);

      return true;
    } catch (e) {
      print('Error adding to watchlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWatchlist(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      // Delete all instances (should be only one, but just in case)
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }

  Future<bool> isInWatchlist(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking watchlist: $e');
      return false;
    }
  }

  Future<List<String>> getWatchlistIds() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .get();

      return querySnapshot.docs
          .map((doc) => (doc.data()['itemId'] as String))
          .toList();
    } catch (e) {
      print('Error getting watchlist IDs: $e');
      return [];
    }
  }

  // Get watchlist items (both movies and TV shows)
  Future<List<MovieModel>> getWatchlistMovies() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .orderBy('addedAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<MovieModel> watchlistItems = [];

      // Process items in batches to improve performance
      const batchSize = 5;
      for (int i = 0; i < querySnapshot.docs.length; i += batchSize) {
        final endIdx = i + batchSize < querySnapshot.docs.length
            ? i + batchSize : querySnapshot.docs.length;

        final batch = querySnapshot.docs.sublist(i, endIdx);
        final futures = batch.map((doc) async {
          final data = doc.data();
          final itemId = data['itemId'] as String;
          final isMovie = data['isMovie'] as bool;

          final item = await getMovieDetails(itemId, isMovie: isMovie);
          return item;
        }).toList();

        final results = await Future.wait(futures);
        watchlistItems.addAll(results.whereType<MovieModel>());
      }

      return watchlistItems;
    } catch (e) {
      print('Error getting watchlist items: $e');
      return [];
    }
  }

  // Favorites methods
  Future<bool> addToFavorites(String itemId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final favoriteItem = {
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .add(favoriteItem);

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      // Delete all instances (should be only one, but just in case)
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  Future<bool> isInFavorites(String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking favorites: $e');
      return false;
    }
  }

  // Get favorite items (both movies and TV shows)
  Future<List<MovieModel>> getFavoriteMovies() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      List<MovieModel> favoriteItems = [];

      // Process items in batches to improve performance
      const batchSize = 5;
      for (int i = 0; i < querySnapshot.docs.length; i += batchSize) {
        final endIdx = i + batchSize < querySnapshot.docs.length
            ? i + batchSize : querySnapshot.docs.length;

        final batch = querySnapshot.docs.sublist(i, endIdx);
        final futures = batch.map((doc) async {
          final data = doc.data();
          final itemId = data['itemId'] as String;
          final isMovie = data['isMovie'] as bool;

          final item = await getMovieDetails(itemId, isMovie: isMovie);
          return item;
        }).toList();

        final results = await Future.wait(futures);
        favoriteItems.addAll(results.whereType<MovieModel>());
      }

      return favoriteItems;
    } catch (e) {
      print('Error getting favorite items: $e');
      return [];
    }
  }

  // List methods
  Future<bool> addToList(String listId, String itemId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final listRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('lists')
          .doc(listId);

      // Get the current list
      final listDoc = await listRef.get();
      if (!listDoc.exists) {
        return false;
      }

      // Update the list
      await listRef.update({
        'itemIds': FieldValue.arrayUnion([itemId]),
        'itemCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add the item details to the list_items subcollection
      await listRef.collection('items').add({
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding to list: $e');
      return false;
    }
  }

  // new fetching method
  Future<List<MovieModel>> getImprovedSimilarMovies(String movieId, bool isMovie) async {
    try {
      // First, get the movie details to understand its genres, cast, etc.
      final movie = await getMovieDetails(movieId, isMovie: isMovie);

      if (movie == null) {
        return [];
      }

      // Get base similar movies from API
      final String endpoint = isMovie
          ? '${ApiConstants.baseUrl}/movie/$movieId/similar'
          : '${ApiConstants.baseUrl}/tv/$movieId/similar';

      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US&page=1',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      List<MovieModel> similarMovies = (data['results'] as List)
          .map((json) => MovieModel.fromMap(json))
          .toList();

      // Set isMovie flag
      for (var item in similarMovies) {
        item.isMovie = isMovie;
      }

      // Add sequels/prequels for movies (if they exist)
      if (isMovie && movie.title.isNotEmpty) {
        final sequels = await _searchForSequels(movie.title);

        // Add sequels/prequels that aren't already in the similar list
        final existingIds = similarMovies.map((m) => m.id).toSet();
        for (var sequel in sequels) {
          if (!existingIds.contains(sequel.id) && sequel.id != movieId) {
            similarMovies.add(sequel);
          }
        }
      }

      // Prioritize:
      // 1. Movies with same director/creator
      // 2. Movies with common cast members
      // 3. Movies in the same genre with high ratings

      // Sort by relevance
      similarMovies.sort((a, b) {
        // Calculate relevance score
        int scoreA = _calculateRelevanceScore(a, movie);
        int scoreB = _calculateRelevanceScore(b, movie);

        // Sort by score (descending)
        return scoreB.compareTo(scoreA);
      });

      // Limit to top 10 most relevant
      if (similarMovies.length > 10) {
        similarMovies = similarMovies.sublist(0, 10);
      }

      return similarMovies;
    } catch (e) {
      print('Error getting improved similar movies: $e');
      return [];
    }
  }

// Helper method to search for sequels/prequels
  Future<List<MovieModel>> _searchForSequels(String title) async {
    // Extract base movie name (remove numbers and common sequel indicators)
    final baseTitle = title.replaceAll(RegExp(r'\s*\d+\s*$'), '')
        .replaceAll(RegExp(r'\s*:\s*.*$'), '')
        .trim();

    if (baseTitle.length < 3) {
      return [];
    }

    // Search for movies with similar title
    final response = await _client.get(
      Uri.parse(
        '${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$baseTitle&page=1',
      ),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final Map<String, dynamic> data = json.decode(response.body);
    List<MovieModel> results = (data['results'] as List)
        .map((json) => MovieModel.fromMap(json))
        .toList();

    // Filter results to find likely sequels/prequels
    return results.where((movie) {
      // Check if title starts with the base title
      if (!movie.title.toLowerCase().startsWith(baseTitle.toLowerCase())) {
        return false;
      }

      // Check for sequel/prequel indicators
      final sequelPattern = RegExp(
        r'\s+(part\s+\d+|chapter\s+\d+|\d+|ii|iii|iv|v|vi|vii|viii|ix|x)$',
        caseSensitive: false,
      );

      return sequelPattern.hasMatch(movie.title.toLowerCase()) ||
          movie.title.toLowerCase().contains(':');
    }).toList();
  }

// Helper method to calculate relevance score for similar movies
  int _calculateRelevanceScore(MovieModel movie, MovieModel referenceMovie) {
    int score = 0;

    // Check for same director/creator
    if (movie.director == referenceMovie.director ||
        movie.creator == referenceMovie.creator) {
      score += 50;
    }

    // Check for common cast members
    final referenceCastIds = referenceMovie.cast.map((c) => c.id).toSet();
    for (var castMember in movie.cast) {
      if (referenceCastIds.contains(castMember.id)) {
        score += 10;
      }
    }

    // Check for matching genres
    final referenceGenres = referenceMovie.genres.toSet();
    for (var genre in movie.genres) {
      if (referenceGenres.contains(genre)) {
        score += 5;
      }
    }

    // Bonus for high ratings
    if (movie.voteAverage >= 7.5) {
      score += 15;
    } else if (movie.voteAverage >= 6.5) {
      score += 10;
    } else if (movie.voteAverage >= 5.0) {
      score += 5;
    }

    return score;
  }

// Add this method to get better "You Might Also Like" recommendations
  Future<List<MovieModel>> getYouMightAlsoLike(String movieId, bool isMovie) async {
    try {
      // First get the movie details
      final movie = await getMovieDetails(movieId, isMovie: isMovie);

      if (movie == null) {
        return [];
      }

      // Get base recommendations from API
      final String endpoint = isMovie
          ? '${ApiConstants.baseUrl}/movie/$movieId/recommendations'
          : '${ApiConstants.baseUrl}/tv/$movieId/recommendations';

      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US&page=1',
        ),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.body);
      List<MovieModel> recommendations = (data['results'] as List)
          .map((json) => MovieModel.fromMap(json))
          .toList();

      // Set isMovie flag
      for (var item in recommendations) {
        item.isMovie = isMovie;
      }

      // If we don't have enough recommendations, supplement with popular items in same genre
      if (recommendations.length < 8 && movie.genres.isNotEmpty) {
        final mainGenre = movie.genres.first;

        // Find matching genre ID
        int? genreId;
        for (var entry in ApiConstants.genres.entries) {
          if (entry.value.toLowerCase() == mainGenre.toLowerCase()) {
            genreId = entry.key;
            break;
          }
        }

        if (genreId != null) {
          // Get popular items in this genre
          final genreItems = isMovie
              ? await getMoviesByGenre(genreId, page: 1)
              : await getTVShowsByGenre(genreId, page: 1);

          // Add non-duplicate items from genre search
          final existingIds = recommendations.map((m) => m.id).toSet();
          for (var item in genreItems) {
            if (!existingIds.contains(item.id) && item.id != movieId) {
              recommendations.add(item);
              if (recommendations.length >= 10) break;
            }
          }
        }
      }

      // Sort by popularity and rating
      recommendations.sort((a, b) {
        // First by vote average (high to low)
        final ratingCompare = b.voteAverage.compareTo(a.voteAverage);
        if (ratingCompare != 0) return ratingCompare;

        // Then by vote count (high to low) as a proxy for popularity
        return b.voteCount.compareTo(a.voteCount);
      });

      // Limit to top 10
      if (recommendations.length > 10) {
        recommendations = recommendations.sublist(0, 10);
      }

      return recommendations;
    } catch (e) {
      print('Error getting you might also like: $e');
      return [];
    }
  }
  // new fetching method

  Future<List<MovieModel>> getNowPlayingMoviesInRange({
    required String startDate,
    required String endDate,
    int page = 1
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.nowPlayingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&primary_release_date.gte=$startDate&primary_release_date.lte=$endDate',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load now playing movies');
      }
    } catch (e) {
      print('Error fetching now playing movies in range: $e');
      return [];
    }
  }

  Future<List<MovieModel>> getUpcomingMoviesWithReleaseDate({int page = 1}) async {
    try {
      // Get current date
      final now = DateTime.now();
      final nowFormatted = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.upcomingMovies}?api_key=${ApiConstants.apiKey}&language=en-US&page=$page&primary_release_date.gte=$nowFormatted',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = results.map((json) => MovieModel.fromMap(json)).toList();

        // Set isMovie flag
        for (var movie in movies) {
          movie.isMovie = true;
        }

        return movies;
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      print('Error fetching upcoming movies with release date: $e');
      return [];
    }
  }

  Future<SeasonModel?> getSeasonDetails(String tvId, int seasonNumber) async {
    try {
      final endpoint = '${ApiConstants.baseUrl}/tv/$tvId/season/$seasonNumber';
      final response = await _client.get(
        Uri.parse(
          '$endpoint?api_key=${ApiConstants.apiKey}&language=en-US',
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      return SeasonModel.fromMap(data);
    } catch (e) {
      print('Error getting season details: $e');
      return null;
    }
  }

  Future<bool> removeFromList(String listId, String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final listRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('lists')
          .doc(listId);

      // Get the current list
      final listDoc = await listRef.get();
      if (!listDoc.exists) {
        return false;
      }

      // Update the list
      await listRef.update({
        'itemIds': FieldValue.arrayRemove([itemId]),
        'itemCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove the item from the list_items subcollection
      final querySnapshot = await listRef
          .collection('items')
          .where('itemId', isEqualTo: itemId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error removing from list: $e');
      return false;
    }
  }
}