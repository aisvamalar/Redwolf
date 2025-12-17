import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';

enum SortOption { defaultSort, nameAsc, nameDesc }

class ProductController extends ChangeNotifier {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  SortOption _sortOption = SortOption.defaultSort;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _filteredProducts;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  SortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductController() {
    _initializeProducts();
  }

  Future<void> _initializeProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch products from Supabase
      _allProducts = await SupabaseService.fetchProducts();

      // If no products from Supabase, use fallback
      if (_allProducts.isEmpty) {
        _allProducts = _getFallbackProducts();
      }

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      // Use fallback products on error
      _allProducts = _getFallbackProducts();
      _applyFilters();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> _getFallbackProducts() {
    // Fallback products with new standee models and images
    return [
      Product(
        id: 'standee_1',
        name: 'Easel Standee',
        imageUrl:
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193255.png',
        modelUrl:
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/models3d/32_EASEL%20STANDEE.glb',
        category: 'Standees',
        description:
            'Elegant easel standee design perfect for retail displays and exhibitions.',
        images: [
          'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193255.png',
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
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193437.png',
        modelUrl:
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/models3d/32_TOTEM%20STANDEE.glb',
        category: 'Standees',
        description:
            'Premium totem standee for high-traffic environments and brand visibility.',
        images: [
          'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193437.png',
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
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193658.png',
        modelUrl:
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/models3d/32_WALL%20MOUNT.glb',
        category: 'Standees',
        description:
            'Space-efficient wall mount design ideal for modern retail spaces.',
        images: [
          'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193658.png',
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
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193719.png',
        modelUrl:
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/models3d/32_WALL%20MOUNT%20WITH%20STAND.glb',
        category: 'Standees',
        description:
            'Versatile wall mount with stand for flexible placement options.',
        images: [
          'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193719.png',
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
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193744.png',
        modelUrl:
            'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/models3d/43_EASEL%20STANDEE.glb',
        category: 'Standees',
        description:
            'Enhanced easel standee design with improved stability and display quality.',
        images: [
          'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/images/Screenshot%202025-12-16%20193744.png',
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

  Future<void> refreshProducts() async {
    await _initializeProducts();
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

    // Apply category filter
    if (_selectedCategory != 'all') {
      _filteredProducts = _filteredProducts
          .where((product) => product.category == _selectedCategory)
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
                product.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
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
