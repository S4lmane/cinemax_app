import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/user_service.dart';
import '../../../models/user_model.dart';
import '../../../models/list_model.dart';

class ProfileProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _error;
  UserModel? _userProfile;
  List<ListModel> _userLists = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get userProfile => _userProfile;
  List<ListModel> get userLists => _userLists;

  // Initialize user profile
  Future<void> initializeUserProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _setError('No authenticated user found');
      return;
    }

    await getUserProfile(currentUser.uid);
    await getUserLists(currentUser.uid);
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

  // Create a new list
  Future<bool> createList({
    required String name,
    required String description,
    required bool isPublic,
    required bool allowMovies,
    required bool allowTvShows,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _setError('No authenticated user found');
        return false;
      }

      await _userService.createList(
        name: name,
        description: description,
        isPublic: isPublic,
        allowMovies: allowMovies,
        allowTvShows: allowTvShows,
      );

      await getUserLists(currentUser.uid);
      return true;
    } catch (e) {
      _setError('Failed to create list');
      print('Error creating list: $e');
      return false;
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
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}