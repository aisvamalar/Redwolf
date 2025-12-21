import '../models/product.dart';
// import '../config/supabase_config.dart'; // Uncomment when Supabase client is configured
import 'package:flutter/foundation.dart';
import 'product_detail_service_web_stub.dart'
    if (dart.library.html) 'product_detail_service_web.dart'
    as web_utils;

/// Production-level service for fetching product details
class ProductDetailService {
  /// Fetch detailed product information by ID
  /// Attempts to fetch from Supabase, falls back to enhanced default data
  static Future<Product?> fetchProductDetail(String productId) async {
    try {
      // Try to fetch from Supabase database if configured
      // Note: Uncomment when Supabase client is configured
      // import '../config/supabase_config.dart';
      // if (SupabaseConfig.supabaseClient != null) {
      //   try {
      //     final response = await SupabaseConfig.supabaseClient!
      //         .from('products')
      //         .select()
      //         .eq('id', productId)
      //         .maybeSingle();
      //
      //     if (response != null) {
      //       return Product.fromJson(response);
      //     }
      //   } catch (e) {
      //     print('Supabase fetch failed, using fallback: $e');
      //   }
      // }

      // Fallback: Return enhanced product with default data
      return _getEnhancedProduct(productId);
    } catch (e) {
      print('Error fetching product detail: $e');
      return _getEnhancedProduct(productId);
    }
  }

  /// Get enhanced product with full details (fallback)
  /// Uses product data from ProductController to preserve the correct modelUrl
  static Product _getEnhancedProduct(String productId) {
    // Try to find the product from the controller's fallback products
    // This ensures we use the correct modelUrl for each product
    final fallbackProducts = _getFallbackProducts();
    final existingProduct = fallbackProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () =>
          fallbackProducts.first, // Fallback to first product if not found
    );

    // Return the existing product with all its correct data (including modelUrl)
    return existingProduct;
  }

  /// Get fallback products (same as ProductController)
  static List<Product> _getFallbackProducts() {
    return [
      Product(
        id: 'standee_1',
        name: 'Easel Standee',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/Screenshot_2025-12-18_093321-removebg-preview.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_EASEL%20STANDEE%20.glb',
        category: 'Standees',
        description:
            'Elegant easel standee design perfect for retail displays and exhibitions.',
        images: [
          'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/Screenshot_2025-12-18_093321-removebg-preview.png',
        ],
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        technicalSpecs: {
          'Model': '32" Easel Standee',
          'Software Mode': 'Online/Offline',
          'Display Resolution': '4K',
          'Brightness': '400 nits',
          'Aspect Ratio': '9:16',
          'Viewing Angle': '178°/178°',
          'Operating Hours': '10-12 Hours/Day',
          'Colour': 'Black',
          'Storage': '2 GB RAM, 16 GB ROM',
          'Connectivity': 'Wi-Fi / USB',
          'Stable Voltage': '50HZ; 100-240V AC',
          'Power Supply': '50W Max',
          'Working Temperature': '0-40°c',
          'Warranty': 'One Year',
        },
      ),
      Product(
        id: 'standee_2',
        name: 'Totem Standee',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/Screenshot_2025-12-18_093321-removebg-preview.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_TOTEM%20STANDEE.glb',
        category: 'Standees',
        description:
            'Premium totem standee for high-traffic environments and brand visibility.',
        images: [
          'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/Screenshot_2025-12-18_093321-removebg-preview.png',
        ],
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        technicalSpecs: {
          'Model': '32" Totem Standee',
          'Software Mode': 'Online/Offline',
          'Display Resolution': '4K',
          'Brightness': '400 nits',
          'Aspect Ratio': '9:16',
          'Viewing Angle': '178°/178°',
          'Operating Hours': '10-12 Hours/Day',
          'Colour': 'Black',
          'Storage': '2 GB RAM, 16 GB ROM',
          'Connectivity': 'Wi-Fi / USB',
          'Stable Voltage': '50HZ; 100-240V AC',
          'Power Supply': '50W Max',
          'Working Temperature': '0-40°c',
          'Warranty': 'One Year',
        },
      ),
      Product(
        id: 'standee_3',
        name: 'Wall Mount',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093329-removebg-preview.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_WALL%20MOUNT.glb',
        category: 'Standees',
        description:
            'Space-efficient wall mount design ideal for modern retail spaces.',
        images: [
          'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093329-removebg-preview.png',
        ],
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        technicalSpecs: {
          'Model': '32" Wall Mount',
          'Software Mode': 'Online/Offline',
          'Display Resolution': '4K',
          'Brightness': '400 nits',
          'Aspect Ratio': '9:16',
          'Viewing Angle': '178°/178°',
          'Operating Hours': '10-12 Hours/Day',
          'Colour': 'Black',
          'Storage': '2 GB RAM, 16 GB ROM',
          'Connectivity': 'Wi-Fi / USB',
          'Stable Voltage': '50HZ; 100-240V AC',
          'Power Supply': '50W Max',
          'Working Temperature': '0-40°c',
          'Warranty': 'One Year',
        },
      ),
      Product(
        id: 'standee_4',
        name: 'Wall Mount with Stand',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093338-removebg-preview.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_WALL%20MOUNT%20WITH%20STAND.glb',
        category: 'Standees',
        description:
            'Versatile wall mount with stand for flexible placement options.',
        images: [
          'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093338-removebg-preview.png',
        ],
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        technicalSpecs: {
          'Model': '32" Wall Mount with Stand',
          'Software Mode': 'Online/Offline',
          'Display Resolution': '4K',
          'Brightness': '400 nits',
          'Aspect Ratio': '9:16',
          'Viewing Angle': '178°/178°',
          'Operating Hours': '10-12 Hours/Day',
          'Colour': 'Black',
          'Storage': '2 GB RAM, 16 GB ROM',
          'Connectivity': 'Wi-Fi / USB',
          'Stable Voltage': '50HZ; 100-240V AC',
          'Power Supply': '50W Max',
          'Working Temperature': '0-40°c',
          'Warranty': 'One Year',
        },
      ),
      Product(
        id: 'standee_5',
        name: 'Easel Standee 43',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093348-removebg-preview.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/43_EASEL%20STANDEE.glb',
        category: 'Standees',
        description:
            'Enhanced easel standee design with improved stability and display quality.',
        images: [
          'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093348-removebg-preview.png',
        ],
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        technicalSpecs: {
          'Model': '43" Easel Standee',
          'Software Mode': 'Online/Offline',
          'Display Resolution': '4K',
          'Brightness': '400 nits',
          'Aspect Ratio': '9:16',
          'Viewing Angle': '178°/178°',
          'Operating Hours': '10-12 Hours/Day',
          'Colour': 'Black',
          'Storage': '2 GB RAM, 16 GB ROM',
          'Connectivity': 'Wi-Fi / USB',
          'Stable Voltage': '50HZ; 100-240V AC',
          'Power Supply': '50W Max',
          'Working Temperature': '0-40°c',
          'Warranty': 'One Year',
        },
      ),
    ];
  }

  /// Submit enquiry form
  /// Saves to Supabase if available, otherwise logs for manual processing
  static Future<bool> submitEnquiry({
    required String productId,
    required String name,
    required String email,
    required String phone,
    String? message,
  }) async {
    try {
      // Validate input
      if (name.trim().isEmpty || email.trim().isEmpty || phone.trim().isEmpty) {
        throw Exception('Required fields are missing');
      }

      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Invalid email format');
      }

      final enquiryData = {
        'product_id': productId,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'message': message?.trim() ?? '',
        'created_at': DateTime.now().toIso8601String(),
        'status': 'new',
      };

      // Try to save to Supabase if configured
      // Note: Uncomment when Supabase client is configured
      // import '../config/supabase_config.dart';
      // if (SupabaseConfig.supabaseClient != null) {
      //   try {
      //     await SupabaseConfig.supabaseClient!
      //         .from('enquiries')
      //         .insert(enquiryData);
      //     print('Enquiry saved to Supabase: $productId');
      //     return true;
      //   } catch (e) {
      //     print('Supabase save failed, logging locally: $e');
      //     // Fall through to local logging
      //   }
      // }

      // Fallback: Log to console (in production, you might want to send to analytics)
      print('Enquiry submitted: ${enquiryData.toString()}');

      // Optionally send to analytics service
      _logToAnalytics('enquiry_submitted', enquiryData);

      return true;
    } catch (e) {
      print('Error submitting enquiry: $e');
      return false;
    }
  }

  /// Track product view for analytics
  static Future<void> trackProductView(String productId) async {
    if (!kIsWeb) return; // Only track on web

    try {
      final viewData = {
        'product_id': productId,
        'viewed_at': DateTime.now().toIso8601String(),
        'user_agent': web_utils.WebUtils.getUserAgent(),
        'url': web_utils.WebUtils.getCurrentUrl(),
      };

      // Try to save to Supabase if configured
      // Note: Uncomment when Supabase client is configured
      // import '../config/supabase_config.dart';
      // if (SupabaseConfig.supabaseClient != null) {
      //   try {
      //     await SupabaseConfig.supabaseClient!
      //         .from('product_views')
      //         .insert(viewData);
      //     return;
      //   } catch (e) {
      //     print('Supabase tracking failed: $e');
      //   }
      // }

      // Fallback: Log to analytics
      _logToAnalytics('product_viewed', viewData);
    } catch (e) {
      print('Error tracking product view: $e');
    }
  }

  /// Log events to analytics (can be extended to use Google Analytics, Mixpanel, etc.)
  static void _logToAnalytics(String eventName, Map<String, dynamic> data) {
    // In production, integrate with your analytics service
    // Example: Google Analytics, Mixpanel, Amplitude, etc.
    print('Analytics Event: $eventName - $data');

    // Example Google Analytics integration:
    // html.window.gtag?.call('event', eventName, data);
  }
}
