import '../models/product.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  SupabaseClient get _client => SupabaseConfig.supabaseClient ?? Supabase.instance.client;
  final String _tableName = 'products';
  
  // Cache products for instant loading
  List<Product> _cachedProducts = [];
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Pre-load products on initialization
  Future<void> preloadProducts() async {
    if (_cachedProducts.isEmpty || 
        _lastFetchTime == null ||
        DateTime.now().difference(_lastFetchTime!) > _cacheDuration) {
      await getProducts(forceRefresh: true);
    }
  }

  // Get all products from database (with caching)
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    // Return cached products if available and not expired
    if (!forceRefresh && 
        _cachedProducts.isNotEmpty && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return List.from(_cachedProducts);
    }
    
    try {
      // Try to select all fields including usdz_file_url
      // If column doesn't exist, fall back to selecting without it
      dynamic response;
      try {
        response = await _client
            .from(_tableName)
            .select('id, name, category, status, image_url, second_image_url, third_image_url, glb_file_url, usdz_file_url, description, specifications, key_features, created_at, updated_at')
            .order('created_at', ascending: false);
      } on PostgrestException catch (e) {
        // If usdz_file_url column doesn't exist (code 42703), retry without it
        if (e.code == '42703') {
          print('⚠️ usdz_file_url column not found. Fetching without it...');
          response = await _client
              .from(_tableName)
              .select('id, name, category, status, image_url, second_image_url, third_image_url, glb_file_url, description, specifications, key_features, created_at, updated_at')
              .order('created_at', ascending: false);
        } else {
          rethrow;
        }
      }

      // Convert response to List<dynamic> to handle JSArray on web
      // Force conversion to native Dart List
      final List<dynamic> responseList;
      if (response is List) {
        responseList = List<dynamic>.from(response);
      } else {
        responseList = [response];
      }

      if (responseList.isEmpty) {
        _cachedProducts = [];
        _lastFetchTime = DateTime.now();
        return [];
      }

      // Convert each item to Product, ensuring proper type conversion
      final List<Product> products = [];
      for (var item in responseList) {
        try {
          // Ensure item is a Map<String, dynamic>
          Map<String, dynamic> productJson;
          if (item is Map<String, dynamic>) {
            productJson = item;
          } else if (item is Map) {
            productJson = Map<String, dynamic>.from(item);
          } else {
            print('⚠️ Skipping invalid product item: $item');
            continue;
          }
          
          // Debug: Log USDZ file URL status
          final usdzValue = productJson['usdz_file_url'];
          if (usdzValue != null) {
            final usdzStr = usdzValue.toString();
            if (usdzStr.toUpperCase() == 'NULL' || usdzStr.isEmpty) {
              print('📱 Product "${productJson['name']}" has USDZ file: NULL (empty or NULL string)');
            } else {
              print('📱 Product "${productJson['name']}" has USDZ file: $usdzStr');
            }
          } else {
            print('📱 Product "${productJson['name']}" has USDZ file: NULL (null value)');
          }
          
          products.add(Product.fromJson(productJson));
        } catch (e) {
          print('⚠️ Error parsing product: $e');
          continue;
        }
      }
      
      // Update cache with explicit type conversion
      _cachedProducts = List<Product>.from(products);
      _lastFetchTime = DateTime.now();
      
      // Return explicitly typed list
      return List<Product>.from(products);
    } catch (e, stackTrace) {
      print('Error fetching products: $e');
      print('Stack trace: $stackTrace');
      // Return cached products if available, even if expired
      if (_cachedProducts.isNotEmpty) {
        return List<Product>.from(_cachedProducts);
      }
      return <Product>[];
    }
  }
  
  // Get cached products instantly (no async)
  List<Product> getCachedProducts() {
    return List.from(_cachedProducts);
  }
  
  // Invalidate cache
  void invalidateCache() {
    _cachedProducts = [];
    _lastFetchTime = null;
  }

  // Get filtered products
  Future<List<Product>> getFilteredProducts(String filter) async {
    try {
      final allProducts = await getProducts();
      
      if (filter == 'All Products') {
        return allProducts;
      }
      
      return allProducts.where((p) => p.status == filter).toList();
    } catch (e) {
      print('Error filtering products: $e');
      return [];
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      // Try to select all fields including usdz_file_url
      // If column doesn't exist, fall back to selecting without it
      dynamic response;
      try {
        response = await _client
            .from(_tableName)
            .select('id, name, category, status, image_url, second_image_url, third_image_url, glb_file_url, usdz_file_url, description, specifications, key_features, created_at, updated_at')
            .eq('id', id)
            .single();
      } on PostgrestException catch (e) {
        // If usdz_file_url column doesn't exist (code 42703), retry without it
        if (e.code == '42703') {
          print('⚠️ usdz_file_url column not found. Fetching without it...');
          response = await _client
              .from(_tableName)
              .select('id, name, category, status, image_url, second_image_url, third_image_url, glb_file_url, description, specifications, key_features, created_at, updated_at')
              .eq('id', id)
              .single();
        } else {
          rethrow;
        }
      }

      if (response == null || (response is Map && response.isEmpty)) return null;

      // Ensure response is a Map<String, dynamic>
      final Map<String, dynamic> productJson = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response);

      return Product.fromJson(productJson);
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  // Add product to database
  Future<String?> addProduct(Product product) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(product.toJson())
          .select()
          .single();

      if (response.isEmpty) return null;

      final productId = response['id']?.toString();
      
      // Update cache - add new product at the beginning
      if (productId != null) {
        final newProduct = Product.fromJson(response);
        _cachedProducts.insert(0, newProduct);
      }
      
      return productId;
    } catch (e) {
      print('Error adding product: $e');
      return null;
    }
  }
  
  // Duplicate/Copy product
  Future<String?> duplicateProduct(Product product) async {
    try {
      // Create a copy of the product with new name
      final duplicatedProduct = Product(
        name: '${product.name} (Copy)',
        category: product.category,
        status: 'Draft', // Always set duplicated products as Draft
        imageUrl: product.imageUrl,
        secondImageUrl: product.secondImageUrl,
        thirdImageUrl: product.thirdImageUrl,
        glbFileUrl: product.glbFileUrl,
        usdzFileUrl: product.usdzFileUrl, // Include USDZ file URL
        description: product.description,
        specifications: product.specifications,
        keyFeatures: product.keyFeatures,
      );
      
      return await addProduct(duplicatedProduct);
    } catch (e) {
      print('Error duplicating product: $e');
      return null;
    }
  }

  // Update product in database
  Future<bool> updateProduct(String id, Product product) async {
    try {
      final productData = product.toJson();
      productData.remove('id'); // Remove id from update data
      productData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from(_tableName)
          .update(productData)
          .eq('id', id)
          .select()
          .single();

      if (response.isEmpty) {
        return false;
      }

      // Update cache with fresh data from database
      final updatedProduct = Product.fromJson(response);
      final index = _cachedProducts.indexWhere((p) => p.id == id);
      if (index != -1) {
        _cachedProducts[index] = updatedProduct;
      } else {
        // If product not in cache, add it (shouldn't happen, but handle gracefully)
        _cachedProducts.insert(0, updatedProduct);
      }
      
      // Update last fetch time to keep cache valid
      _lastFetchTime = DateTime.now();

      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product from database
  Future<bool> deleteProduct(String id) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('id', id);

      // Update cache - remove deleted product
      _cachedProducts.removeWhere((p) => p.id == id);

      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }
}
