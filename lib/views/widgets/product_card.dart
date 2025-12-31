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

            /// CONTENT - Ultra compact to eliminate overflow
            Expanded(
              flex: 1, // Fixed flex to make content section smaller
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 4 : 8, // Further reduced left/right padding
                  vertical: isMobile ? 4 : 6, // Further reduced vertical padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category tag - ultra minimal
                        if (widget.product.category.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.product.category,
                              style: TextStyle(
                            fontSize: isMobile ? 8 : 10,
                            color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                    if (widget.product.category.isNotEmpty)
                      SizedBox(height: isMobile ? 2 : 4),

                    // Product name - ultra minimal font size
                    Flexible(
                      child: Text(
                          widget.product.name,
                        maxLines: 2, // Allow 2 lines for longer names
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                          fontSize: isMobile ? 10 : 14, // Ultra minimal font size
                            fontWeight: FontWeight.w600,
                          height: 1.05, // Ultra tight line height
                          color: Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(height: isMobile ? 3 : 5), // Ultra minimal spacing

                    // View details CTA - minimal
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'view details',
                          style: TextStyle(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 9 : 11, // Ultra minimal font size
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward,
                          size: isMobile ? 11 : 13, // Ultra minimal icon size
                          color: const Color(0xFFDC2626),
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
