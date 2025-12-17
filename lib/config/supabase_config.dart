/// Supabase Configuration
/// Update these values with your Supabase project details
class SupabaseConfig {
  // Supabase Storage Public URL
  static const String storageBaseUrl =
      'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public';

  // Storage bucket names
  static const String modelsBucket = 'models3d';
  static const String imagesBucket = 'images'; // For preview images

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
}
