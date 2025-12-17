class Product {
  final String id;
  final String name;
  final String imageUrl;
  final String? modelUrl; // 3D model URL (.glb file)
  final String category;
  final String description;
  final List<String>? images; // Multiple product images
  final List<String>? keyFeatures; // Key features list
  final Map<String, String>? technicalSpecs; // Technical specifications

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.modelUrl,
    required this.category,
    required this.description,
    this.images,
    this.keyFeatures,
    this.technicalSpecs,
  });

  Product.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      imageUrl = json['imageUrl'] as String,
      modelUrl = json['modelUrl'] as String?,
      category = json['category'] as String,
      description = json['description'] as String,
      images = json['images'] != null 
          ? List<String>.from(json['images'] as List)
          : null,
      keyFeatures = json['keyFeatures'] != null
          ? List<String>.from(json['keyFeatures'] as List)
          : null,
      technicalSpecs = json['technicalSpecs'] != null
          ? Map<String, String>.from(json['technicalSpecs'] as Map)
          : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'modelUrl': modelUrl,
    'category': category,
    'description': description,
    if (images != null) 'images': images,
    if (keyFeatures != null) 'keyFeatures': keyFeatures,
    if (technicalSpecs != null) 'technicalSpecs': technicalSpecs,
  };

  // Get default technical specs if not provided
  Map<String, String> get defaultTechnicalSpecs => technicalSpecs ?? {
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

  // Get default key features if not provided
  List<String> get defaultKeyFeatures => keyFeatures ?? [
    '2 Years Warranty',
    '4K Display',
    'Portable Design',
    'Touch Enabled',
  ];
}
