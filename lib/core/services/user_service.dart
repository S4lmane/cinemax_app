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
      debugPrint('Creating user profile for $uid with email $email and username $username');

      // Validate inputs
      if (uid.isEmpty || email.isEmpty || username.isEmpty) {
        throw Exception('Invalid user data: uid, email, and username are required');
      }

      final userDoc = _usersCollection.doc(uid);

      // Check if user already exists
      final userSnapshot = await userDoc.get();
      if (userSnapshot.exists) {
        debugPrint('User profile already exists for $uid');
        return;
      }

      // Ensure username is unique
      final uniqueUsername = await _ensureUniqueUsername(username, uid);

      // Generate a default nickname if not provided
      final userNickname = nickname?.isNotEmpty == true ? nickname! : uniqueUsername;

      // Create user document with proper timestamp handling
      final now = DateTime.now();
      final userData = {
        'uid': uid,
        'email': email,
        'username': uniqueUsername,
        'nickname': userNickname,
        'profileImageUrl': '',
        'bannerImageUrl': '',
        'isModerator': false,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      // Use a transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Double-check user doesn't exist
        final userExists = await transaction.get(userDoc);
        if (userExists.exists) {
          debugPrint('User already exists, skipping creation');
          return;
        }

        // Set user document
        transaction.set(userDoc, userData);

        debugPrint('User document created in transaction');
      });

      debugPrint('Successfully created user profile for $uid with username: $uniqueUsername');

    } catch (e) {
      debugPrint('Error creating user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Ensure username is unique
  Future<String> _ensureUniqueUsername(String baseUsername, String currentUid) async {
    try {
      // Check if username already exists (excluding current user)
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: baseUsername)
          .limit(1)
          .get();
// and to get
      // If no documents or the document is for the current user, username is available
      if (querySnapshot.docs.isEmpty ||
          (querySnapshot.docs.length == 1 && querySnapshot.docs.first.id == currentUid)) {
        return baseUsername;
      }

      // Generate unique username with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final uniqueUsername = '${baseUsername}_$timestamp';

      debugPrint('Username $baseUsername already exists, using $uniqueUsername');
      return uniqueUsername;
    } catch (e) {
      debugPrint('Error checking username uniqueness: $e');
      // If there's an error checking, use timestamp-based username
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      return '${baseUsername}_$timestamp';
    }
  }

  // Get user data from Firestore with improved error handling
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      debugPrint('Getting user profile for $uid');

      if (uid.isEmpty) {
        debugPrint('Empty UID provided');
        return null;
      }

      final userDoc = await _usersCollection.doc(uid).get();

      if (!userDoc.exists) {
        debugPrint('User profile not found for $uid');

        // Try to create user if it's the current user
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.uid == uid && currentUser.email != null) {
          debugPrint('Attempting to create profile for current user');
          String username = currentUser.email!.split('@')[0].toLowerCase();
          await createUserProfile(
            uid: uid,
            email: currentUser.email!,
            username: username,
            nickname: username,
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

      final userData = userDoc.data() as Map<String, dynamic>;

      // Ensure required fields exist
      if (!userData.containsKey('username') || userData['username'] == null || userData['username'].toString().isEmpty) {
        debugPrint('User profile missing username, updating...');
        // Generate username from email if missing
        String username = userData['email']?.split('@')[0]?.toLowerCase() ?? 'user${DateTime.now().millisecondsSinceEpoch}';
        username = await _ensureUniqueUsername(username, uid);

        await _usersCollection.doc(uid).update({
          'username': username,
          'nickname': userData['nickname'] ?? username,
        });

        userData['username'] = username;
        userData['nickname'] = userData['nickname'] ?? username;
      }

      debugPrint('Successfully retrieved user profile for $uid');
      return UserModel.fromMap(userData, uid);
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

      if (uid.isEmpty) {
        throw Exception('UID cannot be empty');
      }

      final userDoc = _usersCollection.doc(uid);
      final Map<String, dynamic> data = {};

      if (nickname != null && nickname.isNotEmpty) data['nickname'] = nickname;
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) data['profileImageUrl'] = profileImageUrl;
      if (bannerImageUrl != null && bannerImageUrl.isNotEmpty) data['bannerImageUrl'] = bannerImageUrl;

      // Only update if there are changes
      if (data.isNotEmpty) {
        data['lastLoginAt'] = FieldValue.serverTimestamp();

        // Use merge to avoid overwriting other fields
        await userDoc.set(data, SetOptions(merge: true));
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
      if (uid.isEmpty) return;

      await _usersCollection.doc(uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Updated last login for $uid');
    } catch (e) {
      debugPrint('Error updating last login: $e');
      // Don't throw here, it's not critical
    }
  }

  // Upload profile image to Firebase Storage with improved path handling
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      debugPrint('Starting profile image upload for user: $userId');

      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      // Validate the image file first
      final isValid = await _storageService.validateImageFile(imageFile);
      if (!isValid) {
        throw Exception('Invalid image file');
      }

      // Upload using storage service
      final imageUrl = await _storageService.uploadProfileImage(userId, imageFile);

      // Update user profile with the URL
      await updateUserProfile(uid: userId, profileImageUrl: imageUrl);

      debugPrint('Successfully uploaded and updated profile image for $userId');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Upload banner image to Firebase Storage with improved path handling
  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      debugPrint('Starting banner image upload for user: $userId');

      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      // Validate the image file first
      final isValid = await _storageService.validateImageFile(imageFile);
      if (!isValid) {
        throw Exception('Invalid image file');
      }

      // Upload using storage service
      final imageUrl = await _storageService.uploadBannerImage(userId, imageFile);

      // Update user profile with the URL
      await updateUserProfile(uid: userId, bannerImageUrl: imageUrl);

      debugPrint('Successfully uploaded and updated banner image for $userId');
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

            // Ensure itemIds is a list
            if (data['itemIds'] == null) {
              data['itemIds'] = [];
            }

            // Ensure itemCount matches itemIds length
            final itemIds = List<String>.from(data['itemIds'] ?? []);
            data['itemCount'] = itemIds.length;

            validLists.add(ListModel.fromMap(data, doc.id));
          } else {
            debugPrint('Skipping invalid list document: ${doc.id} - missing required fields');
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'itemCount': 0,
      };

      final docRef = await getUserListsCollection(userId).add(listData);
      debugPrint('Successfully created list with ID: ${docRef.id}');

      // Return the created list
      listData['createdAt'] = Timestamp.fromDate(now);
      listData['updatedAt'] = Timestamp.fromDate(now);
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
          await _storageService.deleteImage(coverImageUrl);
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

      // Use transaction for atomic operation
      return await _firestore.runTransaction((transaction) async {
        final listDoc = await transaction.get(listRef);

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
        transaction.update(listRef, {
          'itemIds': FieldValue.arrayUnion([itemId]),
          'itemCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Add to items subcollection
        final itemRef = listRef.collection('items').doc();
        transaction.set(itemRef, {
          'itemId': itemId,
          'isMovie': isMovie,
          'addedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Successfully added item to list');
        return true;
      });
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

      // Use transaction for atomic operation
      return await _firestore.runTransaction((transaction) async {
        final listDoc = await transaction.get(listRef);

        if (!listDoc.exists) {
          debugPrint('List not found: $listId');
          return false;
        }

        // Update the list
        transaction.update(listRef, {
          'itemIds': FieldValue.arrayRemove([itemId]),
          'itemCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Note: We'll handle items subcollection deletion outside the transaction
        debugPrint('Successfully removed item from list');
        return true;
      }).then((success) async {
        if (success) {
          // Remove from items subcollection (outside transaction)
          try {
            final itemsQuery = await listRef.collection('items')
                .where('itemId', isEqualTo: itemId)
                .get();

            for (var doc in itemsQuery.docs) {
              await doc.reference.delete();
            }
          } catch (e) {
            debugPrint('Error cleaning up items subcollection: $e');
            // Don't fail the operation for this
          }
        }
        return success;
      });
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