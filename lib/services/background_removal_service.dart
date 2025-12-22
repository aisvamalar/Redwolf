import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/supabase_config.dart';

/// Service for removing backgrounds from product images
/// Uses remove.bg API for background removal (when configured)
/// Falls back to CSS filters for web when API is not available
class BackgroundRemovalService {
  static const String _apiUrl = 'https://api.remove.bg/v1.0/removebg';
  
  // Cache to store processed image URLs
  static final Map<String, String> _cache = {};

  /// Remove background from an image URL
  /// Returns the processed image URL with transparent background
  static Future<String?> removeBackground(String imageUrl) async {
    // Check cache first
    if (_cache.containsKey(imageUrl)) {
      return _cache[imageUrl];
    }

    // If background removal is enabled and API key is configured, use remove.bg API
    if (SupabaseConfig.enableBackgroundRemoval && 
        SupabaseConfig.removeBgApiKey != 'YOUR_REMOVE_BG_API_KEY' && 
        SupabaseConfig.removeBgApiKey.isNotEmpty) {
      return _removeBackgroundWithAPI(imageUrl);
    }

    // For web, apply CSS filter effect to make background appear lighter/removed
    // This is a visual effect, not true background removal
    if (kIsWeb) {
      // Return original image - we'll apply CSS filters in the widget
      return imageUrl;
    }

    // For mobile/desktop, return original image
    return imageUrl;
  }

  /// Remove background using remove.bg API
  static Future<String?> _removeBackgroundWithAPI(String imageUrl) async {
    try {
      // Download the image
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) {
        print('❌ Failed to download image: ${imageResponse.statusCode}');
        return imageUrl;
      }

      // Send to remove.bg API
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['X-Api-Key'] = SupabaseConfig.removeBgApiKey;
      request.files.add(
        http.MultipartFile.fromBytes(
          'image_file',
          imageResponse.bodyBytes,
          filename: 'image.jpg',
        ),
      );
      request.fields['size'] = 'auto';

      final response = await request.send();
      final responseBody = await response.stream.toBytes();

      if (response.statusCode == 200) {
        // Upload processed image to Supabase or use base64
        // For now, we'll use a data URL (base64)
        final base64Image = base64Encode(responseBody);
        final processedUrl = 'data:image/png;base64,$base64Image';
        
        // Cache the result
        _cache[imageUrl] = processedUrl;
        
        return processedUrl;
      } else {
        print('❌ Background removal failed: ${response.statusCode}');
        print('Response: ${String.fromCharCodes(responseBody)}');
        return imageUrl;
      }
    } catch (e) {
      print('❌ Error removing background: $e');
      return imageUrl;
    }
  }

  /// Clear the cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get cached processed URL if available
  static String? getCachedUrl(String originalUrl) {
    return _cache[originalUrl];
  }
}
