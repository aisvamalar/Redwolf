import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../widgets/simple_ar_viewer.dart';

/// Full-screen AR view screen that shows SimpleARViewer
class ARViewScreen extends StatelessWidget {
  final Product product;
  final String modelUrl;

  const ARViewScreen({Key? key, required this.product, required this.modelUrl})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR Viewer takes full screen
          SimpleARViewer(
            modelUrl: modelUrl,
            altText: product.name,
            productName: product.name,
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          // Back button overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
