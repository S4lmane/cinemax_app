import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Upload profile image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Generate unique file name
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${userId}_${_uuid.v4()}$fileExtension';

      // Create storage reference
      final storageRef = _storage.ref()
          .child(AppConstants.profileImagesPath)
          .child(userId)
          .child(fileName);

      // Upload file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Get download URL
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  // Upload banner image
  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      // Generate unique file name
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${userId}_${_uuid.v4()}$fileExtension';

      // Create storage reference
      final storageRef = _storage.ref()
          .child(AppConstants.bannerImagesPath)
          .child(userId)
          .child(fileName);

      // Upload file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Get download URL
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      rethrow;
    }
  }

  // Upload list cover image
  Future<String> uploadListCoverImage(String userId, String listId, File imageFile) async {
    try {
      // Generate unique file name
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${listId}_${_uuid.v4()}$fileExtension';

      // Create storage reference
      final storageRef = _storage.ref()
          .child(AppConstants.listCoversPath)
          .child(userId)
          .child(fileName);

      // Upload file
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Get download URL
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading list cover image: $e');
      rethrow;
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        return;
      }

      // Get storage reference from URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw error if deletion fails
    }
  }
}