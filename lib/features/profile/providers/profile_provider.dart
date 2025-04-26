import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Get user profile
  Future<void> getUserProfile(String uid) async {
    _setLoading(true);
    _clearError();

    try {
      final profile = await _userService.getUserProfile(uid);
      if (profile == null) {
        throw Exception('User profile not found');
      }
      _userProfile = profile;
      print('User profile loaded: ${profile.nickname}, Username: ${profile.username}');
    } catch (e) {
      print('Error getting user profile: $e');
      _setError('Failed to load user profile: $e');
    } finally {
      _setLoading(false);
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

      final querySnapshot = await FirebaseFirestore.instance
          .collection('lists')
          .where('userId', isEqualTo: uid)
          .get();

      print('Retrieved ${querySnapshot.docs.length} lists');

      _userLists = querySnapshot.docs
          .map((doc) => ListModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort lists in memory by updatedAt (avoiding orderBy due to SDK issue)
      _userLists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      print('Error getting user lists: $e');
      _setError('Failed to load user lists: $e');
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
        _notifySafely();
      }

      return true;
    } catch (e) {
      print('Error adding item to list: $e');
      _setError('Failed to add item to list: $e');
      return false;
    }
  }

  // Get watchlist items
  Future<void> getWatchlistItems() async {
    _setLoadingWatchlist(true);
    _clearError();

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
      _setLoadingWatchlist(false);
    }
  }

  // Get favorite items
  Future<void> getFavoriteItems() async {
    _setLoadingFavorites(true);
    _clearError();

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
      _setLoadingFavorites(false);
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
        _notifySafely();
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
        _notifySafely();
      }
      return success;
    } catch (e) {
      print('Error removing from favorites: $e');
      _setError('Failed to remove from favorites: $e');
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

  // Upload profile image
  Future<bool> uploadProfileImage(File imageFile) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      print('Uploading profile image for user: ${currentUser.uid}');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${currentUser.uid}/profile.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed: ${snapshot.state}');
      }

      await Future.delayed(Duration(seconds: 1));
      final imageUrl = await storageRef.getDownloadURL();
      print('Profile image uploaded successfully: $imageUrl');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'profileImageUrl': imageUrl});

      await getUserProfile(currentUser.uid);
      return true;
    } catch (e) {
      print('Error uploading profile image: $e');
      _setError('Failed to upload profile image: $e');
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
        throw Exception('No authenticated user found');
      }

      print('Uploading banner image for user: ${currentUser.uid}');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('banner_images/${currentUser.uid}/banner.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed: ${snapshot.state}');
      }

      await Future.delayed(Duration(seconds: 1));
      final imageUrl = await storageRef.getDownloadURL();
      print('Banner image uploaded successfully: $imageUrl');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'bannerImageUrl': imageUrl});

      await getUserProfile(currentUser.uid);
      return true;
    } catch (e) {
      print('Error uploading banner image: $e');
      _setError('Failed to upload banner image: $e');
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
        throw Exception('No authenticated user found');
      }

      print('Uploading list cover image for user: ${currentUser.uid}, list: $listId');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('list_covers/${currentUser.uid}/$listId.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed: ${snapshot.state}');
      }

      await Future.delayed(Duration(seconds: 1));
      final imageUrl = await storageRef.getDownloadURL();
      print('List cover image uploaded successfully: $imageUrl');

      await FirebaseFirestore.instance
          .collection('lists')
          .doc(listId)
          .update({
        'coverImageUrl': imageUrl,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      final index = _userLists.indexWhere((list) => list.id == listId);
      if (index != -1) {
        _userLists[index] = _userLists[index].copyWith(
          coverImageUrl: imageUrl,
          updatedAt: DateTime.now(),
        );
        _notifySafely();
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
    _notifySafely();
  }

  void _setLoadingWatchlist(bool value) {
    _isLoadingWatchlist = value;
    _notifySafely();
  }

  void _setLoadingFavorites(bool value) {
    _isLoadingFavorites = value;
    _notifySafely();
  }

  void _setError(String error) {
    _error = error;
    _notifySafely();
  }

  void _clearError() {
    _error = null;
    _notifySafely();
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
    _notifySafely();
  }
}