import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/product_controller.dart';
import '../../utils/responsive_helper.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProductController>(context);
    final products = controller.products;
    final isMobile = ResponsiveHelper.isMobile(context);

    // Loading State
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC2626)),
      );
    }

    // Error State
    if (controller.errorMessage != null) {
      return Center(
        child: Text(
          controller.errorMessage!,
          style: const TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Filter: Only products with AR + specifically the 32" Easel Standee
    final targetProduct = products.where((p) {
      final hasAR =
          (p.glbFileUrl?.isNotEmpty ?? false) ||
          (p.usdzFileUrl?.isNotEmpty ?? false);
      final is32Easel =
          p.name.toLowerCase().contains('32') &&
          p.name.toLowerCase().contains('easel');
      return hasAR && is32Easel;
    }).toList();

    if (targetProduct.isEmpty) {
      return const Center(
        child: Text(
          'Featured product coming soon',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final product = targetProduct.first;

    // Correct badge text
    final String badgeText = product.name.toLowerCase().contains('easel')
        ? 'Portable'
        : 'Floor Standing';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ), // Clean side margins only
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.error, size: 60),
                  ),
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(
                      Icons.view_in_ar,
                      color: Colors.white,
                      size: 40,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                    ),
                  ),
                ],
              ),
            ),

            // Text Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to details or launch AR view
                      },
                      child: const Text(
                        'view details →',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
