/// Supabase Configuration
/// Update these values with your Supabase project details
class SupabaseConfig {
  // Supabase Project URL
  static const String supabaseUrl = 'https://zsipfgtlfnfvmnrohtdo.supabase.co';
  
  // Supabase Storage Public URL
  static const String storageBaseUrl =
      'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public';

  // Storage bucket names
  // Based on actual Supabase storage structure: files are in 'products' bucket
  // Files can be in root, 'img' folder, or 'glb' folder
  static const String bucketName = 'products';
  static const String modelsBucket = 'products/glb'; // GLB files folder
  static const String imagesBucket = 'products/img'; // Image files folder
  
  // Supabase API credentials
  static const String publishableKey = 'sb_publishable_wmZqFa8wSJhsyPeWcFOmYg_ta4eoCcS';
  static const String secretKey = 'sb_secret_9umn23jj2dE7m7x4B5wjuw_tGmHqLqf';

  // Background Removal API (remove.bg)
  // Get your free API key from: https://www.remove.bg/api
  // Note: Background removal is enabled by default with visual effects
  // Set enableBackgroundRemoval = true and add API key for true background removal
  static const String removeBgApiKey = 'YOUR_REMOVE_BG_API_KEY'; // Replace with your API key
  static const bool enableBackgroundRemoval = true; // Set to true to enable background removal (requires API key)

  // List of standee files in your Supabase storage
  // Update this list when you add new standees
  static const List<String> standeeFiles = [
    'Digital standee 4.5 feet.glb',
    // Add more standee file names here as you upload them
    // Example: 'Standee 6 feet.glb',
  ];

  // Supabase client instance (null if not initialized)
  // To use Supabase database features, initialize this with:
  // import 'package:supabase_flutter/supabase_flutter.dart';
  // supabaseClient = Supabase.instance.client;
  static dynamic supabaseClient;

  // Edge Function base URL for proxying models with CORS
  static const String edgeFunctionBaseUrl =
      'https://zsipfgtlfnfvmnrohtdo.supabase.co/functions/v1';
  
  // Set to false to use direct storage URLs (bypass proxy)
  // Set to true to use proxy URLs (requires Edge Function to be deployed)
  // Currently set to false since Edge Function is not deployed yet
  static const bool useProxyForModels = false;

  /// Get proxy URL for a model file (uses Edge Function for CORS support)
  /// This is needed for Google Scene Viewer which requires specific CORS headers
  static String getProxyModelUrl(String modelPath) {
    final encodedPath = Uri.encodeComponent(modelPath);
    return '$edgeFunctionBaseUrl/proxy-model?path=$encodedPath';
  }

  /// Get direct storage URL for a model file
  static String getDirectModelUrl(String modelPath) {
    return '$storageBaseUrl/$modelPath';
  }

  /// Get model URL - uses proxy by default for better CORS support
  static String getModelUrl(String fileName, {bool useProxy = true}) {
    final modelPath = '$modelsBucket/$fileName';
    if (useProxy) {
      return getProxyModelUrl(modelPath);
    }
    return getDirectModelUrl(modelPath);
  }

  /// Convert a full storage URL to a proxy URL
  /// Extracts the path from the full URL and converts it to proxy format
  /// Returns original URL if useProxyForModels is false
  static String convertToProxyUrl(String fullStorageUrl) {
    if (!useProxyForModels) {
      return fullStorageUrl;
    }
    try {
      // Extract the path after /object/public/
      final uri = Uri.parse(fullStorageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index of 'public' and get everything after it
      final publicIndex = pathSegments.indexOf('public');
      if (publicIndex >= 0 && publicIndex < pathSegments.length - 1) {
        final modelPath = pathSegments.sublist(publicIndex + 1).join('/');
        return getProxyModelUrl(modelPath);
      }
      
      // Fallback: try to extract from the full path
      final pathMatch = RegExp(r'/object/public/(.+)$').firstMatch(uri.path);
      if (pathMatch != null) {
        return getProxyModelUrl(pathMatch.group(1)!);
      }
      
      // If we can't parse it, return original
      return fullStorageUrl;
    } catch (e) {
      // If parsing fails, return original URL
      return fullStorageUrl;
    }
  }
}
