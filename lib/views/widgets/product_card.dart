import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../screens/product_detail_view.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // Derive a standee name from the model URL (e.g. "32_EASEL STANDEE.glb")
  // If parsing fails, fall back to the product name.
  String _getStandeeDisplayName() {
    final url = product.modelUrl;
    if (url == null || url.isEmpty) {
      return product.name;
    }

    try {
      // Try to get the last segment of the URL path
      final uri = Uri.parse(url);
      String fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : url.split('/').last;

      // Remove extension
      if (fileName.toLowerCase().endsWith('.glb')) {
        fileName = fileName.substring(0, fileName.length - 4);
      }

      // Decode URL-encoded characters (e.g. %20 -> space)
      fileName = Uri.decodeComponent(fileName);

      return fileName;
    } catch (_) {
      return product.name;
    }
  }

  Widget _buildProductImage() {
    // Show network image from Supabase
    return Stack(
      fit: StackFit.expand,
      children: [
        // Product image
        Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: const Color(0xFFDC2626),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(color: Colors.transparent),
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
        // 3D Model indicator badge (always shown on the card)
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.view_in_ar, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String baseCategory = product.category.isNotEmpty
        ? product.category
        : 'Portable';

    // Use derived standee name (from model URL) when available
    final String standeeName = _getStandeeDisplayName();
    // Show category combined with standee name on home screen
    final String categoryLabel = '$baseCategory • $standeeName';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailView(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                // Higher aspect ratio = shorter image height
                aspectRatio: 1.9,
                child: _buildProductImage(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Portable label
                    Text(
                      categoryLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Description
                    Text(
                      product.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // View details link
                    Row(
                      children: [
                        Text(
                          'view details',
                          style: TextStyle(
                            fontSize: 13,
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
      ),
    );
  }
}

// Custom painter for colorful circles pattern
class ColorfulCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.purple,
      Colors.green,
      Colors.blue,
      Colors.pink,
      Colors.teal,
    ];

    final circleRadius = size.width * 0.08;

    for (int i = 0; i < 50; i++) {
      final x = (i % 10) * (size.width / 10) + circleRadius;
      final y = (i ~/ 10) * (size.height / 5) + circleRadius;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), circleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
