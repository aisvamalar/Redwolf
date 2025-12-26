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

    final bool isMobile = ResponsiveHelper.isMobile(context);
    final bool isTablet = ResponsiveHelper.isTablet(context);
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

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
                size: isMobile ? 40.0 : 48.0,
                color: Colors.grey[400],
              ),
              SizedBox(height: isMobile ? 12.0 : 16.0),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 14.0 : 16.0,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isMobile ? 16.0 : 24.0),
              ElevatedButton(
                onPressed: controller.refreshProducts,
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

    final productsWithModels = products
        .where(
          (p) =>
              (p.glbFileUrl != null && p.glbFileUrl!.isNotEmpty) ||
              (p.usdzFileUrl != null && p.usdzFileUrl!.isNotEmpty),
        )
        .toList();

    if (productsWithModels.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
        child: const Center(
          child: Text(
            'No products with AR models available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final layout = controller.layout;

    final int crossAxisCount = layout == ProductLayout.grid2
        ? (isDesktop ? 3 : 2)
        : (isDesktop ? 3 : (isTablet ? 2 : 1));

    // Aspect ratios must be double
    final double childAspectRatio = layout == ProductLayout.grid2
        ? (isDesktop ? 0.66 : (isTablet ? 0.64 : 0.62))
        : (isDesktop ? 0.70 : (isTablet ? 0.68 : 0.72));

    // Spacing must be double
    final double crossAxisSpacing = ResponsiveHelper.getResponsiveSpacing(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    final double mainAxisSpacing = ResponsiveHelper.getResponsiveSpacing(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );

    // Padding must be double
    final double padding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(padding),
      itemCount: productsWithModels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemBuilder: (context, index) {
        return ProductCard(product: productsWithModels[index]);
      },
    );
  }
}
