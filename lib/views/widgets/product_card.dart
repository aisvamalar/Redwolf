import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../utils/responsive_helper.dart';
import '../../views/screens/product_detail_view.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isZoomed = false;

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailView(product: widget.product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return InkWell(
      onTap: _navigateToDetail,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image section with zoom
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _isZoomed = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _isZoomed = false;
                      });
                    },
                    child: GestureDetector(
                      onTap: _navigateToDetail, // Add navigation on tap
                      onTapDown: (_) {
                        setState(() {
                          _isZoomed = true;
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          _isZoomed = false;
                        });
                      },
                      onTapCancel: () {
                        setState(() {
                          _isZoomed = false;
                        });
                      },
                      child: ClipRect(
                        child: AnimatedScale(
                          scale: _isZoomed ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: Image.network(
                            widget.product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[400],
                                    size: isMobile ? 40 : 48,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.view_in_ar,
                        color: Colors.white,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.product.category.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.product.category,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (widget.product.category.isNotEmpty)
                    SizedBox(height: isMobile ? 8 : 12),

                  // Product name with full display (no truncation)
                  Text(
                    widget.product.name,
                    maxLines: 3, // Allow up to 3 lines for full name display
                    overflow: TextOverflow.visible, // Show full text
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: isMobile
                          ? 14.0
                          : 16.0, // Slightly smaller to fit more text
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.2, // Tighter line height for better spacing
                    ),
                  ),

                  SizedBox(height: isMobile ? 8 : 12),

                  Row(
                    children: const [
                      Text(
                        'view details',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFFDC2626),
                        size: 16,
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
}
