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

    // For now, home screen should only show a single featured product card.
    // When an admin panel is added, this can be driven by backend config.
    final featuredProduct = products.firstWhere(
      (p) => p.modelUrl != null && p.modelUrl!.isNotEmpty,
      orElse: () => products.first,
    );

    final maxCardWidth = isDesktop
        ? 320.0
        : (isTablet ? 300.0 : double.infinity);

    return Container(
      width: isDesktop ? 960 : double.infinity,
      alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: ProductCard(product: featuredProduct),
      ),
    );
  }
}
