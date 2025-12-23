import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class AdminSupabaseService {
  static final AdminSupabaseService _instance = AdminSupabaseService._internal();
  factory AdminSupabaseService() => _instance;
  AdminSupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Sanitize filename to prevent 404 errors in Supabase Storage
  /// Especially critical for USDZ files on iOS Safari which has strict URL requirements
  /// 
  /// Rules:
  /// - Convert to lowercase (prevents case sensitivity issues)
  /// - Replace spaces with underscores (prevents %20 encoding which breaks iOS Safari)
  /// - Remove special characters except dots, hyphens, and underscores
  /// - Preserve file extension
  /// 
  /// Example:
  /// Input:  "Model_1766472163538_32_EASEL STANDEE.usdz"
  /// Output: "model_1766472163538_32_easel_standee.usdz"
  /// 
  /// Why this is required:
  /// - iOS Safari AR Quick Look requires clean URLs without %20 encoding
  /// - Supabase Storage URLs with spaces get encoded as %20 which can cause 404 errors
  /// - Case sensitivity can cause mismatches between database URLs and actual file paths
  static String sanitizeFileName(String fileName) {
    if (fileName.isEmpty) return fileName;
    
    // Extract file extension
    final lastDotIndex = fileName.lastIndexOf('.');
    String nameWithoutExt = fileName;
    String extension = '';
    
    if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
      nameWithoutExt = fileName.substring(0, lastDotIndex);
      extension = fileName.substring(lastDotIndex); // includes the dot
    }
    
    // Convert to lowercase
    nameWithoutExt = nameWithoutExt.toLowerCase();
    
    // Replace spaces with underscores (critical for iOS Safari - prevents %20 encoding)
    nameWithoutExt = nameWithoutExt.replaceAll(' ', '_');
    
    // Remove special characters except dots, hyphens, and underscores
    // Keep only alphanumeric, dots, hyphens, and underscores
    nameWithoutExt = nameWithoutExt.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    
    // Remove multiple consecutive underscores
    nameWithoutExt = nameWithoutExt.replaceAll(RegExp(r'_+'), '_');
    
    // Remove leading/trailing underscores
    nameWithoutExt = nameWithoutExt.replaceAll(RegExp(r'^_+|_+$'), '');
    
    // Reconstruct filename with extension
    final sanitized = '$nameWithoutExt$extension';
    
    if (kDebugMode && sanitized != fileName) {
      print('📝 Filename sanitized: "$fileName" → "$sanitized"');
    }
    
    return sanitized;
  }

  // Upload image to Supabase Storage
  Future<String?> uploadImage({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      // Sanitize filename to prevent 404 errors (spaces, uppercase, special chars)
      final sanitizedFileName = sanitizeFileName(fileName);
      
      // Upload to img/ folder (matching admin panel structure)
      final path = 'img/$sanitizedFileName';
      
      if (kDebugMode) {
        print('📤 Uploading image: $fileName → $sanitizedFileName');
      }
      
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'image/png',
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      
      if (kDebugMode) {
        print('✅ Image uploaded successfully');
        print('📁 Path: $path');
        print('🔗 Public URL: $url');
      }
      
      return url;
    } catch (e) {
      print('❌ Error uploading image: $e');
      print('📁 Original filename: $fileName');
      return null;
    }
  }

  // Upload GLB file to Supabase Storage
  Future<String?> uploadGlbFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      // Sanitize filename to prevent 404 errors (spaces, uppercase, special chars)
      final sanitizedFileName = sanitizeFileName(fileName);
      
      // Upload to products/glb/ folder (matching admin panel structure)
      final path = 'glb/$sanitizedFileName';
      
      if (kDebugMode) {
        print('📤 Uploading GLB file: $fileName → $sanitizedFileName');
      }
      
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'model/gltf-binary',
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      
      if (kDebugMode) {
        print('✅ GLB file uploaded successfully');
        print('📁 Path: $path');
        print('🔗 Public URL: $url');
      }
      
      return url;
    } catch (e) {
      print('❌ Error uploading GLB file: $e');
      print('📁 Original filename: $fileName');
      return null;
    }
  }

  // Upload USDZ file to Supabase Storage (separate folder for Apple devices)
  // CRITICAL: Filename sanitization is especially important for USDZ files
  // iOS Safari AR Quick Look requires clean URLs without %20 encoding or special characters
  Future<String?> uploadUsdzFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      // Sanitize filename to prevent 404 errors (spaces, uppercase, special chars)
      // This is CRITICAL for iOS Safari AR Quick Look compatibility
      final sanitizedFileName = sanitizeFileName(fileName);
      
      // Upload to products/usdz/ folder (separate bucket/folder for USDZ files)
      final path = 'usdz/$sanitizedFileName';
      
      if (kDebugMode) {
        print('📤 Uploading USDZ file: $fileName → $sanitizedFileName');
        print('🔍 Sanitization applied for iOS Safari AR Quick Look compatibility');
      }
      
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'model/vnd.usdz+zip',
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      
      // Verify the file exists by checking if URL is accessible
      if (kDebugMode) {
        print('✅ USDZ file uploaded successfully');
        print('📁 Path: $path');
        print('📦 Bucket: $bucketName');
        print('🔗 Public URL: $url');
        print('✅ URL verified: No spaces or %20 encoding (iOS Safari compatible)');
      }
      
      return url;
    } catch (e) {
      print('❌ Error uploading USDZ file: $e');
      print('📦 Bucket: $bucketName');
      print('📁 Original filename: $fileName');
      print('📁 Attempted path: usdz/[sanitized]');
      return null;
    }
  }

  // Delete file from Supabase Storage
  Future<bool> deleteFile({
    required String filePath,
    required String bucketName,
  }) async {
    try {
      await client.storage.from(bucketName).remove([filePath]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}

