import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/movie_service.dart';
import '../../../core/utils/notification_service.dart';
import '../../../models/user_model.dart';
import '../../../models/list_model.dart';
import '../../../models/movie_model.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final MovieService _movieService = MovieService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // General loading state
  bool _isLoading = false;

  // Specific loading states for different sections
  bool _isLoadingWatchlist = false;
  bool _isLoadingFavorites = false;

  String? _error;
  UserModel? _userProfile;

  // Content lists
  List<ListModel> _userLists = [];
  List<MovieModel> _watchlistItems = [];
  List<MovieModel> _favoriteItems = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingWatchlist => _isLoadingWatchlist;
  bool get isLoadingFavorites => _isLoadingFavorites;
  String? get error => _error;
  UserModel? get userProfile => _userProfile;
  List<ListModel> get userLists => _userLists;
  List<MovieModel> get watchlistItems => _watchlistItems;
  List<MovieModel> get favoriteItems => _favoriteItems;

  // Initialize user profile
  Future<void> initializeUserProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('No authenticated user found');
      return;
    }

    await getUserProfile(currentUser.uid);
    await getUserLists(currentUser.uid);
    await getWatchlistItems();
    await getFavoriteItems();
  }

  // Get user profile
  Future<void> getUserProfile(String uid) async {
    _setLoading(true);
    _clearError();

    try {
      final profile = await _userService.getUserProfile(uid);
      _userProfile = profile;

      if (profile == null) {
        _setError('Failed to load user profile');
      }
    } catch (e) {
      _setError('Failed to load user profile');
      print('Error getting user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get user lists
  Future<void> getUserLists(String uid) async {
    _setLoading(true);
    _clearError();

    try {
      final lists = await _userService.getUserLists(uid);
      _userLists = lists;
    } catch (e) {
      _setError('Failed to load user lists');
      print('Error getting user lists: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get watchlist items
  Future<void> getWatchlistItems() async {
    _isLoadingWatchlist = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isLoadingWatchlist = false;
        notifyListeners();
        return;
      }

      final watchlistMovies = await _movieService.getWatchlistMovies();
      _watchlistItems = watchlistMovies;
    } catch (e) {
      print('Error getting watchlist items: $e');
    } finally {
      _isLoadingWatchlist = false;
      notifyListeners();
    }
  }

  // Get favorite items
  Future<void> getFavoriteItems() async {
    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isLoadingFavorites = false;
        notifyListeners();
        return;
      }

      final favoriteMovies = await _movieService.getFavoriteMovies();
      _favoriteItems = favoriteMovies;
    } catch (e) {
      print('Error getting favorite items: $e');
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  // Refresh watchlist
  Future<void> refreshWatchlist() async {
    await getWatchlistItems();
  }

  // Refresh favorites
  Future<void> refreshFavorites() async {
    await getFavoriteItems();
  }

  // Remove from watchlist
  Future<bool> removeFromWatchlist(String movieId) async {
    try {
      final success = await _movieService.removeFromWatchlist(movieId);
      if (success) {
        // Remove the item from local list
        _watchlistItems.removeWhere((movie) => movie.id == movieId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(String movieId) async {
    try {
      final success = await _movieService.removeFromFavorites(movieId);
      if (success) {
        // Remove the item from local list
        _favoriteItems.removeWhere((movie) => movie.id == movieId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({String? nickname}) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      await _userService.updateUserProfile(
        uid: currentUser.uid,
        nickname: nickname,
      );

      await getUserProfile(currentUser.uid);
      return true;
    } catch (e) {
      _setError('Failed to update user profile');
      print('Error updating user profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      final imageUrl = await _userService.uploadProfileImage(
        currentUser.uid,
        imageFile,
      );

      await _userService.updateUserProfile(
        uid: currentUser.uid,
        profileImageUrl: imageUrl,
      );

      await getUserProfile(currentUser.uid);
      return true;
    } catch (e) {
      _setError('Failed to upload profile image');
      print('Error uploading profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload banner image
  Future<bool> uploadBannerImage(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      final imageUrl = await _userService.uploadBannerImage(
        currentUser.uid,
        imageFile,
      );

      await _userService.updateUserProfile(
        uid: currentUser.uid,
        bannerImageUrl: imageUrl,
      );

      await getUserProfile(currentUser.uid);
      return true;
    } catch (e) {
      _setError('Failed to upload banner image');
      print('Error uploading banner image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload list cover image
  Future<bool> uploadListCoverImage(String listId, File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Use StorageService to upload the image
      final storageService = await _userService.getStorageService();
      final imageUrl = await storageService.uploadListCoverImage(
        currentUser.uid,
        listId,
        imageFile,
      );

      // Update list cover in Firestore
      final success = await _userService.updateListCover(
        currentUser.uid,
        listId,
        imageUrl,
      );

      if (success) {
        // Update local list data
        final index = _userLists.indexWhere((list) => list.id == listId);
        if (index != -1) {
          _userLists[index] = _userLists[index].copyWith(
            coverImageUrl: imageUrl,
          );
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _setError('Failed to upload list cover image');
      print('Error uploading list cover image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create a new list
  Future<ListModel?> createList({
    required String name,
    required String description,
    required bool isPublic,
    required bool allowMovies,
    required bool allowTvShows,
    File? coverImage,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return null;
      }

      final newList = await _userService.createList(
        name: name,
        description: description,
        isPublic: isPublic,
        allowMovies: allowMovies,
        allowTvShows: allowTvShows,
      );

      if (newList != null && coverImage != null) {
        // Upload cover image if provided
        await uploadListCoverImage(newList.id, coverImage);
      }

      // Refresh lists
      await getUserLists(currentUser.uid);
      return newList;
    } catch (e) {
      _setError('Failed to create list');
      print('Error creating list: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear all data
  void clearData() {
    _userProfile = null;
    _userLists = [];
    _watchlistItems = [];
    _favoriteItems = [];
    _error = null;
    _isLoading = false;
    _isLoadingWatchlist = false;
    _isLoadingFavorites = false;
    notifyListeners();
  }
}