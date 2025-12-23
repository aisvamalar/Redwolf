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

  /// Get full storage URL from bucket path and file name
  /// Constructs the public URL for files in Supabase storage
  /// Handles files in root, img folder, glb folder, or with full paths
  static String getStorageUrl(String bucketPath, String fileName) {
    // Remove leading slash if present
    final cleanPath = bucketPath.startsWith('/')
        ? bucketPath.substring(1)
        : bucketPath;
    final cleanFileName = fileName.startsWith('/')
        ? fileName.substring(1)
        : fileName;

    // If fileName already contains a path (e.g., "img/file.png" or "glb/model.glb")
    // and bucketPath is just "products", combine them properly
    if (cleanFileName.contains('/') && cleanPath == 'products') {
      // File already has path, use it directly
      return '${SupabaseConfig.storageBaseUrl}/$cleanPath/$cleanFileName';
    }

    // Construct full URL: bucketPath/fileName
    return '${SupabaseConfig.storageBaseUrl}/$cleanPath/${Uri.encodeComponent(cleanFileName)}';
  }

  /// Fetch products from Supabase database
  /// Fetches all products from the 'products' table
  static Future<List<Product>> fetchProducts() async {
    try {
      // Check if Supabase client is initialized
      if (SupabaseConfig.supabaseClient == null) {
        print('❌ Supabase client not initialized!');
        print('   Make sure Supabase is initialized in main.dart');
        return [];
      }

      print('🔍 Fetching products from Supabase database...');

      // Fetch products from the database
      final response = await SupabaseConfig.supabaseClient!
          .from('products')
          .select()
          .order('created_at', ascending: false); // Order by newest first

      print('📦 Database response: ${response?.length ?? 0} products found');

      if (response == null || response.isEmpty) {
        print('⚠️ No products found in database!');
        print(
          '   Please check if products table exists and has data',
        );
        return [];
      }

      // Convert database records to Product objects
      final products = <Product>[];
      for (var record in response) {
        try {
          // Extract thumbnail - can be a full URL or a path in the storage bucket
          String? thumbnailUrl =
              record['thumbnail']?.toString() ??
              record['image_url']?.toString() ??
              record['imageUrl']?.toString();

          // If thumbnail is a path (not a full URL), construct the full storage URL
          if (thumbnailUrl != null && !thumbnailUrl.startsWith('http')) {
            // Try different possible locations:
            // 1. products/img/filename (in img folder)
            // 2. products/filename (in root of products bucket)
            // 3. Just filename (assume in img folder)
            if (thumbnailUrl.contains('/')) {
              // Already has path, use as-is
              thumbnailUrl = getStorageUrl(
                SupabaseConfig.bucketName,
                thumbnailUrl,
              );
            } else {
              // Just filename, try img folder first, then root
              thumbnailUrl = getStorageUrl(
                SupabaseConfig.imagesBucket,
                thumbnailUrl,
              );
            }
          }

          // Extract model URL - can be a full URL or a path in the storage bucket
          String? modelUrl =
              record['model_url']?.toString() ??
              record['modelUrl']?.toString() ??
              record['glb_file']?.toString() ??
              record['glbFile']?.toString();

          // If model URL is a path (not a full URL), construct the full storage URL
          if (modelUrl != null && !modelUrl.startsWith('http')) {
            // Try different possible locations:
            // 1. products/glb/filename (in glb folder)
            // 2. products/filename (in root of products bucket)
            // 3. Just filename (assume in glb folder)
            if (modelUrl.contains('/')) {
              // Already has path, use as-is
              modelUrl = getStorageUrl(SupabaseConfig.bucketName, modelUrl);
            } else {
              // Just filename, try glb folder first, then root
              modelUrl = getStorageUrl(SupabaseConfig.modelsBucket, modelUrl);
            }
          }

          // Extract images array - handle both full URLs and paths
          List<String>? imagesList;
          if (record['images'] != null) {
            final imagesData = record['images'];
            if (imagesData is List) {
              imagesList = imagesData.map((img) {
                final imgStr = img.toString();
                if (imgStr.startsWith('http')) {
                  return imgStr;
                } else if (imgStr.contains('/')) {
                  return getStorageUrl(SupabaseConfig.bucketName, imgStr);
                } else {
                  return getStorageUrl(SupabaseConfig.imagesBucket, imgStr);
                }
              }).toList();
            }
          }

          // Convert specifications to List<Map<String, String>> format
          List<Map<String, String>>? specificationsList;
          if (record['specifications'] != null) {
            if (record['specifications'] is List) {
              specificationsList = (record['specifications'] as List)
                  .map((item) {
                    if (item is Map) {
                      return {
                        'label': item['label']?.toString() ?? '',
                        'value': item['value']?.toString() ?? '',
                      };
                    }
                    return <String, String>{};
                  })
                  .where((map) => map['label']?.isNotEmpty ?? false)
                  .cast<Map<String, String>>()
                  .toList();
            } else if (record['specifications'] is Map) {
              specificationsList = (record['specifications'] as Map)
                  .entries
                  .map((entry) => {
                        'label': entry.key.toString(),
                        'value': entry.value.toString(),
                      })
                  .toList();
            }
          }

          // Handle different possible field names from database
          final product = Product(
            id: record['id']?.toString(),
            name: record['name']?.toString() ?? 'Unnamed Product',
            category: record['category']?.toString() ?? 'Standees',
            status: record['status']?.toString() ?? 'Published',
            imageUrl: thumbnailUrl ?? '',
            glbFileUrl: modelUrl,
            secondImageUrl: imagesList != null && imagesList.length > 1 ? imagesList[1] : null,
            thirdImageUrl: imagesList != null && imagesList.length > 2 ? imagesList[2] : null,
            description:
                record['description']?.toString() ??
                'Digital standee display for AR experiences',
            specifications: specificationsList,
            keyFeatures: record['key_features'] != null
                ? List<String>.from(
                    (record['key_features'] as List).map((e) => e.toString()),
                  )
                : record['keyFeatures'] != null
                ? List<String>.from(
                    (record['keyFeatures'] as List).map((e) => e.toString()),
                  )
                : null,
          );

          // Only add products that have required fields
          if (product.id != null &&
              product.id!.isNotEmpty &&
              product.name.isNotEmpty &&
              product.imageUrl.isNotEmpty) {
            products.add(product);
            print('   ✓ Loaded: ${product.name} (ID: ${product.id})');
            print('      Thumbnail: ${product.imageUrl}');
            print('      Model: ${product.modelUrl ?? "No AR model"}');
            print('      Category: ${product.category}');
          } else {
            print(
              '   ⚠️ Skipped product (missing required fields): ${record['id']}',
            );
          }
        } catch (e) {
          print('❌ Error parsing product record: $e');
          print('   Record data: $record');
          // Continue with next product
        }
      }

      print('✅ Successfully fetched ${products.length} products from database');
      if (products.isNotEmpty) {
        print('   Products: ${products.map((p) => p.name).join(", ")}');
      }
      return products;
    } catch (e, stackTrace) {
      print('❌ Error fetching products from Supabase:');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      print('   This might mean:');
      print('   1. The "products" table does not exist');
      print('   2. Database connection failed');
      print('   3. RLS (Row Level Security) policies are blocking access');
      print('   4. Check Supabase dashboard for table and permissions');
      // Return empty list to trigger fallback
      return [];
    }
  }
}
