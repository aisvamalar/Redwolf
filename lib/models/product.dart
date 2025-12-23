class Product {
  final String? id; // Database ID
  final String name;
  final String category;
  final String status;
  final String imageUrl; // Thumbnail image URL (from image_url field)
  final String? secondImageUrl; // Second image URL
  final String? thirdImageUrl; // Third image URL
  final String? glbFileUrl; // GLB file URL (from glb_file_url field)
  final String?
  usdzFileUrl; // USDZ file URL (from usdz_file_url field) - for Apple devices
  final String? description;
  final List<Map<String, String>>? specifications;
  final List<String>? keyFeatures;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.status,
    required this.imageUrl,
    this.secondImageUrl,
    this.thirdImageUrl,
    this.glbFileUrl,
    this.usdzFileUrl,
    this.description,
    this.specifications,
    this.keyFeatures,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON (database)
  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract and construct image URL
    String? imageUrl =
        json['image_url']?.toString() ?? json['thumbnail']?.toString();
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      imageUrl = _constructStorageUrl('img', imageUrl);
    }

    // Extract and construct GLB file URL
    String? glbFileUrl =
        json['glb_file_url']?.toString() ?? json['model_url']?.toString();
    if (glbFileUrl != null && !glbFileUrl.startsWith('http')) {
      glbFileUrl = _constructStorageUrl('glb', glbFileUrl);
    }

    // Extract and construct USDZ file URL
    String? usdzFileUrl = json['usdz_file_url']?.toString();
    // Handle case where database stores "NULL" as string instead of null
    if (usdzFileUrl != null &&
        usdzFileUrl.isNotEmpty &&
        usdzFileUrl.toUpperCase() != 'NULL' &&
        !usdzFileUrl.startsWith('http')) {
      usdzFileUrl = _constructStorageUrl('usdz', usdzFileUrl);
    } else if (usdzFileUrl != null &&
        (usdzFileUrl.isEmpty || usdzFileUrl.toUpperCase() == 'NULL')) {
      // Treat "NULL" string or empty string as null
      usdzFileUrl = null;
    }

    // Extract and construct second image URL
    String? secondImageUrl = json['second_image_url']?.toString();
    if (secondImageUrl != null && !secondImageUrl.startsWith('http')) {
      secondImageUrl = _constructStorageUrl('img', secondImageUrl);
    }

    // Extract and construct third image URL
    String? thirdImageUrl = json['third_image_url']?.toString();
    if (thirdImageUrl != null && !thirdImageUrl.startsWith('http')) {
      thirdImageUrl = _constructStorageUrl('img', thirdImageUrl);
    }

    return Product(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Unnamed Product',
      category: json['category']?.toString() ?? 'Standees',
      status: json['status']?.toString() ?? 'Published',
      imageUrl: imageUrl ?? '',
      secondImageUrl: secondImageUrl,
      thirdImageUrl: thirdImageUrl,
      glbFileUrl: glbFileUrl,
      usdzFileUrl: usdzFileUrl,
      description: json['description']?.toString(),
      specifications: json['specifications'] != null
          ? List<Map<String, String>>.from(
              (json['specifications'] as List).map(
                (item) => Map<String, String>.from(item),
              ),
            )
          : null,
      keyFeatures: json['key_features'] != null
          ? List<String>.from(json['key_features'] as List)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Helper method to construct storage URLs from relative paths
  static String _constructStorageUrl(String folder, String fileName) {
    const baseUrl =
        'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products';
    final cleanFileName = fileName.startsWith('/')
        ? fileName.substring(1)
        : fileName;
    
    // Normalize file name to lowercase to avoid case sensitivity issues
    // But preserve the path structure if fileName contains folders
    String normalizedFileName;
    if (cleanFileName.contains('/')) {
      // If fileName already contains folder path, normalize only the filename part
      final parts = cleanFileName.split('/');
      final lastPart = parts.last.toLowerCase();
      normalizedFileName = '${parts.sublist(0, parts.length - 1).join('/')}/$lastPart';
    } else {
      normalizedFileName = cleanFileName.toLowerCase();
    }
    
    // Handle if fileName already contains folder path
    if (normalizedFileName.contains('/')) {
      return '$baseUrl/$normalizedFileName';
    }
    // Handle USDZ files in usdz folder
    if (folder == 'usdz') {
      return '$baseUrl/$folder/${Uri.encodeComponent(normalizedFileName)}';
    }
    return '$baseUrl/$folder/${Uri.encodeComponent(normalizedFileName)}';
  }

  // Convert to JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'status': status,
      'image_url': imageUrl,
      if (secondImageUrl != null) 'second_image_url': secondImageUrl,
      if (thirdImageUrl != null) 'third_image_url': thirdImageUrl,
      if (glbFileUrl != null) 'glb_file_url': glbFileUrl,
      if (usdzFileUrl != null) 'usdz_file_url': usdzFileUrl,
      if (description != null) 'description': description,
      if (specifications != null) 'specifications': specifications,
      if (keyFeatures != null) 'key_features': keyFeatures,
    };
  }

  // Copy with method for updates
  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? status,
    String? imageUrl,
    String? secondImageUrl,
    String? thirdImageUrl,
    String? glbFileUrl,
    String? usdzFileUrl,
    String? description,
    List<Map<String, String>>? specifications,
    List<String>? keyFeatures,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      secondImageUrl: secondImageUrl ?? this.secondImageUrl,
      thirdImageUrl: thirdImageUrl ?? this.thirdImageUrl,
      glbFileUrl: glbFileUrl ?? this.glbFileUrl,
      usdzFileUrl: usdzFileUrl ?? this.usdzFileUrl,
      description: description ?? this.description,
      specifications: specifications ?? this.specifications,
      keyFeatures: keyFeatures ?? this.keyFeatures,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get modelUrl for AR (alias for glbFileUrl for backward compatibility)
  String? get modelUrl => glbFileUrl;

  // Get default technical specs if not provided (for backward compatibility)
  Map<String, String> get defaultTechnicalSpecs {
    if (specifications != null && specifications!.isNotEmpty) {
      final Map<String, String> specs = {};
      for (var spec in specifications!) {
        if (spec.containsKey('label') && spec.containsKey('value')) {
          specs[spec['label']!] = spec['value']!;
        }
      }
      return specs;
    }
    return {
      'Model': '50" Totem',
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
    };
  }

  // Get default key features if not provided (for backward compatibility)
  List<String> get defaultKeyFeatures =>
      keyFeatures ??
      ['2 Years Warranty', '4K Display', 'Portable Design', 'Touch Enabled'];

  // Get images list (for backward compatibility)
  List<String>? get images {
    final List<String> imageList = [];
    if (imageUrl.isNotEmpty) imageList.add(imageUrl);
    if (secondImageUrl != null && secondImageUrl!.isNotEmpty)
      imageList.add(secondImageUrl!);
    if (thirdImageUrl != null && thirdImageUrl!.isNotEmpty)
      imageList.add(thirdImageUrl!);
    return imageList.isEmpty ? null : imageList;
  }
}
