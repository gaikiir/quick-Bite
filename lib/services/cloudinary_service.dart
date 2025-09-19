import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryService {
  // Cloudinary configuration - using config file
  static String get cloudName => CloudinaryConfig.cloudName;
  static String get uploadPreset => CloudinaryConfig.uploadPreset;
  static String get apiKey => CloudinaryConfig.apiKey;

  // Upload image to Cloudinary
  static Future<String?> uploadImage({
    File? imageFile,
    Uint8List? webImage,
    String? fileName,
  }) async {
    try {
      if (imageFile == null && webImage == null) {
        throw Exception('No image provided');
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['api_key'] = apiKey;

      // Add file based on platform
      if (kIsWeb && webImage != null) {
        // For web, use bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webImage,
            filename:
                fileName ??
                'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else if (!kIsWeb && imageFile != null) {
        // For mobile/desktop, use file
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            filename:
                fileName ??
                'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      } else {
        throw Exception('Invalid image data for platform');
      }

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseString);
        return jsonResponse['secure_url'] as String?;
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - $responseString',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Cloudinary (optional - requires admin API)
  static Future<bool> deleteImage(String publicId) async {
    try {
      // Note: This requires server-side implementation for security
      // as it needs the API secret key
      debugPrint(
        'Delete image not implemented - requires server-side implementation',
      );
      return false;
    } catch (e) {
      debugPrint('Cloudinary delete error: $e');
      return false;
    }
  }

  // Extract public ID from Cloudinary URL
  static String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('cloudinary.com')) {
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          // Remove 'v' version segment and file extension
          final publicIdWithExt = pathSegments.sublist(1).join('/');
          return publicIdWithExt.split('.').first;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting public ID: $e');
      return null;
    }
  }

  // Validate Cloudinary configuration
  static bool isConfigured() {
    return CloudinaryConfig.isConfigured;
  }
}
