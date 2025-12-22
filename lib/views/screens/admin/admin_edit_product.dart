import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../models/admin_product.dart';
import 'admin_add_product.dart';

class AdminEditProduct extends StatelessWidget {
  final Product product;

  const AdminEditProduct({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Convert Product to AdminProduct for editing
    final adminProduct = AdminProduct(
      id: product.id,
      name: product.name,
      category: product.category,
      status: product.status,
      imageUrl: product.imageUrl,
      secondImageUrl: product.secondImageUrl,
      thirdImageUrl: product.thirdImageUrl,
      glbFileUrl: product.glbFileUrl,
      description: product.description,
      specifications: product.specifications,
      keyFeatures: product.keyFeatures,
    );
    
    return AdminAddProduct(product: adminProduct);
  }
}
