import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/user_model.dart';
import '../../../models/list_model.dart';
import '../../../models/movie_model.dart';
import '../../lists/providers/list_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final MovieService _movieService = MovieService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool _isLoading = false;
  bool _isLoadingWatchlist = false;
  bool _isLoadingFavorites = false;
  String? _error;
  UserModel? _userProfile;
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
  User? get currentUser => _auth.currentUser;

  // Initialize user profile
  Future<void> initializeUserProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('Authentication Error: No authenticated user found');
      _setError('No authenticated user found');
      return;
    }

    await Future.wait([
      getUserProfile(currentUser.uid),
      getUserLists(currentUser.uid),
      getWatchlistItems(),
      getFavoriteItems(),
    ]);
  }

  // Get user profile with better error handling and user creation if needed
  Future<void> getUserProfile(String uid) async {
    _setLoading(true);
    _clearError();

    try {
      // Try to get existing profile first
      var profile = await _userService.getUserProfile(uid);

      // If profile is null, we might need to create it
      if (profile == null) {
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Create a basic profile with username derived from email
          String username = currentUser.email!.split('@')[0];
          String nickname = username; // Default nickname is the same as username

          await _userService.createUserProfile(
              uid: currentUser.uid,
              email: currentUser.email!,
              username: username,
              nickname: nickname
          );

          // Fetch the newly created profile
          profile = await _userService.getUserProfile(uid);
        }
      }

      _userProfile = profile;

      if (profile == null) {
        throw Exception('Failed to load or create user profile');
      }
      print('User profile loaded: ${profile.nickname}, Username: ${profile.username}');
    } catch (e) {
      print('Error getting user profile: $e');
      _setError('Failed to load user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteListAndRefresh(String listId) async {
    try {
      final listProvider = ListProvider();

      // Set the current list first
      final success = await listProvider.getListById(listId);
      if (!success) {
        return false;
      }

      // Delete the list
      final deleted = await listProvider.deleteList();

      if (deleted) {
        // Remove the list from local state immediately
        _userLists.removeWhere((list) => list.id == listId);
        notifyListeners();

        // Refresh the lists to ensure UI is updated
        await getUserLists(userProfile?.uid ?? '');
      }

      return deleted;
    } catch (e) {
      print('Error in deleteListAndRefresh: $e');
      return false;
    }
  }

  // Get user username (if not part of UserModel)
  Future<String?> getUsername(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final data = userDoc.data()!;
      final username = data['username'] as String?;
      if (username == null || username.isEmpty) {
        throw Exception('Username not set for user');
      }
      return '@$username';
    } catch (e) {
      print('Error getting username: $e');
      _setError('Failed to load username: $e');
      return null;
    }
  }

  // Get user lists
  Future<void> getUserLists(String uid) async {
    _setLoading(true);
    _clearError();

    try {
      if (uid.isEmpty) {
        throw Exception('Invalid UID: UID cannot be empty');
      }

      print('Fetching lists for UID: $uid');

      final lists = await _userService.getUserLists(uid);
      _userLists = lists;

      // Sort lists in memory by updatedAt
      _userLists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      print('Error getting user lists `/Users/Documents/flutter/flutter_project/lib/features/profile/providers/profile_provider.dart lists`');
      print('Retrieved ${_userLists.length} lists');
    } finally {
      _setLoading(false);
    }
  }

  // Add an item to a list
  Future<bool> addItemToList(String listId, String itemId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Authentication Error: No authenticated user found');
        _setError('No authenticated user found');
        return false;
      }

      print('Adding item $itemId to list $listId for user ${currentUser.uid}');

      final listDoc = await FirebaseFirestore.instance
          .collection('lists')
          .doc(listId)
          .get();

      if (!listDoc.exists) {
        print('List $listId does not exist');
        _setError('List does not exist');
        return false;
      }

      final listData = listDoc.data()!;
      if (listData['userId'] != currentUser.uid) {
        print('Permission Error: User ${currentUser.uid} does not own list $listId');
        _setError('You do not have permission to modify this list');
        return false;
      }

      List<String> currentItemIds = List<String>.from(listData['itemIds'] ?? []);
      if (currentItemIds.contains(itemId)) {
        print('Item $itemId already in list $listId');
        return true;
      }

      currentItemIds.add(itemId);

      await FirebaseFirestore.instance
          .collection('lists')
          .doc(listId)
          .update({
        'itemIds': currentItemIds,
        'itemCount': currentItemIds.length,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('Item $itemId added to list $listId successfully');

      final index = _userLists.indexWhere((list) => list.id == listId);
      if (index != -1) {
        _userLists[index] = _userLists[index].copyWith(
          itemIds: currentItemIds,
          itemCount: currentItemIds.length,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Error adding item to list: $e');
      _setError('Failed to add item to list: $e');
      return false;
    }
  }

  // Get watchlist items with better isMovie handling
  Future<void> getWatchlistItems() async {
    _isLoadingWatchlist = true;
    notifyListeners();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final watchlistMovies = await _movieService.getWatchlistMovies();
      _watchlistItems = watchlistMovies;
    } catch (e) {
      print('Error getting watchlist items: $e');
      _setError('Failed to load watchlist items: $e');
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
        throw Exception('No authenticated user found');
      }

      final favoriteMovies = await _movieService.getFavoriteMovies();
      _favoriteItems = favoriteMovies;
    } catch (e) {
      print('Error getting favorite items: $e');
      _setError('Failed to load favorite items: $e');
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
        _watchlistItems.removeWhere((movie) => movie.id == movieId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error removing from watchlist: $e');
      _setError('Failed to remove from watchlist: $e');
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeFromFavorites(String movieId) async {
    try {
      final success = await _movieService.removeFromFavorites(movieId);
      if (success) {
        _favoriteItems.removeWhere((movie) => movie.id == movieId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error removing from favorites: $e');
      _setError('Failed to remove from favorites: $e');
      return false;
    }
  }

  // Update user profile with better error handling
  Future<bool> updateUserProfile({String? nickname}) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      await _userService.updateUserProfile(
        uid: currentUser.uid,
        nickname: nickname,
      );

      await getUserProfile(currentUser.uid);
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      _setError('Failed to update user profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload profile image with robust error handling
  Future<bool> uploadProfileImage(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('Uploading profile image for user: ${currentUser.uid}');
      final imageUrl = await _userService.uploadProfileImage(
        currentUser.uid,
        imageFile,
      );

      // Update Firestore document directly to ensure it gets updated
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user profile
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          profileImageUrl: imageUrl,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error uploading profile image: $e');
      _setError('Failed to upload profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload banner image with robust error handling
  Future<bool> uploadBannerImage(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('Uploading banner image for user: ${currentUser.uid}');
      final imageUrl = await _userService.uploadBannerImage(
        currentUser.uid,
        imageFile,
      );

      // Update Firestore document directly to ensure it gets updated
      await _firestore.collection('users').doc(currentUser.uid).update({
        'bannerImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local user profile
      if (_userProfile != null) {
        _userProfile = _userProfile!.copyWith(
          bannerImageUrl: imageUrl,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error uploading banner image: $e');
      _setError('Failed to upload banner image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload list cover image with direct Firestore update
  Future<bool> uploadListCoverImage(String listId, File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('Uploading list cover image for user: ${currentUser.uid}, list: $listId');
      final storageService = await _userService.getStorageService();
      final imageUrl = await storageService.uploadListCoverImage(
        currentUser.uid,
        listId,
        imageFile,
      );

      // Update list cover in Firestore directly
      await _firestore
          .collection('lists')
          .doc(listId)
          .update({
        'coverImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list data
      final index = _userLists.indexWhere((list) => list.id == listId);
      if (index != -1) {
        _userLists[index] = _userLists[index].copyWith(
          coverImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Error uploading list cover image: $e');
      _setError('Failed to upload list cover image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create a new list
  Future<String?> createList({
    required String name,
    required String description,
    required bool isPublic,
    required bool allowMovies,
    required bool allowTvShows,
    File? coverImage,
  }) async {
    _setLoading(true);
    _clearError();

    String? createdListId;

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('Creating list for user: ${currentUser.uid}');

      final now = DateTime.now();
      final listData = {
        'userId': currentUser.uid,
        'name': name,
        'description': description,
        'coverImageUrl': '',
        'isPublic': isPublic,
        'allowMovies': allowMovies,
        'allowTvShows': allowTvShows,
        'itemIds': <String>[],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'itemCount': 0,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('lists')
          .add(listData);

      createdListId = docRef.id;
      print('List created with ID: $createdListId');

      if (coverImage != null) {
        final success = await uploadListCoverImage(createdListId, coverImage);
        if (!success) {
          print('Warning: Failed to upload cover image, but list was created');
          _setError('List created, but failed to upload cover image');
        }
      }

      try {
        await getUserLists(currentUser.uid);
      } catch (e) {
        print('Warning: Failed to refresh lists after creation: $e');
        _setError('List created, but failed to refresh lists: $e');
      }

      return createdListId;
    } catch (e) {
      print('Error creating list: $e');
      _setError('Failed to create list: $e');
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

  void _setLoadingWatchlist(bool value) {
    _isLoadingWatchlist = value;
    notifyListeners();
  }

  void _setLoadingFavorites(bool value) {
    _isLoadingFavorites = value;
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

  void _notifySafely() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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