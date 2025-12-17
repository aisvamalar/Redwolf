import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
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

    if (isWeb) {
      // Desktop layout - match Figma exactly (2 rows x 3 columns)
      return Container(
        width: 960,
        child: Column(
          children: [
            // First row of products (3 columns)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 24,
              children: [
                if (products.isNotEmpty)
                  Expanded(child: ProductCard(product: products[0])),
                if (products.length > 1)
                  Expanded(child: ProductCard(product: products[1])),
                if (products.length > 2)
                  Expanded(child: ProductCard(product: products[2])),
              ],
            ),
            const SizedBox(height: 24),
            // Second row of products (3 columns)
            if (products.length > 3)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 24,
                children: [
                  if (products.length > 3)
                    Expanded(child: ProductCard(product: products[3])),
                  if (products.length > 4)
                    Expanded(child: ProductCard(product: products[4])),
                  // Add empty space for the third column if only 2 products in second row
                  if (products.length == 5) const Expanded(child: SizedBox()),
                ],
              ),
          ],
        ),
      );
    } else {
      // Mobile layout - responsive grid
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        ),
      );
    }
  }
}
