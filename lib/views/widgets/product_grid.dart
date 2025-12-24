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
    // Filter products that have GLB or USDZ file URLs (for AR viewing)
    final productsWithModels = products
        .where(
          (p) =>
              (p.glbFileUrl != null && p.glbFileUrl!.isNotEmpty) ||
              (p.usdzFileUrl != null && p.usdzFileUrl!.isNotEmpty),
        )
        .toList();

    // Debug: Log products with USDZ files
    final usdzProducts = productsWithModels
        .where((p) => p.usdzFileUrl != null && p.usdzFileUrl!.isNotEmpty)
        .toList();
    if (usdzProducts.isNotEmpty) {
      print('📱 Found ${usdzProducts.length} product(s) with USDZ files:');
      for (var product in usdzProducts) {
        print('   - "${product.name}": ${product.usdzFileUrl}');
      }
    }

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
        ? (isDesktop
              ? 3
              : (isTablet ? 2 : 2)) // 2 columns on mobile when grid mode
        : (isDesktop
              ? 3
              : (isTablet ? 2 : 1)); // Single column on mobile when list mode
    // Adjusted aspect ratios to match actual card content with proper Figma spacing
    final childAspectRatio = layout == ProductLayout.grid2
        ? (isDesktop
              ? 0.85
              : (isTablet
                    ? 0.82
                    : 0.75)) // Increased for mobile to make cards bigger
        : (isDesktop
              ? 0.85
              : (isTablet ? 0.82 : 0.82)); // Adjusted for list mode
    // Spacing between cards - responsive spacing for better visual balance
    final crossAxisSpacing = ResponsiveHelper.getResponsiveSpacing(
      context,
      mobile: 28.0,
      tablet: 48.0,
      desktop: 56.0,
    );
    final mainAxisSpacing = ResponsiveHelper.getResponsiveSpacing(
      context,
      mobile: 20.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    // For equal spacing: set padding to match crossAxisSpacing on desktop/tablet
    // This ensures equal spacing between all columns including edges
    final padding = isDesktop
        ? crossAxisSpacing
        : (isTablet ? crossAxisSpacing : 8.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for grid items
        final availableWidth =
            constraints.maxWidth -
            (padding * 2) -
            (crossAxisSpacing * (crossAxisCount - 1));
        final itemWidth = availableWidth / crossAxisCount;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
          ),
          padding: EdgeInsets.all(padding),
          itemCount: productsWithModels.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: itemWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: ProductCard(product: productsWithModels[index]),
              ),
            );
          },
        );
      },
    );
  }
}
