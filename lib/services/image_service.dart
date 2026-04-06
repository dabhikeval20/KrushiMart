import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  ImageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// 📸 Pick image from camera
  /// Returns File if selected, null if cancelled
  static Future<File?> pickImageFromCamera() async {
    try {
      debugPrint('📷 Opening camera...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        debugPrint('❌ Camera cancelled by user');
        return null;
      }

      debugPrint('✅ Image captured: ${image.path}');
      return File(image.path);
    } catch (e) {
      debugPrint('❌ Camera error: $e');
      throw Exception('Failed to capture image from camera: $e');
    }
  }

  /// 🖼️ Pick image from gallery
  /// Returns File if selected, null if cancelled
  static Future<File?> pickImageFromGallery() async {
    try {
      debugPrint('🖼️ Opening gallery...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        debugPrint('❌ Gallery cancelled by user');
        return null;
      }

      debugPrint('✅ Image selected: ${image.path}');
      return File(image.path);
    } catch (e) {
      debugPrint('❌ Gallery error: $e');
      throw Exception('Failed to select image from gallery: $e');
    }
  }

  /// ☁️ Upload image to Firebase Storage
  /// Returns download URL, throws exception if fails
  static Future<String> uploadProductImage({
    required File imageFile,
    required String userId,
    required String productName,
  }) async {
    try {
      debugPrint('⏳ Starting image upload...');

      // Create unique file path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'product_${userId}_$timestamp.jpg';
      final ref = _storage.ref().child('products/$userId/$fileName');

      // Upload file
      debugPrint('📤 Uploading to Firebase Storage...');
      await ref.putFile(imageFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ Upload successful: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase Storage error: ${e.message}');
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// 🗑️ Delete image from Firebase Storage by URL
  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      debugPrint('🗑️ Deleting image: $imageUrl');
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('✅ Image deleted successfully');
    } catch (e) {
      debugPrint('⚠️ Failed to delete image: $e');
      // Don't throw - this is a non-critical operation
    }
  }

  /// 🔄 Replace product image
  /// Deletes old image and uploads new one
  static Future<String> replaceProductImage({
    required File newImageFile,
    required String? oldImageUrl,
    required String userId,
    required String productName,
  }) async {
    try {
      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProductImage(oldImageUrl);
      }

      // Upload new image
      final newImageUrl = await uploadProductImage(
        imageFile: newImageFile,
        userId: userId,
        productName: productName,
      );

      return newImageUrl;
    } catch (e) {
      debugPrint('❌ Replace image error: $e');
      rethrow;
    }
  }
}
