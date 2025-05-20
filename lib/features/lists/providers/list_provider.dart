import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/movie_service.dart';
import '../../../models/list_model.dart';
import '../../../models/movie_model.dart';

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

  // Create a new list - FIXED VERSION
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

      // IMPORTANT: Make sure userId field is included and matches current user
      final listData = {
        'userId': userId,  // Critical field for security rules
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

      // Debug info about the list being created
      debugPrint('Creating new list: $name for user: $userId');

      // Add to Firestore - Try DIRECT string paths instead of constants
      // This ensures exact match with security rules
      final listRef = await _firestore
          .collection('users')  // Direct string instead of constant
          .doc(userId)
          .collection('lists')  // Direct string instead of constant
          .add(listData);

      debugPrint('List created with ID: ${listRef.id}');

      // If cover image is provided, upload it
      if (coverImage != null) {
        try {
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
          debugPrint('Cover image added to list: $imageUrl');
        } catch (e) {
          debugPrint('Error uploading cover image, continuing without image: $e');
          // Continue without image rather than failing the whole operation
        }
      }

      // Create list model and set as current list
      _currentList = ListModel.fromMap(listData, listRef.id);

      _setLoading(false);
      return listRef.id;
    } catch (e) {
      debugPrint('Error creating list: $e');
      _setError('Failed to create list: $e');
      return null;
    }
  }

  // Get list by ID - FIXED VERSION
  Future<bool> getListById(String listId) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      debugPrint('Getting list: $listId for user: ${currentUser.uid}');

      // IMPORTANT: First try direct path to the list using current user's ID
      DocumentSnapshot? listDoc;
      try {
        listDoc = await _firestore
            .collection('users')  // Direct string instead of constant
            .doc(currentUser.uid)
            .collection('lists')  // Direct string instead of constant
            .doc(listId)
            .get();

        debugPrint('Direct path list lookup result: ${listDoc.exists ? 'Found' : 'Not found'}');
      } catch (e) {
        debugPrint('Error with direct list lookup: $e');
      }

      // If not found, try to find it using a collection group query
      if (listDoc == null || !listDoc.exists) {
        debugPrint('List not found in user\'s lists, trying collection group query');

        final querySnapshot = await _firestore
            .collectionGroup('lists')  // Direct string instead of constant
            .where(FieldPath.documentId, isEqualTo: listId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          debugPrint('List not found in collection group either');
          _setError('List not found');
          _setLoading(false);
          return false;
        }

        listDoc = querySnapshot.docs.first;
        debugPrint('Found list via collection group query');
      }

      // Get list data
      final data = listDoc.data() as Map<String, dynamic>;

      // Debug the data structure
      debugPrint('List data: $data');

      // Check for required fields
      if (!data.containsKey('userId')) {
        debugPrint('WARNING: List is missing userId field!');
        _setError('Invalid list data: missing userId');
        _setLoading(false);
        return false;
      }

      final userId = data['userId'] as String;

      // Check if list is public or belongs to current user
      final isPublic = data['isPublic'] as bool? ?? false;
      final isOwner = userId == currentUser.uid;

      debugPrint('List access check - isPublic: $isPublic, isOwner: $isOwner');

      if (!isPublic && !isOwner) {
        debugPrint('Permission denied: List is private and user is not the owner');
        _setError('You do not have permission to view this list');
        _setLoading(false);
        return false;
      }

      // Create list model
      _currentList = ListModel.fromMap(data, listId);
      debugPrint('List loaded: ${_currentList!.name} with ${_currentList!.itemIds.length} items');

      // Get list items
      await getListItems();

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error getting list: $e');
      _setError('Failed to get list: $e');
      _setLoading(false);
      return false;
    }
  }

  // Get list items - FIXED VERSION
  Future<void> getListItems() async {
    if (_currentList == null) {
      debugPrint('Cannot get list items: no current list');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      debugPrint('Getting items for list: ${_currentList!.id}');

      final itemIds = _currentList!.itemIds;
      _listItems = [];

      // Add extra logging
      debugPrint('ItemIds from list document: $itemIds');
      debugPrint('Item count: ${itemIds.length}');

      if (itemIds.isEmpty) {
        debugPrint('List has no items, returning empty list');
        _setLoading(false);
        return;
      }

      // Fetch items in batches of 20 for better performance
      for (var i = 0; i < itemIds.length; i += 20) {
        final end = (i + 20 < itemIds.length) ? i + 20 : itemIds.length;
        final batch = itemIds.sublist(i, end);
        debugPrint('Getting batch ${i ~/ 20 + 1}: ${batch.length} items');

        // Fetch movies/TV shows in parallel
        final futures = batch.map((id) async {
          try {
            final movie = await _movieService.getMovieDetails(id);
            return movie;
          } catch (e) {
            debugPrint('Error fetching movie $id: $e');
            return null;
          }
        }).toList();

        final results = await Future.wait(futures);

        // Add non-null results
        final validResults = results.whereType<MovieModel>().toList();
        debugPrint('Got ${validResults.length} valid results from batch');
        _listItems.addAll(validResults);
      }

      debugPrint('Loaded ${_listItems.length} items total');
      _setLoading(false);
    } catch (e) {
      debugPrint('Error getting list items: $e');
      _setError('Failed to get list items: $e');
      _setLoading(false);
    }
  }

  // Add item to list - FIXED VERSION
  Future<bool> addItemToList(String itemId, bool isMovie) async {
    if (_currentList == null) {
      debugPrint('Cannot add item: no current list');
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

      debugPrint('Adding item $itemId to list ${_currentList!.id}, isMovie: $isMovie');

      // CRITICAL: Verify ownership
      if (_currentList!.userId != currentUser.uid) {
        debugPrint('Permission denied: User is not the list owner');
        debugPrint('List userId: ${_currentList!.userId}, current userId: ${currentUser.uid}');
        _setError('You do not have permission to modify this list');
        return false;
      }

      // Check if item is already in the list
      if (_currentList!.itemIds.contains(itemId)) {
        debugPrint('Item already in list');
        _setError('This item is already in the list');
        return false;
      }

      // Check content type allowed
      if (isMovie && !_currentList!.allowMovies) {
        debugPrint('Movies not allowed in this list');
        _setError('Movies are not allowed in this list');
        return false;
      }

      if (!isMovie && !_currentList!.allowTvShows) {
        debugPrint('TV shows not allowed in this list');
        _setError('TV shows are not allowed in this list');
        return false;
      }

      // Use DIRECT string paths for collection references
      final listRef = _firestore
          .collection('users')  // Direct string instead of constant
          .doc(currentUser.uid)
          .collection('lists')  // Direct string instead of constant
          .doc(_currentList!.id);

      // IMPORTANT: Use a transaction for atomic operations
      debugPrint('Starting transaction to add item');

      await _firestore.runTransaction((transaction) async {
        // Get fresh list data to ensure we're working with current version
        final listSnapshot = await transaction.get(listRef);

        if (!listSnapshot.exists) {
          debugPrint('List does not exist in transaction');
          throw Exception('List not found');
        }

        // Get current data including itemIds
        final data = listSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> currentItemIds = List<dynamic>.from(data['itemIds'] ?? []);

        // Skip if already in list
        if (currentItemIds.contains(itemId)) {
          debugPrint('Item already in list (detected in transaction)');
          return; // Exit transaction without error
        }

        // Update the list document
        transaction.update(listRef, {
          'itemIds': FieldValue.arrayUnion([itemId]),
          'itemCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('List document updated in transaction');

        // Add to items subcollection
        final itemRef = listRef.collection('items').doc();
        transaction.set(itemRef, {
          'itemId': itemId,
          'isMovie': isMovie,
          'addedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Item added to subcollection in transaction');
      });

      debugPrint('Transaction completed successfully');

      // Update local list model
      final updatedItemIds = [..._currentList!.itemIds, itemId];
      _currentList = _currentList!.copyWith(
        itemIds: updatedItemIds,
        itemCount: updatedItemIds.length,
        updatedAt: DateTime.now(),
      );

      // Get the movie details and add to list items
      try {
        final movie = await _movieService.getMovieDetails(itemId);
        if (movie != null) {
          _listItems.add(movie);
          debugPrint('Added movie to list items: ${movie.title}');
        }
      } catch (e) {
        debugPrint('Error getting movie details, but item was added to list: $e');
        // Don't fail the operation if we can't get movie details
      }

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error adding item to list: $e');
      _setError('Failed to add item to list: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove item from list - FIXED VERSION
  Future<bool> removeItemFromList(String itemId) async {
    if (_currentList == null) {
      debugPrint('Cannot remove item: no current list');
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

      debugPrint('Removing item $itemId from list ${_currentList!.id}');

      // CRITICAL: Verify ownership
      if (_currentList!.userId != currentUser.uid) {
        debugPrint('Permission denied: User is not the list owner');
        _setError('You do not have permission to modify this list');
        return false;
      }

      // Use DIRECT string paths for collection references
      final listRef = _firestore
          .collection('users')  // Direct string instead of constant
          .doc(currentUser.uid)
          .collection('lists')  // Direct string instead of constant
          .doc(_currentList!.id);

      // IMPORTANT: Use a transaction for atomic operations
      debugPrint('Starting transaction to remove item');

      await _firestore.runTransaction((transaction) async {
        // First get the list to verify it exists
        final listSnapshot = await transaction.get(listRef);

        if (!listSnapshot.exists) {
          debugPrint('List does not exist in transaction');
          throw Exception('List not found');
        }

        // Update the list document
        transaction.update(listRef, {
          'itemIds': FieldValue.arrayRemove([itemId]),
          'itemCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('List document updated in transaction');

        // Find items to delete from subcollection
        final querySnapshot = await listRef
            .collection('items')
            .where('itemId', isEqualTo: itemId)
            .get();

        debugPrint('Found ${querySnapshot.docs.length} items to delete from subcollection');

        // Delete each item document
        for (var doc in querySnapshot.docs) {
          transaction.delete(doc.reference);
        }

        debugPrint('Items deleted from subcollection in transaction');
      });

      debugPrint('Transaction completed successfully');

      // Update local list
      final updatedItemIds = _currentList!.itemIds.where((id) => id != itemId).toList();
      _currentList = _currentList!.copyWith(
        itemIds: updatedItemIds,
        itemCount: updatedItemIds.length,
        updatedAt: DateTime.now(),
      );

      // Remove from list items
      _listItems.removeWhere((item) => item.id == itemId);
      debugPrint('Item removed from local list');

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error removing item from list: $e');
      _setError('Failed to remove item from list: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete list - FIXED VERSION
  Future<bool> deleteList() async {
    if (_currentList == null) {
      debugPrint('Cannot delete list: no current list');
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

      debugPrint('Deleting list ${_currentList!.id}');

      // CRITICAL: Verify ownership
      if (_currentList!.userId != currentUser.uid) {
        debugPrint('Permission denied: User is not the list owner');
        _setError('You do not have permission to delete this list');
        return false;
      }

      // Use DIRECT string paths for collection references
      final listRef = _firestore
          .collection('users')  // Direct string instead of constant
          .doc(currentUser.uid)
          .collection('lists')  // Direct string instead of constant
          .doc(_currentList!.id);

      // First delete all items in the subcollection
      debugPrint('Deleting items subcollection');

      final itemsSnapshot = await listRef.collection('items').get();

      if (itemsSnapshot.docs.isNotEmpty) {
        debugPrint('Found ${itemsSnapshot.docs.length} items to delete');

        // Use a batch for efficient deletion
        final batch = _firestore.batch();
        for (var doc in itemsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        debugPrint('Items deleted successfully');
      } else {
        debugPrint('No items to delete');
      }

      // Now delete the list document
      await listRef.delete();
      debugPrint('List document deleted');

      // Delete cover image if exists
      if (_currentList!.coverImageUrl.isNotEmpty) {
        try {
          await _storageService.deleteImage(_currentList!.coverImageUrl);
          debugPrint('Cover image deleted');
        } catch (e) {
          debugPrint('Error deleting cover image: $e');
          // Continue even if image deletion fails
        }
      }

      // Clear local data
      _currentList = null;
      _listItems = [];
      debugPrint('Local list data cleared');

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Error deleting list: $e');
      _setError('Failed to delete list: $e');
      _setLoading(false);
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

  // Debug helpers

  // Print information about the current state
  void debugState() {
    debugPrint('=== ListProvider Debug State ===');
    debugPrint('isLoading: $_isLoading');
    debugPrint('error: $_error');
    debugPrint('currentList: ${_currentList?.name ?? 'null'}');
    debugPrint('currentList ID: ${_currentList?.id ?? 'null'}');
    debugPrint('currentList userId: ${_currentList?.userId ?? 'null'}');
    debugPrint('currentList itemCount: ${_currentList?.itemCount ?? 0}');
    debugPrint('listItems count: ${_listItems.length}');
    debugPrint('================================');
  }

  // Test path access for debugging
  Future<bool> testPathAccess() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user');
        return false;
      }

      debugPrint('Testing path access for user: ${currentUser.uid}');

      // Check users collection
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        debugPrint('User document exists: ${userDoc.exists}');
      } catch (e) {
        debugPrint('Error accessing user document: $e');
        return false;
      }

      // Check lists collection
      try {
        final listsQuery = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('lists')
            .limit(1)
            .get();

        debugPrint('Lists query successful, found ${listsQuery.docs.length} lists');

        if (listsQuery.docs.isNotEmpty) {
          final listId = listsQuery.docs.first.id;

          // Check items subcollection
          try {
            final itemsQuery = await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .collection('lists')
                .doc(listId)
                .collection('items')
                .get();

            debugPrint('Items query successful, found ${itemsQuery.docs.length} items');
          } catch (e) {
            debugPrint('Error accessing items subcollection: $e');
          }
        }
      } catch (e) {
        debugPrint('Error accessing lists collection: $e');
        return false;
      }

      // Test write access with a temporary document
      try {
        // Create a test document in a test collection
        final testDocRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('test_access')
            .doc();

        // Set data
        await testDocRef.set({
          'test': 'value',
          'timestamp': FieldValue.serverTimestamp(),
        });

        debugPrint('Test write successful');

        // Clean up
        await testDocRef.delete();
        debugPrint('Test document deleted');
      } catch (e) {
        debugPrint('Error testing write access: $e');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('General error in testPathAccess: $e');
      return false;
    }
  }
}