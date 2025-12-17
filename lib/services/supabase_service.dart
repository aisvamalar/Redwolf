import '../models/product.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  /// Fetch all standee files from Supabase storage
  /// Returns list of product URLs
  /// Note: Supabase Storage doesn't have a direct list API via public URL
  /// You'll need to use Supabase client SDK or maintain a list of files
  static Future<List<String>> fetchStandeeUrls() async {
    try {
      // Use standee files from config
      return SupabaseConfig.standeeFiles
          .map((fileName) => getStandeeUrl(fileName))
          .toList();
    } catch (e) {
      // Return fallback URLs on error
      if (SupabaseConfig.standeeFiles.isNotEmpty) {
        return [getStandeeUrl(SupabaseConfig.standeeFiles.first)];
      }
      return [];
    }
  }

  /// Get public URL for a standee file
  static String getStandeeUrl(String fileName) {
    return '${SupabaseConfig.storageBaseUrl}/${SupabaseConfig.modelsBucket}/${Uri.encodeComponent(fileName)}';
  }

  /// Get image URL for a standee (if you have preview images)
  static String getStandeeImageUrl(String fileName) {
    // Try to get preview image, fallback to model URL
    // You can create preview images in Supabase storage
    // For now, return the model URL as fallback
    // In production, you should have preview images with same name but .jpg extension
    return getStandeeUrl(fileName);
  }

  /// Fetch products from Supabase
  /// This can be enhanced to fetch from Supabase database if you have a products table
  static Future<List<Product>> fetchProducts() async {
    try {
      // For now, return empty to use fallback products with 5 items
      // This ensures we get the 2x3 grid layout with 5 products
      return [];
      
      // Uncomment below when you want to use actual Supabase products:
      // final standeeUrls = await fetchStandeeUrls();
      // return standeeUrls.asMap().entries.map((entry) {
      //   final index = entry.key;
      //   final url = entry.value;
      //   final fileName = url.split('/').last.replaceAll('%20', ' ');
      //   return Product(
      //     id: 'standee_${index + 1}',
      //     name: fileName.replaceAll('.glb', '').replaceAll('.GLB', ''),
      //     imageUrl: getStandeeImageUrl(fileName),
      //     modelUrl: url,
      //     category: 'standees',
      //     description: 'Digital standee display for AR experiences',
      //   );
      // }).toList();
    } catch (e) {
      return [];
    }
  }
}
