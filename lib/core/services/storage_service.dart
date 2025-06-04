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

      // Validate file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('Image file is empty');
      }

      // Generate unique file name with proper extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      if (fileExtension.isEmpty) {
        throw Exception('Invalid file extension');
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Use storage path that matches Firebase Storage rules
      final storageRef = _storage.ref().child('users/$userId/images/$fileName');

      debugPrint('Uploading to path: ${storageRef.fullPath}');

      // Set proper metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload with retry logic
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Profile image upload successful! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<String> uploadBannerImage(String userId, File imageFile) async {
    try {
      debugPrint('Uploading banner image for user: $userId');

      // Validate file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('Image file is empty');
      }

      // Generate unique file name with proper extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      if (fileExtension.isEmpty) {
        throw Exception('Invalid file extension');
      }

      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Use storage path that matches Firebase Storage rules
      final storageRef = _storage.ref().child('users/$userId/images/$fileName');

      debugPrint('Uploading to path: ${storageRef.fullPath}');

      // Set proper metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'imageType': 'banner',
        },
      );

      // Upload with retry logic
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Banner image upload successful! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading banner image: $e');
      throw Exception('Failed to upload banner image: $e');
    }
  }

  Future<String> uploadListCoverImage(String userId, String listId, File imageFile) async {
    try {
      debugPrint('Uploading list cover image - User: $userId, List: $listId');

      // Validate file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('Image file is empty');
      }

      // Generate unique file name with proper extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      if (fileExtension.isEmpty) {
        throw Exception('Invalid file extension');
      }

      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Use storage path that matches Firebase Storage rules
      final storageRef = _storage.ref().child('users/$userId/lists/$listId/$fileName');

      debugPrint('Uploading to path: ${storageRef.fullPath}');

      // Set proper metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'listId': listId,
          'imageType': 'cover',
        },
      );

      // Upload with retry logic
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(1)}%');
      });

      // Wait for completion
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('List cover upload successful! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading list cover image: $e');
      throw Exception('Failed to upload list cover image: $e');
    }
  }

  // Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        debugPrint('No image URL provided for deletion');
        return;
      }

      debugPrint('Deleting image: $imageUrl');

      // Get storage reference from URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('Image deleted successfully');
    } catch (e) {
      debugPrint('Error deleting image (non-critical): $e');
      // Don't throw error if deletion fails - it's not critical
    }
  }

  // Helper method to get proper content type
  String _getContentType(String fileExtension) {
    switch (fileExtension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  // Helper method to validate image file
  bool _isValidImageFile(String filePath) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final fileExtension = path.extension(filePath).toLowerCase();
    return validExtensions.contains(fileExtension);
  }

  // Get file size in MB for validation
  Future<double> getFileSizeInMB(File file) async {
    try {
      final bytes = await file.length();
      return bytes / (1024 * 1024);
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0.0;
    }
  }

  // Validate image file before upload
  Future<bool> validateImageFile(File imageFile, {double maxSizeMB = 10.0}) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('File does not exist');
      }

      // Check file extension
      if (!_isValidImageFile(imageFile.path)) {
        throw Exception('Invalid image file type');
      }

      // Check file size
      final sizeInMB = await getFileSizeInMB(imageFile);
      if (sizeInMB > maxSizeMB) {
        throw Exception('File size exceeds ${maxSizeMB}MB limit');
      }

      // Check if file is readable
      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw Exception('File is empty');
      }

      return true;
    } catch (e) {
      debugPrint('Image validation failed: $e');
      return false;
    }
  }
}