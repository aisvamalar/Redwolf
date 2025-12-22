import '../models/product.dart';
import 'product_service.dart';

/// Production-level service for fetching product details
class ProductDetailService {
  /// Fetch detailed product information by ID
  /// Fetches from Supabase database using ProductService
  static Future<Product?> fetchProductDetail(String productId) async {
    try {
      print('🔍 Fetching product detail for ID: $productId');
      
      // Use ProductService to fetch product by ID
      final productService = ProductService();
      final product = await productService.getProductById(productId);
      
      if (product != null) {
        print('✅ Product found in database: ${product.name}');
        return product;
      }
      
      print('⚠️ Product not found in database: $productId');
      return null;
    } catch (e) {
      print('❌ Error fetching product detail: $e');
      return null;
    }
  }

  /// Track product view (for analytics)
  static Future<void> trackProductView(String productId) async {
    try {
      // TODO: Implement analytics tracking
      print('📊 Tracking product view: $productId');
    } catch (e) {
      print('❌ Error tracking product view: $e');
    }
  }
}
