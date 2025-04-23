import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/user_model.dart';
import '../../models/list_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference getUserListsCollection(String userId) =>
      _usersCollection.doc(userId).collection('lists');
  CollectionReference getUserWatchlistCollection(String userId) =>
      _usersCollection.doc(userId).collection('watchlist');

  // Create a new user in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String? nickname,
  }) async {
    final userDoc = _usersCollection.doc(uid);

    // Check if username already exists
    final usernameQuery = await _usersCollection
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      throw Exception('Username already taken');
    }

    // Create user document
    final UserModel newUser = UserModel(
      uid: uid,
      email: email,
      username: username,
      nickname: nickname ?? username,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await userDoc.set(newUser.toMap());
  }

  // Get user data from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final userDoc = await _usersCollection.doc(uid).get();

      if (!userDoc.exists) {
        return null;
      }

      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, uid);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? nickname,
    String? profileImageUrl,
    String? bannerImageUrl,
  }) async {
    final Map<String, dynamic> data = {};

    if (nickname != null) data['nickname'] = nickname;
    if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
    if (bannerImageUrl != null) data['bannerImageUrl'] = bannerImageUrl;
    data['lastLoginAt'] = FieldValue.serverTimestamp();

    await _usersCollection.doc(uid).update(data);
  }

  // Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    await _usersCollection.doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final storageRef = _storage.ref().child('users/$uid/profile.jpg');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Upload banner image to Firebase Storage
  Future<String> uploadBannerImage(String uid, File imageFile) async {
    final storageRef = _storage.ref().child('users/$uid/banner.jpg');
    final uploadTask = storageRef.putFile(imageFile);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Get user lists
  Future<List<ListModel>> getUserLists(String userId) async {
    try {
      final querySnapshot = await getUserListsCollection(userId).get();

      return querySnapshot.docs.map((doc) {
        return ListModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting user lists: $e');
      return [];
    }
  }

  // Create a new list
  Future<ListModel> createList({
    required String name,
    required String description,
    required bool isPublic,
    required bool allowMovies,
    required bool allowTvShows,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
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
      'createdAt': now,
      'updatedAt': now,
      'itemCount': 0,
    };

    final docRef = await getUserListsCollection(userId).add(listData);

    return ListModel.fromMap(listData, docRef.id);
  }

  // Check if user is a moderator
  Future<bool> isUserModerator(String uid) async {
    final userDoc = await _usersCollection.doc(uid).get();
    if (!userDoc.exists) return false;

    final userData = userDoc.data() as Map<String, dynamic>;
    return userData['isModerator'] ?? false;
  }
}