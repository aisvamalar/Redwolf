import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../services/device_detection_service.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProductController>(context);
    final products = controller.products;

    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      );
    }

    if (controller.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(
          child: Text(
            'No products found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final isWeb = MediaQuery.of(context).size.width > 800;
    final isTablet = DeviceDetectionService.isTablet(context);

    // For now, home screen should only show a single featured product card.
    // When an admin panel is added, this can be driven by backend config.
    final featuredProduct = products.firstWhere(
      (p) => p.modelUrl != null && p.modelUrl!.isNotEmpty,
      orElse: () => products.first,
    );

    final horizontalPadding = isWeb
        ? 0.0
        : (isTablet ? 24.0 : 16.0); // match page paddings on smaller screens
    final maxCardWidth = isWeb ? 320.0 : 300.0;

      return Container(
      width: isWeb ? 960 : double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxCardWidth),
        child: ProductCard(product: featuredProduct),
        ),
      );
  }
}
