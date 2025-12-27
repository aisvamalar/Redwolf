import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

enum SortOption { defaultSort, nameAsc, nameDesc }

/// Layout options for the product grid
enum ProductLayout { singleColumn, grid2 }

class ProductController extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  SortOption _sortOption = SortOption.defaultSort;
  ProductLayout _layout = ProductLayout.grid2; // Start with 4-square grid view
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _allProducts; // Expose all products for category extraction
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProductLayout get layout => _layout;

  ProductController() {
    _initializeProducts();
  }

  Future<void> _initializeProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch products directly from database using ProductService
      final productService = ProductService();
      _allProducts = await productService.getProducts(forceRefresh: true);

      // Filter to only show Published products on home screen
      _allProducts = _allProducts.where((p) => p.status == 'Published').toList();

      // If no products from database, show error message
      if (_allProducts.isEmpty) {
        print('ℹ️ No published products in database');
        _errorMessage = 'No products available.';
      }

      _applyFilters();
    } catch (e) {
      print('❌ Error in ProductController: $e');
      _errorMessage = 'Failed to load products: $e';
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fallback products method - kept for potential future use
  // ignore: unused_element
  List<Product> _getFallbackProducts() {
    // Fallback products with new standee models and images
    return [
      Product(
        id: 'standee_1',
        name: 'Easel Standee',
        category: 'Standees',
        status: 'Published',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/Screenshot_2025-12-18_093321-removebg-preview.png',
        glbFileUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_EASEL%20STANDEE%20.glb',
        description:
            'Elegant easel standee design perfect for retail displays and exhibitions.',
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        specifications: [
          {'label': 'Model', 'value': '32" Easel Standee'},
          {'label': 'Software Mode', 'value': 'Online/Offline'},
          {'label': 'Display Resolution', 'value': '4K'},
          {'label': 'Brightness', 'value': '400 nits'},
          {'label': 'Aspect Ratio', 'value': '9:16'},
          {'label': 'Viewing Angle', 'value': '178°/178°'},
          {'label': 'Operating Hours', 'value': '10-12 Hours/Day'},
          {'label': 'Colour', 'value': 'Black'},
          {'label': 'Storage', 'value': '2 GB RAM, 16 GB ROM'},
          {'label': 'Connectivity', 'value': 'Wi-Fi / USB'},
          {'label': 'Stable Voltage', 'value': '50HZ; 100-240V AC'},
          {'label': 'Power Supply', 'value': '50W Max'},
          {'label': 'Working Temperature', 'value': '0-40°c'},
          {'label': 'Warranty', 'value': 'One Year'},
        ],
      ),
      Product(
        id: 'standee_2',
        name: 'Totem Standee',
        category: 'Standees',
        status: 'Published',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/img/Screenshot_2025-12-18_093321-removebg-preview.png',
        glbFileUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_TOTEM%20STANDEE.glb',
        description:
            'Premium totem standee for high-traffic environments and brand visibility.',
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        specifications: [
          {'label': 'Model', 'value': '32" Totem Standee'},
          {'label': 'Software Mode', 'value': 'Online/Offline'},
          {'label': 'Display Resolution', 'value': '4K'},
          {'label': 'Brightness', 'value': '400 nits'},
          {'label': 'Aspect Ratio', 'value': '9:16'},
          {'label': 'Viewing Angle', 'value': '178°/178°'},
          {'label': 'Operating Hours', 'value': '10-12 Hours/Day'},
          {'label': 'Colour', 'value': 'Black'},
          {'label': 'Storage', 'value': '2 GB RAM, 16 GB ROM'},
          {'label': 'Connectivity', 'value': 'Wi-Fi / USB'},
          {'label': 'Stable Voltage', 'value': '50HZ; 100-240V AC'},
          {'label': 'Power Supply', 'value': '50W Max'},
          {'label': 'Working Temperature', 'value': '0-40°c'},
          {'label': 'Warranty', 'value': 'One Year'},
        ],
      ),
      Product(
        id: 'standee_3',
        name: 'Wall Mount',
        category: 'Standees',
        status: 'Published',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093329-removebg-preview.png',
        glbFileUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_WALL%20MOUNT.glb',
        description:
            'Space-efficient wall mount design ideal for modern retail spaces.',
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        specifications: [
          {'label': 'Model', 'value': '32" Wall Mount'},
          {'label': 'Software Mode', 'value': 'Online/Offline'},
          {'label': 'Display Resolution', 'value': '4K'},
          {'label': 'Brightness', 'value': '400 nits'},
          {'label': 'Aspect Ratio', 'value': '9:16'},
          {'label': 'Viewing Angle', 'value': '178°/178°'},
          {'label': 'Operating Hours', 'value': '10-12 Hours/Day'},
          {'label': 'Colour', 'value': 'Black'},
          {'label': 'Storage', 'value': '2 GB RAM, 16 GB ROM'},
          {'label': 'Connectivity', 'value': 'Wi-Fi / USB'},
          {'label': 'Stable Voltage', 'value': '50HZ; 100-240V AC'},
          {'label': 'Power Supply', 'value': '50W Max'},
          {'label': 'Working Temperature', 'value': '0-40°c'},
          {'label': 'Warranty', 'value': 'One Year'},
        ],
      ),
      Product(
        id: 'standee_4',
        name: 'Wall Mount with Stand',
        category: 'Standees',
        status: 'Published',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093338-removebg-preview.png',
        glbFileUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_WALL%20MOUNT%20WITH%20STAND.glb',
        description:
            'Versatile wall mount with stand for flexible placement options.',
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        specifications: [
          {'label': 'Model', 'value': '32" Wall Mount with Stand'},
          {'label': 'Software Mode', 'value': 'Online/Offline'},
          {'label': 'Display Resolution', 'value': '4K'},
          {'label': 'Brightness', 'value': '400 nits'},
          {'label': 'Aspect Ratio', 'value': '9:16'},
          {'label': 'Viewing Angle', 'value': '178°/178°'},
          {'label': 'Operating Hours', 'value': '10-12 Hours/Day'},
          {'label': 'Colour', 'value': 'Black'},
          {'label': 'Storage', 'value': '2 GB RAM, 16 GB ROM'},
          {'label': 'Connectivity', 'value': 'Wi-Fi / USB'},
          {'label': 'Stable Voltage', 'value': '50HZ; 100-240V AC'},
          {'label': 'Power Supply', 'value': '50W Max'},
          {'label': 'Working Temperature', 'value': '0-40°c'},
          {'label': 'Warranty', 'value': 'One Year'},
        ],
      ),
      Product(
        id: 'standee_5',
        name: 'Easel Standee 43',
        category: 'Standees',
        status: 'Published',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot_2025-12-18_093348-removebg-preview.png',
        glbFileUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/43_EASEL%20STANDEE.glb',
        description:
            'Enhanced easel standee design with improved stability and display quality.',
        keyFeatures: [
          '2 Years Warranty',
          '4K Display',
          'Portable Design',
          'Touch Enabled',
        ],
        specifications: [
          {'label': 'Model', 'value': '43" Easel Standee'},
          {'label': 'Software Mode', 'value': 'Online/Offline'},
          {'label': 'Display Resolution', 'value': '4K'},
          {'label': 'Brightness', 'value': '400 nits'},
          {'label': 'Aspect Ratio', 'value': '9:16'},
          {'label': 'Viewing Angle', 'value': '178°/178°'},
          {'label': 'Operating Hours', 'value': '10-12 Hours/Day'},
          {'label': 'Colour', 'value': 'Black'},
          {'label': 'Storage', 'value': '2 GB RAM, 16 GB ROM'},
          {'label': 'Connectivity', 'value': 'Wi-Fi / USB'},
          {'label': 'Stable Voltage', 'value': '50HZ; 100-240V AC'},
          {'label': 'Power Supply', 'value': '50W Max'},
          {'label': 'Working Temperature', 'value': '0-40°c'},
          {'label': 'Warranty', 'value': 'One Year'},
        ],
      ),
    ];
  }

  Future<void> refreshProducts() async {
    await _initializeProducts();
  }

  /// Toggle between single-column list and 2-column grid layouts.
  void toggleLayout() {
    _layout = _layout == ProductLayout.grid2
        ? ProductLayout.singleColumn
        : ProductLayout.grid2;
    notifyListeners();
  }

  /// Explicitly set layout (in case you want direct control later).
  void setLayout(ProductLayout layout) {
    if (_layout == layout) return;
    _layout = layout;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = List.from(_allProducts);

    // Apply filter based on the selected category value.
    // - 'all'  -> show all products
    // - other -> filter by product.category field (e.g. "Touch display", "Portable", etc.)
    if (_selectedCategory != 'all') {
      _filteredProducts = _filteredProducts
          .where((product) {
            final productCategory = product.category.isNotEmpty ? product.category : 'Portable';
            return productCategory == _selectedCategory;
          })
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (product.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ?? false),
          )
          .toList();
    }

    // Apply sort
    switch (_sortOption) {
      case SortOption.nameAsc:
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        _filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case SortOption.defaultSort:
        // Keep original order
        break;
    }
  }
}
