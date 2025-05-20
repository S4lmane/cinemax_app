// lib/core/services/user_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../models/user_model.dart';
import '../../models/list_model.dart';
import 'storage_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference getUserListsCollection(String userId) =>
      _usersCollection.doc(userId).collection('lists');

  CollectionReference getUserWatchlistCollection(String userId) =>
      _usersCollection.doc(userId).collection('watchlist');

  CollectionReference getUserFavoritesCollection(String userId) =>
      _usersCollection.doc(userId).collection('favorites');

  // Get the storage service instance
  Future<StorageService> getStorageService() async {
    return _storageService;
  }

  // Create a new user in Firestore with improved error handling
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String? nickname,
  }) async {
    try {
      debugPrint('Creating user profile for $uid with email $email');
      final userDoc = _usersCollection.doc(uid);

      // Check if user already exists
      final userSnapshot = await userDoc.get();
      if (userSnapshot.exists) {
        debugPrint('User profile already exists for $uid');
        return;
      }

      // Check if username already exists
      final usernameQuery = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        // Add a random number to make it unique
        final randomSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        username = '${username}_$randomSuffix';
        debugPrint('Username already exists, changed to $username');
      }

      // Generate a default nickname if not provided
      nickname = nickname ?? username;

      // Create user document with Timestamp for better compatibility
      final UserModel newUser = UserModel(
        uid: uid,
        email: email,
        username: username,
        nickname: nickname,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      final userData = newUser.toMap();

      // Convert DateTime to Timestamp for Firestore
      userData['createdAt'] = Timestamp.fromDate(newUser.createdAt);
      userData['lastLoginAt'] = Timestamp.fromDate(newUser.lastLoginAt);

      await userDoc.set(userData);
      debugPrint('Successfully created user profile for $uid');

      // Create default collections
      userDoc.collection('lists').doc(); // Create the lists collection
      userDoc.collection('watchlist').doc(); // Create the watchlist collection
      userDoc.collection('favorites').doc(); // Create the favorites collection

    } catch (e) {
      debugPrint('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user data from Firestore with improved error handling
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      debugPrint('Getting user profile for $uid');
      final userDoc = await _usersCollection.doc(uid).get();

      if (!userDoc.exists) {
        debugPrint('User profile not found for $uid');

        // Try to create user if it's the current user
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid && currentUser.email != null) {
          debugPrint('Attempting to create profile for current user');
          String username = currentUser.email!.split('@')[0];
          await createUserProfile(
            uid: uid,
            email: currentUser.email!,
            username: username,
          );

          // Get the newly created user
          final newUserDoc = await _usersCollection.doc(uid).get();
          if (newUserDoc.exists) {
            debugPrint('Successfully created and retrieved user profile');
            return UserModel.fromMap(newUserDoc.data() as Map<String, dynamic>, uid);
          }
        }
        return null;
      }

      debugPrint('Successfully retrieved user profile for $uid');
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, uid);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile with improved error handling
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
    String? bannerImageUrl,
  }) async {
    try {
      debugPrint('Updating user profile for $uid');
      debugPrint('nickname: $nickname, profileImageUrl: $profileImageUrl, bannerImageUrl: $bannerImageUrl');

      final userDoc = _usersCollection.doc(uid);
      final Map<String, dynamic> data = {};

      if (nickname != null && nickname.isNotEmpty) data['nickname'] = nickname;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) data['profileImageUrl'] = profileImageUrl;
      if (bannerImageUrl != null && bannerImageUrl.isNotEmpty) data['bannerImageUrl'] = bannerImageUrl;

      // Only update if there are changes
      if (data.isNotEmpty) {
        data['lastLoginAt'] = FieldValue.serverTimestamp();
        await userDoc.update(data);
        debugPrint('Successfully updated user profile for $uid');
      } else {
        debugPrint('No changes to update for user $uid');
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Updated last login for $uid');
    } catch (e) {
      debugPrint('Error updating last login: $e');
      // Don't throw here, it's not critical
    }
  }

  // Upload profile image to Firebase Storage with improved path handling
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Generate a unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(imageFile.path);

      // Use a path compatible with Firebase storage rules
      final storageRef = _storage.ref()
          .child('users')
          .child(userId)
          .child('profile_$timestamp$extension');

      debugPrint('Uploading profile image to path: ${storageRef.fullPath}');

      // Upload file with content type
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.substring(1)}'),
      );

      // Get download URL
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Successfully uploaded profile image, URL: $imageUrl');

      // Update user profile with the URL
      await updateUserProfile(uid: userId, profileImageUrl: imageUrl);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Upload banner image to Firebase Storage with improved path handling
  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      // Generate a unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(imageFile.path);

      // Use a path compatible with Firebase storage rules
      final storageRef = _storage.ref()
          .child('users')
          .child(userId)
          .child('banner_$timestamp$extension');

      debugPrint('Uploading banner image to path: ${storageRef.fullPath}');

      // Upload file with content type
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.substring(1)}'),
      );

      // Get download URL
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Successfully uploaded banner image, URL: $imageUrl');

      // Update user profile with the URL
      await updateUserProfile(uid: userId, bannerImageUrl: imageUrl);

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      throw Exception('Failed to upload banner image: $e');
    }
  }

  // Get user lists with better error handling and data validation
  Future<List<ListModel>> getUserLists(String userId) async {
    try {
      debugPrint('Getting lists for user: $userId');

      if (userId.isEmpty) {
        debugPrint('Empty userId provided, returning empty list');
        return [];
      }

      final querySnapshot = await getUserListsCollection(userId)
          .orderBy('updatedAt', descending: true)
          .get();

      debugPrint('Found ${querySnapshot.docs.length} lists for user $userId');

      List<ListModel> validLists = [];
      for (var doc in querySnapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          // Ensure the data has required fields
          if (data.containsKey('name') && data.containsKey('userId')) {
            // Ensure timestamp fields are properly handled
            if (data['createdAt'] == null) {
              data['createdAt'] = Timestamp.now();
            }

            if (data['updatedAt'] == null) {
              data['updatedAt'] = Timestamp.now();
            }

            validLists.add(ListModel.fromMap(data, doc.id));
          } else {
            debugPrint('Skipping invalid list document: ${doc.id}');
          }
        } catch (e) {
          debugPrint('Error processing list document ${doc.id}: $e');
          // Skip this document and continue
        }
      }

      debugPrint('Returning ${validLists.length} valid lists');
      return validLists;
    } catch (e) {
      debugPrint('Error getting user lists: $e');
      return [];
    }
  }

  // Create a new list with improved error handling
  Future<ListModel?> createList({
    required String name,
    required String description,
    required bool isPublic,
    required bool allowMovies,
    required bool allowTvShows,
  }) async {
    try {
      debugPrint('Creating new list: $name');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final userId = currentUser.uid;
      final now = DateTime.now();

      final listData = {
        'userId': userId,
        'name': name,
        'description': description,
        'coverImageUrl': '',
        'isPublic': isPublic,
        'allowMovies': allowMovies,
        'allowTvShows': allowTvShows,
        'itemIds': [],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'itemCount': 0,
      };

      final docRef = await getUserListsCollection(userId).add(listData);
      debugPrint('Successfully created list with ID: ${docRef.id}');
      return ListModel.fromMap(listData, docRef.id);
    } catch (e) {
      debugPrint('Error creating list: $e');
      return null;
    }
  }

  // Update list cover image
  Future<bool> updateListCover(String userId, String listId, String imageUrl) async {
    try {
      debugPrint('Updating cover image for list $listId');
      await getUserListsCollection(userId).doc(listId).update({
        'coverImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Successfully updated list cover image');
      return true;
    } catch (e) {
      debugPrint('Error updating list cover: $e');
      return false;
    }
  }

  // Delete a list
  Future<bool> deleteList(String listId) async {
    try {
      debugPrint('Deleting list: $listId');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      // Get the list to check ownership
      final listDoc = await getUserListsCollection(currentUser.uid).doc(listId).get();
      if (!listDoc.exists) {
        debugPrint('List not found: $listId');
        return false;
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      if (listData['userId'] != currentUser.uid) {
        // Only the owner can delete the list
        debugPrint('User is not the owner of the list');
        return false;
      }

      // Delete items subcollection first
      final itemsRef = getUserListsCollection(currentUser.uid).doc(listId).collection('items');
      final itemsSnapshot = await itemsRef.get();

      debugPrint('Deleting ${itemsSnapshot.docs.length} items from list');
      for (var doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete list cover image if exists
      final coverImageUrl = listData['coverImageUrl'] as String? ?? '';
      if (coverImageUrl.isNotEmpty) {
        try {
          debugPrint('Deleting list cover image: $coverImageUrl');
          final ref = _storage.refFromURL(coverImageUrl);
          await ref.delete();
        } catch (e) {
          // Ignore errors when deleting images
          debugPrint('Error deleting list cover image: $e');
        }
      }

      // Delete the list document
      await getUserListsCollection(currentUser.uid).doc(listId).delete();
      debugPrint('Successfully deleted list: $listId');
      return true;
    } catch (e) {
      debugPrint('Error deleting list: $e');
      return false;
    }
  }

  // Add item to list with improved error handling
  Future<bool> addItemToList({
    required String listId,
    required String itemId,
    required bool isMovie,
  }) async {
    try {
      debugPrint('Adding item $itemId to list $listId, isMovie: $isMovie');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      final listRef = getUserListsCollection(currentUser.uid).doc(listId);
      final listDoc = await listRef.get();

      if (!listDoc.exists) {
        debugPrint('List not found: $listId');
        return false;
      }

      final listData = listDoc.data() as Map<String, dynamic>;
      final List<dynamic> itemIds = List<dynamic>.from(listData['itemIds'] ?? []);

      // Check if item already exists in the list
      if (itemIds.contains(itemId)) {
        debugPrint('Item already exists in list');
        return true; // Item already exists, consider it success
      }

      // Update the list document
      await listRef.update({
        'itemIds': FieldValue.arrayUnion([itemId]),
        'itemCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add to items subcollection
      await listRef.collection('items').add({
        'itemId': itemId,
        'isMovie': isMovie,
        'addedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Successfully added item to list');
      return true;
    } catch (e) {
      debugPrint('Error adding item to list: $e');
      return false;
    }
  }

  // Remove item from list
  Future<bool> removeItemFromList({
    required String listId,
    required String itemId,
  }) async {
    try {
      debugPrint('Removing item $itemId from list $listId');
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      final listRef = getUserListsCollection(currentUser.uid).doc(listId);
      final listDoc = await listRef.get();

      if (!listDoc.exists) {
        debugPrint('List not found: $listId');
        return false;
      }

      // Update the list
      await listRef.update({
        'itemIds': FieldValue.arrayRemove([itemId]),
        'itemCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from items subcollection
      final itemsQuery = await listRef.collection('items')
          .where('itemId', isEqualTo: itemId)
          .get();

      for (var doc in itemsQuery.docs) {
        await doc.reference.delete();
      }

      debugPrint('Successfully removed item from list');
      return true;
    } catch (e) {
      debugPrint('Error removing item from list: $e');
      return false;
    }
  }

  // Check if user is a moderator
  Future<bool> isUserModerator(String uid) async {
    try {
      final userDoc = await _usersCollection.doc(uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() as Map<String, dynamic>;
      return userData['isModerator'] ?? false;
    } catch (e) {
      debugPrint('Error checking moderator status: $e');
      return false;
    }
  }
}