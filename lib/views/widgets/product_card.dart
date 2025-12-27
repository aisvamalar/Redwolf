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
  bool _isZoomed = false;

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
            /// IMAGE - Flexible to take available space
            Expanded(
              flex: 3,
              child: MouseRegion(
                onEnter: (_) => setState(() => _isZoomed = true),
                onExit: (_) => setState(() => _isZoomed = false),
                child: AnimatedScale(
                  scale: _isZoomed ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: Image.network(
                    widget.product.imageUrl,
                    fit: BoxFit.cover,
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

            /// CONTENT - Minimal space for mobile
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category tag - smaller on mobile
                  if (widget.product.category.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 4 : 6,
                        vertical: isMobile ? 1 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        widget.product.category,
                        style: TextStyle(
                          fontSize: isMobile ? 9 : 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (widget.product.category.isNotEmpty)
                    SizedBox(height: isMobile ? 3 : 4),

                  // Product name - single line, smaller on mobile
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: isMobile ? 4 : 6),

                  // View details CTA - smaller on mobile
                  Row(
                    children: [
                      Text(
                        'view details',
                        style: TextStyle(
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : 13,
                        ),
                      ),
                      SizedBox(width: isMobile ? 2 : 4),
                      Icon(
                        Icons.arrow_forward,
                        size: isMobile ? 12 : 14,
                        color: const Color(0xFFDC2626),
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
