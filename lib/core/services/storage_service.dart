import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      debugPrint('Uploading profile image for user: $userId');

      // Generate unique file name
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${userId}_${_uuid.v4()}$fileExtension';

      // IMPORTANT: Use the direct path that matches your storage rules
      // Change to match your rules exactly
      final storageRef = _storage.ref()
          .child('users') // Changed from AppConstants.profileImagesPath
          .child(userId)
          .child(fileName);

      debugPrint('Uploading profile image to path: ${storageRef.fullPath}');

      // Make sure the file is valid
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Get file size to verify it's not empty
      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('Image file is empty');
      }

      // Upload file with proper content type
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Track upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: $progress%');
      });

      // Get download URL once complete
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Upload successful! URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Upload banner image
  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      debugPrint('Uploading banner image for user: $userId');

      // Generate unique file name
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${userId}_${_uuid.v4()}$fileExtension';

      // IMPORTANT: Use the direct path that matches your storage rules
      final storageRef = _storage.ref()
          .child('users') // Changed from AppConstants.bannerImagesPath
          .child(userId)
          .child('banner') // Add subfolder for organization
          .child(fileName);

      debugPrint('Uploading banner image to path: ${storageRef.fullPath}');

      // Make sure the file is valid
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Get file size to verify it's not empty
      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('Image file is empty');
      }

      // Upload file with proper content type
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Track upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: $progress%');
      });

      // Get download URL once complete
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Upload successful! URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      throw Exception('Failed to upload banner image: $e');
    }
  }

  // Upload list cover image
  Future<String> uploadListCoverImage(String userId, String listId, File imageFile) async {
    try {
      debugPrint('Uploading list cover image - User: $userId, List: $listId');

      // Generate unique file name
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${listId}_${_uuid.v4()}$fileExtension';

      // IMPORTANT: Use the direct path that matches your storage rules
      final storageRef = _storage.ref()
          .child('users') // Changed from AppConstants.listCoversPath
          .child(userId)
          .child('lists')
          .child(listId)
          .child('cover$fileExtension');

      debugPrint('Uploading list cover to path: ${storageRef.fullPath}');

      // Make sure the file is valid
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Get file size to verify it's not empty
      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('Image file is empty');
      }

      // Upload file with proper content type
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Get download URL once complete
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Upload successful! URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading list cover image: $e');
      throw Exception('Failed to upload list cover image: $e');
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        return;
      }

      debugPrint('Deleting image: $imageUrl');

      // Get storage reference from URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('Image deleted successfully');
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Don't throw error if deletion fails
    }
  }
}