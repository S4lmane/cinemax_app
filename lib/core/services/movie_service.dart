import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/movie_model.dart';
import '../constants/api_constants.dart';

class MovieService {
  final http.Client _client = http.Client();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // TMDB API methods
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

        return results.map((json) => MovieModel.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load now playing movies');
      }
    } catch (e) {
      print('Error fetching now playing movies: $e');
      return [];
    }
  }

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

        return results.map((json) => MovieModel.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load popular movies');
      }
    } catch (e) {
      print('Error fetching popular movies: $e');
      return [];
    }
  }

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

        return results.map((json) => MovieModel.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load upcoming movies');
      }
    } catch (e) {
      print('Error fetching upcoming movies: $e');
      return [];
    }
  }

  Future<MovieModel?> getMovieDetails(String movieId) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}&language=en-US&append_to_response=credits,videos,similar',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return MovieModel.fromMap(data);
      } else {
        throw Exception('Failed to load movie details');
      }
    } catch (e) {
      print('Error fetching movie details: $e');
      return null;
    }
  }

  Future<List<MovieModel>> searchMovies(String query, {int page = 1}) async {
    if (query.isEmpty) return [];

    try {
      final response = await _client.get(
        Uri.parse(
          '${ApiConstants.searchMovie}?api_key=${ApiConstants.apiKey}&language=en-US&query=$query&page=$page&include_adult=false',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        return results.map((json) => MovieModel.fromMap(json)).toList();
      } else {
        throw Exception('Failed to search movies');
      }
    } catch (e) {
      print('Error searching movies: $e');
      return [];
    }
  }

  // Watchlist methods
  Future<bool> addToWatchlist(String movieId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final watchlistItem = {
        'itemId': movieId,
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

  Future<bool> removeFromWatchlist(String movieId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .where('itemId', isEqualTo: movieId)
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

  Future<bool> isInWatchlist(String movieId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('watchlist')
          .where('itemId', isEqualTo: movieId)
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
          .map((doc) => (doc.data() as Map<String, dynamic>)['itemId'] as String)
          .toList();
    } catch (e) {
      print('Error getting watchlist IDs: $e');
      return [];
    }
  }

  // Favorites methods
  Future<bool> addToFavorites(String movieId, bool isMovie) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final favoriteItem = {
        'itemId': movieId,
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

  Future<bool> removeFromFavorites(String movieId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('itemId', isEqualTo: movieId)
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

  Future<bool> isInFavorites(String movieId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .where('itemId', isEqualTo: movieId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking favorites: $e');
      return false;
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

  // Get movies from watchlist
  Future<List<MovieModel>> getWatchlistMovies() async {
    try {
      final watchlistIds = await getWatchlistIds();
      if (watchlistIds.isEmpty) return [];

      List<MovieModel> watchlistMovies = [];

      // Due to API limitations, we need to fetch each movie individually
      for (var id in watchlistIds) {
        final movie = await getMovieDetails(id);
        if (movie != null) {
          watchlistMovies.add(movie);
        }
      }

      return watchlistMovies;
    } catch (e) {
      print('Error getting watchlist movies: $e');
      return [];
    }
  }

  // Get favorite movies
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

      final favoriteIds = querySnapshot.docs
          .map((doc) => (doc.data()['itemId'] as String))
          .toList();

      List<MovieModel> favoriteMovies = [];

      // Due to API limitations, we need to fetch each movie individually
      for (var id in favoriteIds) {
        final movie = await getMovieDetails(id);
        if (movie != null) {
          favoriteMovies.add(movie);
        }
      }

      return favoriteMovies;
    } catch (e) {
      print('Error getting favorite movies: $e');
      return [];
    }
  }
}