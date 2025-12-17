import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/model_viewer_widget.dart';
import 'ar_view_screen.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../services/product_detail_service.dart';

class ProductDetailView extends StatefulWidget {
  final Product product;

  const ProductDetailView({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _selectedImageIndex = 0;
  Product? _enhancedProduct;
  bool _isEnquiryDialogOpen = false;

  @override
  void initState() {
    super.initState();
    // Use product directly without fetching from Supabase
    _enhancedProduct = widget.product;
    _trackProductView();
  }

  Future<void> _trackProductView() async {
    await ProductDetailService.trackProductView(widget.product.id);
  }

  Product get _product => _enhancedProduct ?? widget.product;

  /// Gets the 3D model URL for the current product
  /// Uses the product's modelUrl if available, otherwise falls back to default
  String get modelUrl {
    // Always use the product's specific modelUrl if it exists
    final productModelUrl = _product.modelUrl;
    if (productModelUrl != null && productModelUrl.isNotEmpty) {
      return productModelUrl;
    }
    // Fallback to default model (should not be needed if products are configured correctly)
    return 'https://drrsxgopvzhnqfvdfjlm.supabase.co/storage/v1/object/public/models3d/Digital%20standee%204.5%20feet.glb';
  }

  List<String> get _productImages {
    if (_product.images != null && _product.images!.isNotEmpty) {
      return _product.images!;
    }
    // Return multiple images - main image and variations
    return [
      _product.imageUrl,
      _product.imageUrl, // In real app, this would be different images
    ];
  }

  double _getMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 1300;
    if (width > 1200) return 1200;
    if (width > 800) return width - 160;
    return width - 64;
  }

  double _getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return (width - 1300) / 2;
    if (width > 1200) return (width - 1200) / 2;
    if (width > 800) return 80;
    return 16; // Reduced padding for mobile
  }

  Future<void> _handleShare() async {
    try {
      final url = html.window.location.href;
      // Try Web Share API first
      try {
        await html.window.navigator.share({
          'title': _product.name,
          'text': _product.description,
          'url': url,
        });
        return;
      } catch (e) {
        // Web Share API not available, fall through to clipboard
      }

      // Fallback: Copy to clipboard
      await html.window.navigator.clipboard?.writeText(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share. Please copy the URL manually.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleEnquire() async {
    if (_isEnquiryDialogOpen) return;
    _isEnquiryDialogOpen = true;

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enquire Now'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    _isEnquiryDialogOpen = false;

    if (result == true) {
      final success = await ProductDetailService.submitEnquiry(
        productId: _product.id,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        message: messageController.text.isNotEmpty
            ? messageController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Enquiry submitted successfully!'
                  : 'Failed to submit enquiry. Please try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final maxWidth = _getMaxWidth(context);
    final horizontalPadding = _getHorizontalPadding(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Back and Share buttons
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isWeb ? 24 : 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      size: isWeb ? 24 : 20,
                                      color: const Color(0xFF090919),
                                    ),
                                    SizedBox(width: isWeb ? 10 : 8),
                                    Flexible(
                                      child: Text(
                                        'Back to Products',
                                        style: TextStyle(
                                          color: const Color(0xFF090919),
                                          fontSize: isWeb ? 18 : 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.33,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWeb ? 16 : 10,
                                vertical: isWeb ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF090919),
                                borderRadius: BorderRadius.circular(58),
                              ),
                              child: InkWell(
                                onTap: _handleShare,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isWeb ? 14 : 11,
                                        fontWeight: FontWeight.w600,
                                        height: 1.43,
                                      ),
                                    ),
                                    SizedBox(width: isWeb ? 12 : 6),
                                    Icon(
                                      Icons.share,
                                      size: isWeb ? 20 : 16,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Content
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isWeb ? 32 : 20,
                        ),
                        child: isWeb
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Image Gallery with 3D Model
                                  _buildImageGallery(),
                                  const SizedBox(width: 56),
                                  // Right: Product Details and Key Features
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildProductDetails(),
                                        const SizedBox(height: 20),
                                        _buildKeyFeatures(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImageGallery(),
                                  const SizedBox(height: 24),
                                  _buildProductDetails(),
                                  const SizedBox(height: 24),
                                  _buildKeyFeatures(),
                                ],
                              ),
                      ),

                      // Technical Specifications
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 32,
                        ),
                        child: _buildTechnicalSpecs(),
                      ),

                      // Similar Products
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 64,
                        ),
                        child: _buildSimilarProducts(),
                      ),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Built by ',
                              style: TextStyle(
                                color: const Color(0xFFBABABA),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Ruditech',
                                  style: TextStyle(
                                    color: Color(0xFF5D8BFF),
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildImageGallery() {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final screenWidth = MediaQuery.of(context).size.width;
    final mainImageSize = isWeb ? 500.0 : screenWidth - 64;
    final thumbnailSize = isWeb ? 64.0 : 48.0;
    
    if (isWeb) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail images (left side)
          Column(
            children: _productImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                child: Container(
                  width: thumbnailSize,
                  height: thumbnailSize,
                  margin: const EdgeInsets.only(bottom: 19.2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(5.12),
                    border: _selectedImageIndex == index
                        ? Border.all(color: const Color(0xFF1A1B2D), width: 0.64)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 32,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFFF5F5F7),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F7),
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 19.2),
          // Main Image/3D Model Viewer (center)
          Container(
            width: mainImageSize,
            height: mainImageSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 32,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9.6),
              child: SizedBox(
                width: mainImageSize,
                height: mainImageSize,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: ModelViewerWidget(
                    modelUrl: modelUrl,
                    altText: _product.name,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Mobile layout: thumbnails on top, main viewer below
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail images (horizontal scroll on mobile)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _productImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  child: Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    margin: EdgeInsets.only(
                      right: 12,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(5.12),
                      border: _selectedImageIndex == index
                          ? Border.all(color: const Color(0xFF1A1B2D), width: 2)
                          : Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5.12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF5F5F7),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF5F5F7),
                            child: const Icon(Icons.image, color: Colors.grey, size: 24),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Main Image/3D Model Viewer (full width on mobile)
          Container(
            width: double.infinity,
            height: mainImageSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 32,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9.6),
              child: SizedBox(
                width: double.infinity,
                height: mainImageSize,
                child: ModelViewerWidget(
                  modelUrl: modelUrl,
                  altText: _product.name,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildProductDetails() {
    final isWeb = MediaQuery.of(context).size.width > 800;
    return SizedBox(
      width: isWeb ? 453 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category label (Portable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(73),
            ),
            child: Text(
              _product.category.isNotEmpty ? _product.category : 'Portable',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Product name
          Text(
            _product.name,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.23,
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            _product.description,
            style: const TextStyle(
              color: Color(0xFF2C2C34),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.71,
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons - stacked vertically
          SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // Enquire now button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _handleEnquire,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFED1F24),
                      side: const BorderSide(
                        color: Color(0xFFED1F24),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Enquire now',
                          style: TextStyle(
                            color: Color(0xFFED1F24),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.chat_bubble_outline, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // View In My Space button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to AR view with the specific product's model URL
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ARViewScreen(
                            product: _product,
                            modelUrl:
                                modelUrl, // Uses the specific product's modelUrl
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED1F24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View In My Space',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.43,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.view_in_ar, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFeatures() {
    final features = _product.defaultKeyFeatures;
    final isWeb = MediaQuery.of(context).size.width > 800;

    return SizedBox(
      width: isWeb ? 453 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 453,
            child: const Text(
              'Key Features',
              style: TextStyle(
                color: Color(0xFF090919),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.75,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Display features in two columns on web, single column on mobile
          isWeb
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: features
                            .asMap()
                            .entries
                            .where((entry) => entry.key % 2 == 0)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: 226.5,
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1B2D),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.71,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 71),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: features
                            .asMap()
                            .entries
                            .where((entry) => entry.key % 2 == 1)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: 226.5,
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1B2D),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.71,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: features
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: Color(0xFF1A1B2D),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.71,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecs() {
    final specs = _product.defaultTechnicalSpecs;
    final entries = specs.entries.toList();
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Technical Specifications',
          style: TextStyle(
            color: Color(0xFF090919),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.36,
          ),
        ),
        const SizedBox(height: 40),
        // Two-column grid layout on web, single column on mobile
        isWeb
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: entries
                          .asMap()
                          .entries
                          .where((entry) => entry.key % 2 == 0)
                          .map(
                            (entry) => _buildSpecRow(
                              entry.value.key,
                              entry.value.value,
                              isWeb: true,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 7),
                  // Right column
                  Expanded(
                    child: Column(
                      children: entries
                          .asMap()
                          .entries
                          .where((entry) => entry.key % 2 == 1)
                          .map(
                            (entry) => _buildSpecRow(
                              entry.value.key,
                              entry.value.value,
                              isWeb: true,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              )
            : Column(
                children: entries
                    .map(
                      (entry) =>
                          _buildSpecRow(entry.key, entry.value, isWeb: false),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, {required bool isWeb}) {
    return Container(
      width: isWeb ? 420 : double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFFC6C7D0), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(
            width: isWeb ? 200 : 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1B2D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.43,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF050510),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    final controller = Provider.of<ProductController>(context);
    final allProducts = controller.products;
    final similarProducts = allProducts
        .where((p) => p.id != _product.id)
        .take(3)
        .toList();
    final isWeb = MediaQuery.of(context).size.width > 800;

    if (similarProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Similar Products',
          style: TextStyle(
            color: Color(0xFF090919),
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.36,
          ),
        ),
        const SizedBox(height: 40),
        isWeb
            ? Row(
                children: similarProducts.asMap().entries.map((entry) {
                  final isLast = entry.key == similarProducts.length - 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 24),
                      child: ProductCard(product: entry.value),
                    ),
                  );
                }).toList(),
              )
            : Column(
                children: similarProducts
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ProductCard(product: product),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }
}
