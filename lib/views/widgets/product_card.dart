import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import '../../utils/responsive_helper.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  void _navigateToDetail() {
    context.push('/product/${widget.product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return InkWell(
      onTap: _navigateToDetail,
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// IMAGE - With zoom animation on hover (container border preserved)
            Expanded(
              flex: 3, // Increased flex to make image larger
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: AnimatedScale(
                    scale: _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover, // Cover to make image larger and balance with product info
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            /// CONTENT - Reduced size to balance with larger image
            Expanded(
              flex: 1, // Fixed flex to make content section smaller
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category tag - larger size
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
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (widget.product.category.isNotEmpty)
                    const SizedBox(height: 12),

                  // Product name - reduced font size
                  Text(
                    widget.product.name,
                    maxLines: 2, // Allow 2 lines for longer names
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 18, // Reduced font sizes
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12), // Reduced spacing

                  // View details CTA - reduced size
                  Row(
                    children: [
                      Text(
                        'view details',
                        style: TextStyle(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 13 : 14, // Reduced font size
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
