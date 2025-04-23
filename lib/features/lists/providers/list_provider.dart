import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/list_model.dart';
import '../../../models/movie_model.dart';
import '../../../core/constants/app_constants.dart';

class ListProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final MovieService _movieService = MovieService();

  bool _isLoading = false;
  String? _error;

  ListModel? _currentList;
  List<MovieModel> _listItems = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  ListModel? get currentList => _currentList;
  List<MovieModel> get listItems => _listItems;

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

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return null;
      }

      final userId = currentUser.uid;
      final now = DateTime.now();

      // Create list document
      final listData = {
        'userId': userId,
        'name': name,
        'description': description,
        'coverImageUrl': '',
        'isPublic': isPublic,
        'allowMovies': allowMovies,
        'allowTvShows': allowTvShows,
        'itemIds': [],
        'createdAt': now,
        'updatedAt': now,
        'itemCount': 0,
      };

      // Add to Firestore
      final listRef = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.listsCollection)
          .add(listData);

      // If cover image is provided, upload it
      if (coverImage != null) {
        final imageUrl = await _storageService.uploadListCoverImage(
          userId,
          listRef.id,
          coverImage,
        );

        // Update list with cover image URL
        await listRef.update({
          'coverImageUrl': imageUrl,
        });

        listData['coverImageUrl'] = imageUrl;
      }

      // Create list model and set as current list
      _currentList = ListModel.fromMap(listData, listRef.id);

      _setLoading(false);
      return listRef.id;
    } catch (e) {
      _setError('Failed to create list: $e');
      return null;
    }
  }

  // Get list by ID
  Future<bool> getListById(String listId) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Query for the list
      final listDoc = await _firestore
          .collectionGroup(AppConstants.listsCollection)
          .where(FieldPath.documentId, isEqualTo: listId)
          .get();

      if (listDoc.docs.isEmpty) {
        _setError('List not found');
        return false;
      }

      // Get list data
      final data = listDoc.docs.first.data();
      final userId = data['userId'] as String;

      // Check if list is public or belongs to current user
      final isPublic = data['isPublic'] as bool;
      final isOwner = userId == currentUser.uid;

      if (!isPublic && !isOwner) {
        _setError('You do not have permission to view this list');
        return false;
      }

      // Create list model
      _currentList = ListModel.fromMap(data, listId);

      // Get list items
      await getListItems();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to get list: $e');
      return false;
    }
  }

  // Get list items
  Future<void> getListItems() async {
    if (_currentList == null) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final itemIds = _currentList!.itemIds;
      _listItems = [];

      // Fetch items in batches of 20
      for (var i = 0; i < itemIds.length; i += 20) {
        final end = (i + 20 < itemIds.length) ? i + 20 : itemIds.length;
        final batch = itemIds.sublist(i, end);

        // Fetch movies/TV shows in parallel
        final futures = batch.map((id) async {
          final movie = await _movieService.getMovieDetails(id);
          return movie;
        }).toList();

        final results = await Future.wait(futures);

        // Add non-null results
        _listItems.addAll(results.whereType<MovieModel>());
      }

      _setLoading(false);
    } catch (e) {
      _setError('Failed to get list items: $e');
    }
  }

  // Add item to list
  Future<bool> addItemToList(String itemId, bool isMovie) async {
    if (_currentList == null) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Verify ownership
      if (_currentList!.userId != currentUser.uid) {
        _setError('You do not have permission to modify this list');
        return false;
      }

      // Check if item is already in the list
      if (_currentList!.itemIds.contains(itemId)) {
        _setError('This item is already in the list');
        return false;
      }

      // Check content type allowed
      if (isMovie && !_currentList!.allowMovies) {
        _setError('Movies are not allowed in this list');
        return false;
      }

      if (!isMovie && !_currentList!.allowTvShows) {
        _setError('TV shows are not allowed in this list');
        return false;
      }

      // Update list in Firestore
      final listRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .collection(AppConstants.listsCollection)
          .doc(_currentList!.id);

      await listRef.update({
        'itemIds': FieldValue.arrayUnion([itemId]),
        'itemCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final updatedItemIds = [..._currentList!.itemIds, itemId];
      _currentList = _currentList!.copyWith(
        itemIds: updatedItemIds,
        itemCount: updatedItemIds.length,
        updatedAt: DateTime.now(),
      );

      // Get the movie details and add to list items
      final movie = await _movieService.getMovieDetails(itemId);
      if (movie != null) {
        _listItems.add(movie);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to add item to list: $e');
      return false;
    }
  }

  // Remove item from list
  Future<bool> removeItemFromList(String itemId) async {
    if (_currentList == null) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Verify ownership
      if (_currentList!.userId != currentUser.uid) {
        _setError('You do not have permission to modify this list');
        return false;
      }

      // Update list in Firestore
      final listRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .collection(AppConstants.listsCollection)
          .doc(_currentList!.id);

      await listRef.update({
        'itemIds': FieldValue.arrayRemove([itemId]),
        'itemCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final updatedItemIds = _currentList!.itemIds.where((id) => id != itemId).toList();
      _currentList = _currentList!.copyWith(
        itemIds: updatedItemIds,
        itemCount: updatedItemIds.length,
        updatedAt: DateTime.now(),
      );

      // Remove from list items
      _listItems.removeWhere((item) => item.id == itemId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to remove item from list: $e');
      return false;
    }
  }

  // Delete list
  Future<bool> deleteList() async {
    if (_currentList == null) {
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      // Verify ownership
      if (_currentList!.userId != currentUser.uid) {
        _setError('You do not have permission to delete this list');
        return false;
      }

      // Delete list from Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser.uid)
          .collection(AppConstants.listsCollection)
          .doc(_currentList!.id)
          .delete();

      // Delete cover image if exists
      if (_currentList!.coverImageUrl.isNotEmpty) {
        await _storageService.deleteImage(_currentList!.coverImageUrl);
      }

      // Clear local data
      _currentList = null;
      _listItems = [];

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to delete list: $e');
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

  // Clear current list
  void clearCurrentList() {
    _currentList = null;
    _listItems = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}