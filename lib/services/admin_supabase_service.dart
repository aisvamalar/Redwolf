import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AdminSupabaseService {
  static final AdminSupabaseService _instance = AdminSupabaseService._internal();
  factory AdminSupabaseService() => _instance;
  AdminSupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Upload image to Supabase Storage
  Future<String?> uploadImage({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      // Upload to img/ folder (matching admin panel structure)
      final path = 'img/$fileName';
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
      return url;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload GLB or USDZ file to Supabase Storage
  Future<String?> uploadGlbFile({
    required Uint8List fileBytes,
    required String fileName,
    required String bucketName,
  }) async {
    try {
      // Determine content type based on file extension
      final contentType = fileName.toLowerCase().endsWith('.usdz')
          ? 'model/vnd.usdz+zip'
          : 'model/gltf-binary';
      
      // Upload to products/glb/ folder (matching admin panel structure)
      final path = 'glb/$fileName';
      await client.storage.from(bucketName).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      // Get public URL
      final url = client.storage.from(bucketName).getPublicUrl(path);
      return url;
    } catch (e) {
      print('Error uploading GLB/USDZ file: $e');
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


