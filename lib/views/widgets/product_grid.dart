import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../utils/responsive_helper.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProductController>(context);
    final products = controller.products;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (controller.isLoading) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: isMobile ? 40 : 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
                child: Text(
                  controller.errorMessage!,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              ElevatedButton(
                onPressed: () => controller.refreshProducts(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
        child: Center(
          child: Text(
            'No products found',
            style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.grey),
          ),
        ),
      );
    }

    // Display all products from database in a grid
    // Filter products that have GLB file URLs (for AR viewing)
    final productsWithModels = products
        .where((p) => p.glbFileUrl != null && p.glbFileUrl!.isNotEmpty)
        .toList();

    if (productsWithModels.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
        child: Center(
          child: Text(
            'No products with AR models available',
            style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.grey),
          ),
        ),
      );
    }

    // Calculate grid layout based on controller layout preference
    final layout = controller.layout;
    final crossAxisCount = layout == ProductLayout.grid2
        ? (isDesktop ? 3 : (isTablet ? 2 : 2)) // 2 columns on mobile when grid mode
        : (isDesktop ? 3 : (isTablet ? 2 : 1)); // Single column on mobile when list mode
    // Adjusted aspect ratios to account for significantly reduced image size (1.4 instead of 1.0)
    final childAspectRatio = layout == ProductLayout.grid2
        ? (isDesktop ? 0.78 : (isTablet ? 0.80 : 0.78)) // Adjusted for reduced image container
        : (isDesktop ? 0.78 : (isTablet ? 0.82 : 1.0)); // Adjusted list mode aspect ratio
    final spacing = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);
    final padding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for grid items
        final availableWidth = constraints.maxWidth - (padding * 2) - (spacing * (crossAxisCount - 1));
        final itemWidth = availableWidth / crossAxisCount;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          padding: EdgeInsets.all(padding),
          itemCount: productsWithModels.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: itemWidth,
              child: ProductCard(product: productsWithModels[index]),
            );
          },
        );
      },
    );
  }
}
