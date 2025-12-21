import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import 'ar_view_screen.dart';
import '../../services/product_detail_service.dart';
import '../../services/device_detection_service.dart';
import '../../utils/responsive_helper.dart';
import '../../config/supabase_config.dart';
import 'product_detail_view_web_stub.dart'
    if (dart.library.html) 'product_detail_view_web.dart'
    as web_utils;

class ProductDetailView extends StatefulWidget {
  final Product product;

  const ProductDetailView({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _selectedImageIndex = 0;
  bool _isLoading = false;
  Product? _enhancedProduct;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _trackProductView();
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    try {
      // Fetch enhanced product details from backend
      final product = await ProductDetailService.fetchProductDetail(
        widget.product.id,
      );
      if (product != null) {
        setState(() => _enhancedProduct = product);
      }
    } catch (e) {
      print('Error loading product details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _trackProductView() async {
    await ProductDetailService.trackProductView(widget.product.id);
  }

  Product get _product => _enhancedProduct ?? widget.product;

  /// Gets the 3D model URL for the current product
  /// Uses the product's modelUrl if available, otherwise falls back to default
  /// Converts to proxy URL for better CORS support with Google Scene Viewer
  String get modelUrl {
    // Always use the product's specific modelUrl if it exists
    final productModelUrl = _product.modelUrl;
    if (productModelUrl != null && productModelUrl.isNotEmpty) {
      // Convert to proxy URL for CORS support
      return SupabaseConfig.convertToProxyUrl(productModelUrl);
    }
    // Fallback to default model (should not be needed if products are configured correctly)
    final fallbackUrl =
        'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_EASEL%20STANDEE%20.glb';
    // Convert to proxy URL if enabled, otherwise use direct URL
    return SupabaseConfig.convertToProxyUrl(fallbackUrl);
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
    return ResponsiveHelper.getMaxContentWidth(context);
  }

  double _getHorizontalPadding(BuildContext context) {
    return ResponsiveHelper.getHorizontalPadding(context);
  }

  Future<void> _handleShare() async {
    if (!kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing is only available on web.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final url = web_utils.WebUtils.getCurrentUrl();
      // Try Web Share API first
      final shared = await web_utils.WebUtils.shareContent(
        _product.name,
        _product.description,
        url,
      );

      if (shared) return;

      // Fallback: Copy to clipboard
      final copied = await web_utils.WebUtils.copyToClipboard(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              copied
                  ? 'Link copied to clipboard!'
                  : 'Failed to share. Please copy the URL manually.',
            ),
            duration: const Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final maxWidth = _getMaxWidth(context);
    final horizontalPadding = _getHorizontalPadding(context);

    // Debug: Print current state
    if (kDebugMode) {
      print(
        'ProductDetailView build - isLoading: $_isLoading, product: ${_product.name}',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading && _enhancedProduct == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header + main hero section (no tinted background)
                        Container(
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with Back and Share buttons
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.arrow_back,
                                            size: 24,
                                            color: Color(0xFF090919),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Back to Products',
                                            style: TextStyle(
                                              color: Color(0xFF090919),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              height: 1.33,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
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
                                            const Text(
                                              'Share',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                height: 1.43,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.share,
                                              size: 20,
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
                                  vertical: 32,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return isDesktop
                                        ? Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Left: Image Gallery
                                              Flexible(
                                                flex: 1,
                                                child: _buildImageGallery(),
                                              ),
                                              SizedBox(
                                                width:
                                                    ResponsiveHelper.isTablet(
                                                      context,
                                                    )
                                                    ? 32
                                                    : 56,
                                              ),
                                              // Right: Product Details and Key Features
                                              Flexible(
                                                flex: 1,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _buildProductDetails(),
                                                    SizedBox(
                                                      height:
                                                          ResponsiveHelper.getResponsiveSpacing(
                                                            context,
                                                            mobile: 20,
                                                            tablet: 20,
                                                            desktop: 20,
                                                          ),
                                                    ),
                                                    _buildKeyFeatures(),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildImageGallery(),
                                              SizedBox(
                                                height:
                                                    ResponsiveHelper.getResponsiveSpacing(
                                                      context,
                                                      mobile: 24,
                                                      tablet: 28,
                                                      desktop: 32,
                                                    ),
                                              ),
                                              _buildProductDetails(),
                                              SizedBox(
                                                height:
                                                    ResponsiveHelper.getResponsiveSpacing(
                                                      context,
                                                      mobile: 24,
                                                      tablet: 28,
                                                      desktop: 32,
                                                    ),
                                              ),
                                              _buildKeyFeatures(),
                                            ],
                                          );
                                  },
                                ),
                              ),
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
            ),
    );
  }

  Widget _buildImageGallery() {
    final isMobile = ResponsiveHelper.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final thumbnailSize = ResponsiveHelper.getResponsiveSpacing(
      context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
    );

    // Safety check for images
    if (_productImages.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Text('No images available')),
      );
    }

    final mainImageUrl = _productImages[_selectedImageIndex];

    // Main hero product image (white card)
    Widget buildMainImage(double maxWidth) {
      // More compact card so image + details feel lighter
      return Container(
        width: maxWidth,
        height: maxWidth, // square-ish, smaller overall height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFF8F9FA),
            child: Image.network(
              mainImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
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
                      color: const Color(0xFFED1F24),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F7),
                  child: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Thumbnail widget used in both mobile (horizontal) and desktop (vertical)
    Widget buildThumbnailItem({
      required String imageUrl,
      required bool isSelected,
      EdgeInsetsGeometry margin = EdgeInsets.zero,
      double? width,
      double? height,
      VoidCallback? onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: width ?? thumbnailSize,
          height: height ?? thumbnailSize,
          margin: margin,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFFED1F24), width: 2)
                : Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      );
    }

    // Thumbnail row used on mobile (horizontal)
    Widget buildThumbnailsRow() {
      return SizedBox(
        width: double.infinity,
        height: thumbnailSize + 20,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _productImages.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final imageUrl = _productImages[index];
            final isSelected = _selectedImageIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              child: Container(
                width: thumbnailSize,
                height: thumbnailSize,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: const Color(0xFFED1F24), width: 2)
                      : Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
          },
        ),
      );
    }

    // Use a slightly smaller hero width so the image container is reduced
    // and better balanced with the details column.
    // Re‑use the existing `isMobile` defined above.
    final double mainWidth = isMobile ? screenWidth * 0.7 : 320.0;

    if (isMobile) {
      // Mobile: main image centered with thumbnails below (horizontal strip)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildMainImage(mainWidth),
          const SizedBox(height: 16),
          buildThumbnailsRow(),
        ],
      );
    }

    // Desktop / tablet: thumbnails column outside the product container on the left
    // Make this column scrollable so ALL images are accessible.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: mainWidth, // match the main image card height
          width: 56, // a bit wider than the thumbnail width
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _productImages.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final imageUrl = _productImages[index];
              final isSelected = _selectedImageIndex == index;
              return buildThumbnailItem(
                imageUrl: imageUrl,
                isSelected: isSelected,
                width: 48,
                height: 72,
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(width: 24),
        buildMainImage(mainWidth),
      ],
    );
  }

  Widget _buildProductDetails() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      width: isDesktop ? 453 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portable label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(73),
            ),
            child: Text(
              _product.category.isNotEmpty ? _product.category : 'Portable',
              style: TextStyle(
                color: Colors.black,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 11,
                  tablet: 11,
                  desktop: 12,
                ),
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Product name
          SizedBox(
            width: isMobile
                ? double.infinity
                : (isDesktop ? 333 : double.infinity),
            child: Text(
              _product.name,
              style: TextStyle(
                color: Colors.black,
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 22,
                  tablet: 24,
                  desktop: 26,
                ),
                fontWeight: FontWeight.w600,
                height: 1.23,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Description
          SizedBox(
            width: isMobile
                ? double.infinity
                : (isDesktop ? 440 : double.infinity),
            child: Text(
              _product.description,
              style: TextStyle(
                color: const Color(0xFF2C2C34),
                fontSize: ResponsiveHelper.getResponsiveFontSize(
                  context,
                  mobile: 13,
                  tablet: 14,
                  desktop: 14,
                ),
                fontWeight: FontWeight.w400,
                height: 1.71,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Action buttons - responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = ResponsiveHelper.isMobile(context);
              final buttonSpacing = isMobile ? 12.0 : 16.0;
              final buttonPadding = isMobile
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
              final buttonFontSize = isMobile ? 12.0 : 14.0;
              final iconSize = isMobile ? 16.0 : 18.0;

              return SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    // Enquire now button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final uri = Uri.parse('https://wa.me/916369869996');
                          if (!await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not open WhatsApp'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFED1F24),
                          side: const BorderSide(
                            color: Color(0xFFED1F24),
                            width: 1,
                          ),
                          padding: buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Enquire now',
                                style: TextStyle(
                                  color: const Color(0xFFED1F24),
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.43,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isMobile ? 4 : 8),
                            Icon(Icons.chat_bubble_outline, size: iconSize),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: buttonSpacing),
                    // View In My Space button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Check if device is desktop
                          if (DeviceDetectionService.isDesktop(context)) {
                            // Show snackbar on desktop
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'AR is only available on mobile and tablet devices. Please open this website on your mobile or tablet to experience AR.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFFED1F24),
                                duration: const Duration(seconds: 5),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'OK',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                            return;
                          }

                          // Navigate to AR view - let the AR screen handle availability checks
                          // This allows the AR view to appear even on emulators (with appropriate error message)
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
                          backgroundColor:
                              DeviceDetectionService.isDesktop(context)
                              ? Colors.grey[400]
                              : const Color(0xFFED1F24),
                          foregroundColor: Colors.white,
                          padding: buttonPadding,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                isMobile ? 'View AR' : 'View In My Space',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.43,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isMobile ? 4 : 8),
                            Icon(
                              DeviceDetectionService.isDesktop(context)
                                  ? Icons.block
                                  : Icons.view_in_ar,
                              size: iconSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFeatures() {
    final features = _product.defaultKeyFeatures;
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return SizedBox(
      width: isDesktop ? 453 : double.infinity,
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
          // Display features in two columns on desktop, single column on mobile/tablet
          isDesktop
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
                                    '• ${entry.value}',
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
                                    '• ${entry.value}',
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
                            '• $feature',
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
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Technical Specifications',
          style: TextStyle(
            color: const Color(0xFF090919),
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 21,
              desktop: 22,
            ),
            fontWeight: FontWeight.w600,
            height: 1.36,
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.getResponsiveSpacing(
            context,
            mobile: 32,
            tablet: 36,
            desktop: 40,
          ),
        ),
        // Two-column grid layout on desktop, single column on mobile/tablet
        isDesktop
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
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      // Let the row take up the full available width from its parent
      // so we don't overflow on smaller screens.
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveHelper.getResponsiveSpacing(
          context,
          mobile: 10,
          tablet: 11,
          desktop: 12,
        ),
      ),
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
            width: isWeb ? 200 : (isMobile ? 120 : 150),
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
    // Temporarily hide similar products section.
    // Once the admin panel is live and we have real
    // related products configured, this can be re-enabled.
    return const SizedBox.shrink();
  }
}
