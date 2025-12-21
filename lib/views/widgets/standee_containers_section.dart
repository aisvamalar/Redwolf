import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../screens/product_detail_view.dart';

class StandeeContainersSection extends StatelessWidget {
  const StandeeContainersSection({super.key});

  // Sample standee products - you can replace this with data from your controller
  List<Product> _getStandeeProducts() {
    return [
      Product(
        id: 'standee_1',
        name: 'Easel Standee',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot%202025-12-16%20193255.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_EASEL%20STANDEE.glb',
        category: 'Standees',
        description: 'Elegant easel standee design perfect for retail displays and exhibitions.',
      ),
      Product(
        id: 'standee_2',
        name: 'Totem Standee',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot%202025-12-16%20193437.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_TOTEM%20STANDEE.glb',
        category: 'Standees',
        description: 'Premium totem standee for high-traffic environments and brand visibility.',
      ),
      Product(
        id: 'standee_3',
        name: 'Wall Mount',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot%202025-12-16%20193658.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_WALL%20MOUNT.glb',
        category: 'Standees',
        description: 'Space-efficient wall mount design ideal for modern retail spaces.',
      ),
      Product(
        id: 'standee_4',
        name: 'Wall Mount with Stand',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot%202025-12-16%20193719.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_WALL%20MOUNT%20WITH%20STAND.glb',
        category: 'Standees',
        description: 'Versatile wall mount with stand for flexible placement options.',
      ),
      Product(
        id: 'standee_5',
        name: 'Easel Standee 43',
        imageUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/Screenshot%202025-12-16%20193744.png',
        modelUrl:
            'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/43_EASEL%20STANDEE.glb',
        category: 'Standees',
        description: 'Enhanced easel standee design with improved stability and display quality.',
      ),
    ];
  }

  Widget _buildStandeeContainer(BuildContext context, Product product) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailView(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Standee image container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Black standee frame
                    Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label
                  Text(
                    product.category.isNotEmpty ? product.category : 'Portable',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    product.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // View details link
                  Row(
                    children: [
                      Text(
                        'view details',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return (width - 1300) / 2;
    if (width > 1200) return (width - 1200) / 2;
    if (width > 800) return 80;
    return 32;
  }

  @override
  Widget build(BuildContext context) {
    final standees = _getStandeeProducts();
    final horizontalPadding = _getHorizontalPadding(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: const Text(
              'Featured Standees',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Horizontal scrollable containers
          SizedBox(
            height: 420,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              itemCount: standees.length,
              itemBuilder: (context, index) {
                return _buildStandeeContainer(context, standees[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

