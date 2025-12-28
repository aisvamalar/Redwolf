import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../models/product.dart';
import 'ar_view_screen.dart';
import '../../services/product_detail_service.dart';
import '../../services/product_service.dart';
import '../../services/analytics_service.dart';
import '../../services/device_detection_service.dart';
import '../../utils/responsive_helper.dart';
import '../../config/supabase_config.dart';
import '../widgets/product_card.dart';
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
  List<Product> _similarProducts = [];
  bool _isLoadingSimilar = false;
  // Track image load retry attempts
  final Map<String, int> _imageRetryCount = {};
  final Map<String, bool> _imageLoadErrors = {};

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _trackProductView();
    _loadSimilarProducts();
  }

  Future<void> _loadProductDetails() async {
    if (widget.product.id == null) return;

    setState(() => _isLoading = true);
    try {
      // Fetch enhanced product details from backend
      final product = await ProductDetailService.fetchProductDetail(
        widget.product.id!,
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
    if (widget.product.id != null) {
      final analyticsService = AnalyticsService();
      await analyticsService.trackProductView(widget.product.id!);
    }
  }

  Future<void> _loadSimilarProducts() async {
    setState(() => _isLoadingSimilar = true);
    try {
      final productService = ProductService();
      // Fetch all published products
      final allProducts = await productService.getProducts(forceRefresh: false);

      // Filter similar products:
      // 1. Exclude current product
      // 2. Same category preferred, or any other products
      // 3. Must have GLB file for AR viewing
      final currentProduct = _product;
      final similar = allProducts
          .where(
            (p) =>
                p.id != currentProduct.id && // Exclude current product
                p.glbFileUrl != null &&
                p.glbFileUrl!.isNotEmpty && // Must have AR model
                p.status == 'Published',
          ) // Only published products
          .toList();

      // Sort by category match first, then take up to 6 products
      similar.sort((a, b) {
        final aMatchesCategory = a.category == currentProduct.category ? 1 : 0;
        final bMatchesCategory = b.category == currentProduct.category ? 1 : 0;
        return bMatchesCategory.compareTo(aMatchesCategory);
      });

      setState(() {
        _similarProducts = similar
            .take(6)
            .toList(); // Show max 6 similar products
        _isLoadingSimilar = false;
      });
    } catch (e) {
      print('Error loading similar products: $e');
      setState(() => _isLoadingSimilar = false);
    }
  }

  Product get _product => _enhancedProduct ?? widget.product;

  /// Gets the 3D model URL for the current product
  /// Uses the product's glbFileUrl if available, otherwise falls back to modelUrl
  /// Converts to proxy URL for better CORS support with Google Scene Viewer
  String get modelUrl {
    // Always use the product's specific glbFileUrl if it exists (from database)
    final productModelUrl = _product.glbFileUrl ?? _product.modelUrl;
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

  /// Get direct model URL (bypass proxy) - needed for Apple Quick Look AR
  /// For iOS devices, prioritize USDZ file if available from usdz/ folder
  /// For non-iOS devices, always use GLB file
  String get _directModelUrl {
    // Check if device is iOS (iPhone/iPad)
    final isIOS = DeviceDetectionService.isIOS(context);

    // For iOS devices, prioritize USDZ file if available
    // USDZ files are stored in products/usdz/ folder in Supabase storage
    if (isIOS &&
        _product.usdzFileUrl != null &&
        _product.usdzFileUrl!.isNotEmpty &&
        _product.usdzFileUrl!.toUpperCase() != 'NULL' &&
        !_product.usdzFileUrl!.contains('/NULL')) {
      // Ensure the URL points to the usdz/ folder
      // The URL should be: https://...supabase.co/storage/v1/object/public/products/usdz/filename.usdz
      if (kDebugMode) {
        print('Using USDZ file for AR Quick Look: ${_product.usdzFileUrl}');
      }
      return _product.usdzFileUrl!;
    }

    // For non-iOS devices, always use GLB file
    // Always use the product's specific glbFileUrl if it exists (from database)
    final productModelUrl = _product.glbFileUrl ?? _product.modelUrl;
    if (productModelUrl != null && productModelUrl.isNotEmpty) {
      // Return direct URL (not proxy) for Apple Quick Look compatibility
      return productModelUrl;
    }
    // Fallback to default model
    return 'https://zsipfgtlfnfvmnrohtdo.supabase.co/storage/v1/object/public/products/products/glb/32_EASEL%20STANDEE%20.glb';
  }

  /// Check if the model URL is a USDZ file
  /// Supports various URL formats including query parameters and fragments
  bool _isUsdzFile(String url) {
    if (url.isEmpty) return false;
    final lowerUrl = url.toLowerCase().trim();

    // Check for .usdz extension (most common)
    if (lowerUrl.endsWith('.usdz')) return true;

    // Check for .usdz with query parameters
    if (lowerUrl.contains('.usdz?')) return true;

    // Check for .usdz with fragment
    if (lowerUrl.contains('.usdz#')) return true;

    // Check if URL contains 'usdz' (fallback for edge cases)
    // But make sure it's not part of another word like 'usdzfile' or path like '/usdz/'
    final usdzIndex = lowerUrl.indexOf('usdz');
    if (usdzIndex != -1) {
      // Check if it's a file extension (preceded by a dot)
      if (usdzIndex > 0 && lowerUrl[usdzIndex - 1] == '.') {
        return true;
      }
    }

    return false;
  }

  /// Navigate back - handles both web and mobile properly
  void _navigateBack() {
    // Try to pop first (works with context.push navigation)
    if (context.canPop()) {
      context.pop();
    } else {
      // If we can't pop (e.g., direct URL access or deep link), navigate to home
      if (kIsWeb) {
        // On web, try browser history first
        web_utils.WebUtils.navigateBack();
      } else {
        // On mobile, go to home
        context.go('/');
      }
    }
  }

  /// Open Ruditech website
  void _openRuditechWebsite() async {
    final uri = Uri.parse('https://ruditech.com/');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Ruditech website'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening Ruditech website'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<String> get _productImages {
    // Use images from database: thumbnail, secondImageUrl, thirdImageUrl
    final List<String> imageList = [];
    if (_product.imageUrl.isNotEmpty) {
      imageList.add(_product.imageUrl);
    }
    if (_product.secondImageUrl != null &&
        _product.secondImageUrl!.isNotEmpty) {
      imageList.add(_product.secondImageUrl!);
    }
    if (_product.thirdImageUrl != null && _product.thirdImageUrl!.isNotEmpty) {
      imageList.add(_product.thirdImageUrl!);
    }

    // Fallback to images property if available
    if (imageList.isEmpty &&
        _product.images != null &&
        _product.images!.isNotEmpty) {
      return _product.images!;
    }

    // If still empty, return at least the thumbnail
    if (imageList.isEmpty) {
      return [_product.imageUrl];
    }

    return imageList;
  }

  double _getMaxWidth(BuildContext context) {
    return ResponsiveHelper.getMaxContentWidth(context);
  }

  double _getHorizontalPadding(BuildContext context) {
    return ResponsiveHelper.getHorizontalPadding(context);
  }

  Future<void> _handleShare() async {
    try {
      // Format product details as structured text
      final String productText = _formatProductDetailsForSharing();
      final String productImageUrl = _product.imageUrl;

      print('🔗 Sharing product details and image: ${_product.name}');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Preparing to share product...'),
              ],
            ),
            duration: Duration(milliseconds: 1500),
            backgroundColor: Color(0xFF2196F3),
          ),
        );
      }

      bool shared = false;

      if (kIsWeb) {
        // Try Web Share API first (works on mobile browsers too)
        // Combine product text with image URL for sharing
        final fullShareText = '$productText\n\n🖼️ Image: $productImageUrl';

        shared = await web_utils.WebUtils.shareContent(
          _product.name,
          fullShareText,
          '', // Don't pass URL separately, it's included in the text
        );

        if (!shared) {
          // Fallback: Copy to clipboard
          final copied = await web_utils.WebUtils.copyToClipboard(
            fullShareText,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      copied ? Icons.check_circle : Icons.error,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        copied
                            ? 'Product details copied to clipboard!'
                            : 'Failed to copy. Please copy manually.',
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: copied ? Colors.green : Colors.red,
                action: copied
                    ? null
                    : SnackBarAction(
                        label: 'Show Details',
                        textColor: Colors.white,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Product Details'),
                              content: SelectableText(productText),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            );
          }
        } else {
          // Share API worked - no success message needed
        }
      } else {
        // For mobile apps, show product details in a dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Share Product'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Copy product details to share:'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      productText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Image URL:'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: SelectableText(
                      productImageUrl,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final fullContent =
                        '$productText\n\n🖼️ Image: $productImageUrl';
                    Clipboard.setData(ClipboardData(text: fullContent));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product details copied to clipboard!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Copy Details'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to share: ${e.toString()}')),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
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

    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading && _enhancedProduct == null
          ? _buildLoadingSkeleton()
          : SafeArea(
              child: SingleChildScrollView(
                child: isMobile
                    ? Column(
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
                                        onTap: _navigateBack,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      final isTablet =
                                          ResponsiveHelper.isTablet(context);

                                      // Desktop: Side-by-side layout
                                      if (isDesktop && !isTablet) {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Left: Image Gallery
                                            Flexible(
                                              flex: 1,
                                              child: _buildImageGallery(),
                                            ),
                                            const SizedBox(width: 56),
                                            // Right: Product Details and Key Features
                                            Flexible(
                                              flex: 1,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                            ),
                                          ],
                                        );
                                      }

                                      // Tablet/iPad and Mobile: Centered column layout
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Centered image gallery
                                          Center(child: _buildImageGallery()),
                                          SizedBox(
                                            height:
                                                ResponsiveHelper.getResponsiveSpacing(
                                                  context,
                                                  mobile: 24,
                                                  tablet: 28,
                                                  desktop: 32,
                                                ),
                                          ),
                                          // Product details (centered for tablet, left-aligned for mobile)
                                          Align(
                                            alignment: isTablet
                                                ? Alignment.center
                                                : Alignment.centerLeft,
                                            child: _buildProductDetails(),
                                          ),
                                          SizedBox(
                                            height:
                                                ResponsiveHelper.getResponsiveSpacing(
                                                  context,
                                                  mobile: 24,
                                                  tablet: 28,
                                                  desktop: 32,
                                                ),
                                          ),
                                          // Key features (left-aligned for all devices)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: _buildKeyFeatures(),
                                          ),
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
                            padding: EdgeInsets.only(top: 64, bottom: 0),
                            child: _buildSimilarProducts(),
                          ),

                          // Footer
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _openRuditechWebsite,
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
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      )
                    : Center(
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
                                            onTap: _navigateBack,
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                          final isTablet =
                                              ResponsiveHelper.isTablet(
                                                context,
                                              );

                                          // Desktop: Side-by-side layout
                                          if (isDesktop && !isTablet) {
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Left: Image Gallery
                                                Flexible(
                                                  flex: 1,
                                                  child: _buildImageGallery(),
                                                ),
                                                const SizedBox(width: 56),
                                                // Right: Product Details and Key Features
                                                Flexible(
                                                  flex: 1,
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
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
                                                ),
                                              ],
                                            );
                                          }

                                          // Tablet/iPad and Mobile: Centered column layout
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // Centered image gallery
                                              Center(
                                                child: _buildImageGallery(),
                                              ),
                                              SizedBox(
                                                height:
                                                    ResponsiveHelper.getResponsiveSpacing(
                                                      context,
                                                      mobile: 24,
                                                      tablet: 28,
                                                      desktop: 32,
                                                    ),
                                              ),
                                              // Product details (centered for tablet, left-aligned for mobile)
                                              Align(
                                                alignment: isTablet
                                                    ? Alignment.center
                                                    : Alignment.centerLeft,
                                                child: _buildProductDetails(),
                                              ),
                                              SizedBox(
                                                height:
                                                    ResponsiveHelper.getResponsiveSpacing(
                                                      context,
                                                      mobile: 24,
                                                      tablet: 28,
                                                      desktop: 32,
                                                    ),
                                              ),
                                              // Key features (left-aligned for all devices)
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: _buildKeyFeatures(),
                                              ),
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
                                padding: EdgeInsets.only(top: 64, bottom: 0),
                                child: _buildSimilarProducts(),
                              ),

                              // Footer
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _openRuditechWebsite,
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
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
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
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Safety check for images
    if (_productImages.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Text('No images available')),
      );
    }
    // IMPORTANT: use *actual* available width (prevents RenderFlex overflow on web)
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Mobile: main image centered with thumbnails below (horizontal strip)
        if (isMobile) {
          final mainWidth = (screenWidth - 32).clamp(0.0, availableWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainImage(mainWidth),
              const SizedBox(height: 16),
              _buildThumbnailsRow(),
            ],
          );
        }

        // Tablet/iPad: Centered layout with thumbnails below
        if (isTablet) {
          final mainWidth = availableWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMainImage(mainWidth),
              const SizedBox(height: 20),
              _buildThumbnailsRow(),
            ],
          );
        }

        // Desktop: thumbnails column on the left, main image on the right
        const thumbColWidth = 56.0;
        const gap = 24.0;
        final mainWidth = (availableWidth - thumbColWidth - gap).clamp(
          220.0,
          availableWidth,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: mainWidth * 0.9,
              width: thumbColWidth,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _productImages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final imageUrl = _productImages[index];
                  final isSelected = _selectedImageIndex == index;
                  return _buildThumbnailItem(
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
            const SizedBox(width: gap),
            _buildMainImage(mainWidth),
          ],
        );
      },
    );
  }

  Widget _buildMainImage(double maxWidth) {
    // Optimized size for better display with improved centering
    final imageWidth = maxWidth * 0.85; // Reduced for better centering
    final imageHeight = imageWidth * 1.0; // Square aspect ratio

    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (_productImages.length > 1 && event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              _selectedImageIndex =
                  (_selectedImageIndex + 1) % _productImages.length;
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              _selectedImageIndex =
                  (_selectedImageIndex - 1 + _productImages.length) %
                  _productImages.length;
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        // Enhanced swipe gesture detection for hand swipes
        // Lower threshold (200 instead of 0) makes swipes more responsive
        onHorizontalDragEnd: (details) {
          if (_productImages.length > 1) {
            // Swipe left (negative velocity) = next image
            if (details.primaryVelocity! < -100) {
              setState(() {
                _selectedImageIndex =
                    (_selectedImageIndex + 1) % _productImages.length;
              });
            }
            // Swipe right (positive velocity) = previous image
            else if (details.primaryVelocity! > 100) {
              setState(() {
                _selectedImageIndex =
                    (_selectedImageIndex - 1 + _productImages.length) %
                    _productImages.length;
              });
            }
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: imageWidth,
              maxHeight: imageHeight,
            ),
            child: SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Stack(
                children: [
                  // Main Image - centered with retry mechanism
                  _buildImageWithRetry(
                    _productImages[_selectedImageIndex],
                    imageWidth,
                    imageHeight,
                  ),

                  // Navigation overlay - invisible clickable areas (for tap navigation)
                  Row(
                    children: [
                      // Left side - previous image
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_productImages.length > 1) {
                              setState(() {
                                _selectedImageIndex =
                                    (_selectedImageIndex -
                                        1 +
                                        _productImages.length) %
                                    _productImages.length;
                              });
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            height: double.infinity,
                          ),
                        ),
                      ),

                      // Right side - next image
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_productImages.length > 1) {
                              setState(() {
                                _selectedImageIndex =
                                    (_selectedImageIndex + 1) %
                                    _productImages.length;
                              });
                            }
                          },
                          child: Container(
                            color: Colors.transparent,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Image indicator dots
                  if (_productImages.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _productImages.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _selectedImageIndex
                                  ? const Color(0xFFED1F24)
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailItem({
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
        width: width ?? 48,
        height: height ?? 48,
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
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_outlined, size: 24),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build image with retry mechanism for failed loads
  Widget _buildImageWithRetry(String imageUrl, double width, double height) {
    final retryCount = _imageRetryCount[imageUrl] ?? 0;

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      width: width,
      height: height,
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
        // Mark as error and allow retry
        if (!_imageLoadErrors.containsKey(imageUrl)) {
          _imageLoadErrors[imageUrl] = true;
        }

        return Container(
          color: const Color(0xFFF5F5F7),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 8),
                if (retryCount < 3)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _imageRetryCount[imageUrl] = retryCount + 1;
                        _imageLoadErrors.remove(imageUrl);
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFED1F24),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build skeleton loader for loading state
  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        children: [
          // Image skeleton
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          // Text skeletons
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 300,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailsRow() {
    final thumbnailSize = ResponsiveHelper.getResponsiveSpacing(
      context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
    );
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

  Widget _buildProductDetails() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      width: isDesktop ? 453 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              _product.description ?? '',
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
              final buttonSpacing = 12.0; // Reduced spacing
              // Smaller button padding for mobile
              final buttonPadding = EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 14,
              );
              final buttonFontSize = isMobile
                  ? 14.0
                  : 16.0; // Smaller font on mobile
              final iconSize = isMobile ? 16.0 : 18.0; // Smaller icon on mobile

              // Stack buttons vertically on narrow screens
              final isNarrowScreen = constraints.maxWidth < 400;

              return SizedBox(
                width: double.infinity,
                child: isNarrowScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Enquire now button - white background with red border
                          OutlinedButton(
                            onPressed: () async {
                              final uri = Uri.parse(
                                'https://wa.me/916369869996',
                              );
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
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFED1F24),
                              side: const BorderSide(
                                color: Color(0xFFDC2626),
                                width: 1.5,
                              ),
                              padding: buttonPadding,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Enquire now',
                                    style: TextStyle(
                                      color: const Color(0xFFDC2626),
                                      fontSize: buttonFontSize,
                                      fontWeight: FontWeight.w600,
                                      height: 1.43,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 4 : 8),
                                FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  size: iconSize,
                                  color: const Color(0xFFDC2626),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: buttonSpacing),
                          // View In My Space button
                          Builder(
                            builder: (context) {
                              // Check device type - only allow on mobile, tablet, and iPad
                              final isMobile = DeviceDetectionService.isMobile(
                                context,
                              );
                              final isTablet = DeviceDetectionService.isTablet(
                                context,
                              );
                              // Simple iOS/iPad detection (original working method)
                              final isIOS =
                                  DeviceDetectionService.isIOS(context) ||
                                  DeviceDetectionService.isProbablyIPad(
                                    context,
                                  );

                              // AR is only available on mobile, tablet, and iPad (not desktop)
                              final isARSupported =
                                  isMobile || isTablet || isIOS;

                              return ElevatedButton(
                                onPressed: isARSupported
                                    ? () async {
                                        try {
                                          // Check if we have a model file
                                          final hasGlbFile =
                                              _product.glbFileUrl != null &&
                                              _product.glbFileUrl!.isNotEmpty;
                                          final hasUsdzFileInDb =
                                              _product.usdzFileUrl != null &&
                                              _product.usdzFileUrl!.isNotEmpty;
                                          final hasModelUrl =
                                              _product.modelUrl != null &&
                                              _product.modelUrl!.isNotEmpty;

                                          if (!hasGlbFile &&
                                              !hasUsdzFileInDb &&
                                              !hasModelUrl) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No 3D model file available for this product. Please contact support.',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFFED1F24,
                                                  ),
                                                  duration: Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                            return;
                                          }

                                          // Use device detection from Builder context (already checked above)
                                          final isTabletByUA =
                                              DeviceDetectionService.isTabletByUserAgent();

                                          // For iOS devices, check if USDZ file is available
                                          // Exclude "NULL" string values
                                          final hasUsdzFile =
                                              _product.usdzFileUrl != null &&
                                              _product
                                                  .usdzFileUrl!
                                                  .isNotEmpty &&
                                              _product.usdzFileUrl!
                                                      .toUpperCase() !=
                                                  'NULL' &&
                                              !_product.usdzFileUrl!.contains(
                                                '/NULL',
                                              );

                                          // Check if the model URL (from glbFileUrl or modelUrl) is actually a USDZ file
                                          // This is critical because sometimes USDZ files are stored in glbFileUrl field
                                          final glbFileUrl =
                                              _product.glbFileUrl ??
                                              _product.modelUrl ??
                                              '';
                                          final isGlbFileUsdz = _isUsdzFile(
                                            glbFileUrl,
                                          );

                                          // Check if the direct model URL being used is USDZ
                                          final isDirectModelUsdz = _isUsdzFile(
                                            _directModelUrl,
                                          );

                                          // Only consider it a USDZ file if the actual file being used is USDZ
                                          // Check the direct model URL that will be used for AR
                                          final isUsdzFile =
                                              isDirectModelUsdz ||
                                              isGlbFileUsdz;

                                          if (kDebugMode) {
                                            print(
                                              '=== USDZ Detection Debug ===',
                                            );
                                            print(
                                              'hasUsdzFile (usdzFileUrl): $hasUsdzFile',
                                            );
                                            print(
                                              'isGlbFileUsdz (glbFileUrl): $isGlbFileUsdz',
                                            );
                                            print('glbFileUrl: $glbFileUrl');
                                            print(
                                              'Final isUsdzFile: $isUsdzFile',
                                            );
                                            print(
                                              '============================',
                                            );
                                          }

                                          if (kDebugMode) {
                                            print(
                                              '=== AR LAUNCH DEBUG INFO ===',
                                            );
                                            print(
                                              'Direct Model URL: $_directModelUrl',
                                            );
                                            print(
                                              'Model URL (proxy): $modelUrl',
                                            );
                                            print('Is USDZ File: $isUsdzFile');
                                            print('Is iOS Device: $isIOS');
                                            print('Is Tablet: $isTablet');
                                            print(
                                              'Is Tablet by UA: $isTabletByUA',
                                            );
                                            print('Is Web: $kIsWeb');
                                            if (kIsWeb) {
                                              try {
                                                // Try to get user agent for debugging
                                                final userAgent = web_utils
                                                    .WebUtils.getUserAgent();
                                                print('User Agent: $userAgent');
                                                print(
                                                  'Contains "ipad": ${userAgent.toLowerCase().contains('ipad')}',
                                                );
                                                print(
                                                  'Contains "iphone": ${userAgent.toLowerCase().contains('iphone')}',
                                                );
                                              } catch (e) {
                                                print(
                                                  'Could not get user agent: $e',
                                                );
                                              }
                                            }
                                            print(
                                              '============================',
                                            );
                                          }

                                          // For iOS devices (iPhone/iPad), prioritize Apple Quick Look AR
                                          // Try USDZ first, but also check if we should use Quick Look for other formats
                                          if (isIOS && isUsdzFile) {
                                            // For iOS devices (iPhone/iPad) with USDZ files, use Apple Quick Look AR
                                            // iOS Safari automatically opens USDZ files in AR Quick Look when linked directly
                                            // iPad Safari also supports AR Quick Look for USDZ files
                                            // We need to use the direct URL (not proxy) for Apple Quick Look to work
                                            try {
                                              // Use direct URL for Apple Quick Look (bypass proxy)
                                              final directUrl = _directModelUrl;

                                              if (kDebugMode) {
                                                print(
                                                  'Launching USDZ AR with URL: $directUrl',
                                                );
                                              }

                                              // Track AR view before launching
                                              if (_product.id != null) {
                                                final analyticsService =
                                                    AnalyticsService();
                                                await analyticsService
                                                    .trackARView(_product.id!);
                                              }

                                              // Simple USDZ AR launch (original working method)
                                              if (kIsWeb) {
                                                // Use the original working method for iPad
                                                if (kDebugMode) {
                                                  print(
                                                    '=== iPad AR Launch Debug ===',
                                                  );
                                                  print(
                                                    'Product: ${_product.name}',
                                                  );
                                                  print(
                                                    'USDZ URL from DB: ${_product.usdzFileUrl}',
                                                  );
                                                  print(
                                                    'Direct URL being used: $directUrl',
                                                  );
                                                  print(
                                                    'URL contains spaces: ${directUrl.contains(' ')}',
                                                  );
                                                  print(
                                                    'URL length: ${directUrl.length}',
                                                  );
                                                  print(
                                                    '============================',
                                                  );
                                                }
                                                await web_utils
                                                    .WebUtils.openUsdzInAR(
                                                  directUrl,
                                                );
                                              } else {
                                                // For non-web platforms, use URL launcher
                                                final uri = Uri.parse(
                                                  directUrl,
                                                );
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              }
                                            } catch (e) {
                                              print(
                                                'Error launching USDZ AR: $e',
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Error opening AR. Please try again.',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFFED1F24,
                                                    ),
                                                    duration: Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          } else if (isIOS && !isUsdzFile) {
                                            // iOS device but no USDZ file - use regular AR viewer
                                            try {
                                              // Track AR view
                                              if (_product.id != null) {
                                                final analyticsService =
                                                    AnalyticsService();
                                                await analyticsService
                                                    .trackARView(_product.id!);
                                              }

                                              // Use regular AR viewer for GLB files
                                              final glbUrl =
                                                  _product.glbFileUrl ??
                                                  _product.modelUrl;
                                              if (glbUrl != null &&
                                                  glbUrl.isNotEmpty &&
                                                  mounted) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ARViewScreen(
                                                          product: _product,
                                                          modelUrl: glbUrl,
                                                        ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              print(
                                                'Error opening AR viewer: $e',
                                              );
                                            }
                                          } else if (!isIOS && isUsdzFile) {
                                            // Non-iOS device trying to use USDZ file - USDZ is Apple-only
                                            // BUT: Double-check if this is actually an iPad that wasn't detected correctly
                                            // Some iPad Safari user agents might not contain "ipad" string
                                            final recheckIOS =
                                                DeviceDetectionService.isIOS(
                                                  context,
                                                );
                                            final recheckTablet =
                                                DeviceDetectionService.isTablet(
                                                  context,
                                                );

                                            if (kDebugMode) {
                                              print(
                                                '=== iPad Detection Recheck ===',
                                              );
                                              print('Initial isIOS: $isIOS');
                                              print(
                                                'Recheck isIOS: $recheckIOS',
                                              );
                                              print(
                                                'Recheck isTablet: $recheckTablet',
                                              );
                                              if (kIsWeb) {
                                                try {
                                                  final userAgent = web_utils
                                                      .WebUtils.getUserAgent();
                                                  final userAgentLower =
                                                      userAgent.toLowerCase();
                                                  print(
                                                    'User Agent: $userAgent',
                                                  );
                                                  print(
                                                    'Contains "ipad": ${userAgentLower.contains('ipad')}',
                                                  );
                                                  print(
                                                    'Contains "iphone": ${userAgentLower.contains('iphone')}',
                                                  );
                                                  print(
                                                    'Contains "macintel": ${userAgentLower.contains('macintel')}',
                                                  );
                                                  print(
                                                    'Contains "macintosh": ${userAgentLower.contains('macintosh')}',
                                                  );
                                                  print(
                                                    'Has Touch Support: ${DeviceDetectionService.hasTouchSupport()}',
                                                  );
                                                  print(
                                                    'Max Touch Points: ${web_utils.WebUtils.getMaxTouchPoints()}',
                                                  );
                                                } catch (e) {
                                                  print(
                                                    'Error getting user agent: $e',
                                                  );
                                                }
                                              }
                                              print(
                                                '=============================',
                                              );
                                            }

                                            // Enhanced iPad detection: Check for MacIntel/Macintosh with touch
                                            // This should work even if tablet detection fails
                                            bool isLikelyIPad = false;
                                            if (kIsWeb) {
                                              try {
                                                final hasTouch =
                                                    DeviceDetectionService.hasTouchSupport();
                                                if (hasTouch) {
                                                  final userAgent =
                                                      web_utils
                                                              .WebUtils.getUserAgent()
                                                          .toLowerCase();
                                                  // Check for MacIntel/Macintosh (iPadOS 13+)
                                                  if (userAgent.contains(
                                                        'macintel',
                                                      ) ||
                                                      userAgent.contains(
                                                        'macintosh',
                                                      )) {
                                                    final maxTouchPoints = web_utils
                                                        .WebUtils.getMaxTouchPoints();
                                                    if (maxTouchPoints > 1) {
                                                      isLikelyIPad = true;
                                                      if (kDebugMode) {
                                                        print(
                                                          '✅ Enhanced iPad detection: MacIntel/Macintosh + touch + maxTouchPoints=$maxTouchPoints = iPad detected!',
                                                        );
                                                      }
                                                    } else {
                                                      if (kDebugMode) {
                                                        print(
                                                          '⚠️ MacIntel/Macintosh detected but maxTouchPoints=$maxTouchPoints (not iPad)',
                                                        );
                                                      }
                                                    }
                                                  }
                                                  // Also check for explicit iPad in user agent (case-insensitive)
                                                  if (userAgent.contains(
                                                    'ipad',
                                                  )) {
                                                    isLikelyIPad = true;
                                                    if (kDebugMode) {
                                                      print(
                                                        '✅ Explicit iPad detected in user agent',
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  if (kDebugMode) {
                                                    print(
                                                      '⚠️ No touch support detected',
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                if (kDebugMode) {
                                                  print(
                                                    '❌ Error in enhanced iPad detection: $e',
                                                  );
                                                }
                                              }
                                            }

                                            // If recheck shows it's iOS/iPad, use USDZ file with Apple Quick Look
                                            // Also check if it's a tablet with touch support (likely iPad)
                                            if (recheckIOS ||
                                                isLikelyIPad ||
                                                (recheckTablet &&
                                                    kIsWeb &&
                                                    DeviceDetectionService.hasTouchSupport())) {
                                              if (kDebugMode) {
                                                print(
                                                  'iPad detected on recheck! Using Apple AR Quick Look',
                                                );
                                              }
                                              // Use the USDZ file path - it should be in usdzFileUrl or glbFileUrl
                                              final usdzUrl =
                                                  _product.usdzFileUrl ??
                                                  (isGlbFileUsdz
                                                      ? glbFileUrl
                                                      : null);
                                              if (usdzUrl != null && mounted) {
                                                // Launch Apple AR Quick Look
                                                try {
                                                  if (_product.id != null) {
                                                    final analyticsService =
                                                        AnalyticsService();
                                                    await analyticsService
                                                        .trackARView(
                                                          _product.id!,
                                                        );
                                                  }

                                                  if (kIsWeb) {
                                                    final launched =
                                                        await web_utils
                                                            .WebUtils.openUsdzInAR(
                                                          usdzUrl,
                                                        );
                                                    if (!launched && mounted) {
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ARViewScreen(
                                                                product:
                                                                    _product,
                                                                modelUrl:
                                                                    usdzUrl,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  } else {
                                                    final uri = Uri.parse(
                                                      usdzUrl,
                                                    );
                                                    await launchUrl(
                                                      uri,
                                                      mode: LaunchMode
                                                          .externalApplication,
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (kDebugMode) {
                                                    print(
                                                      'Error launching AR on iPad: $e',
                                                    );
                                                  }
                                                }
                                              }
                                              return;
                                            }

                                            // Block only if confirmed non-iOS device (not iPad)
                                            // Don't show banner if we detected it might be an iPad
                                            if (mounted &&
                                                !isLikelyIPad &&
                                                !recheckIOS) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'USDZ format is only supported on Apple devices (iPhone/iPad). Please use an Apple device to view this AR model.',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFFED1F24,
                                                  ),
                                                  duration: Duration(
                                                    seconds: 5,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                            if (kDebugMode) {
                                              print(
                                                'BLOCKED: USDZ file detected on non-iOS device - AR not supported',
                                              );
                                              print(
                                                'hasUsdzFile: $hasUsdzFile',
                                              );
                                              print(
                                                'isGlbFileUsdz: $isGlbFileUsdz',
                                              );
                                              print('isUsdzFile: $isUsdzFile');
                                              print(
                                                'glbFileUrl: ${_product.glbFileUrl}',
                                              );
                                              print(
                                                'usdzFileUrl: ${_product.usdzFileUrl}',
                                              );
                                            }
                                            return;
                                          } else {
                                            // For GLB files on non-iOS devices, use Google Scene Viewer
                                            // This includes cases where:
                                            // - GLB file exists (even if usdzFileUrl also exists)
                                            // - No USDZ file is actually being used
                                            // Ensure we have a GLB file, not USDZ
                                            try {
                                              final directModelUrl =
                                                  _product.glbFileUrl ??
                                                  _product.modelUrl;

                                              // Double-check it's not a USDZ file
                                              if (_isUsdzFile(
                                                directModelUrl ?? '',
                                              )) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'USDZ format is only supported on Apple devices. This product needs a GLB file for AR on this device.',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor: Color(
                                                        0xFFED1F24,
                                                      ),
                                                      duration: Duration(
                                                        seconds: 5,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }

                                              if (directModelUrl == null ||
                                                  directModelUrl.isEmpty) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        '3D model file not available for this product.',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      backgroundColor: Color(
                                                        0xFFED1F24,
                                                      ),
                                                      duration: Duration(
                                                        seconds: 3,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return;
                                              }

                                              // For Google Scene Viewer, we need to properly encode the URL
                                              // The URL from database may already have encoded characters (%20)
                                              // To avoid double-encoding (%20 -> %2520), decode first then encode
                                              // This ensures proper single encoding for the query parameter
                                              String encodedModelUrl;
                                              try {
                                                // Decode the URL first to handle already-encoded characters
                                                final decodedUrl =
                                                    Uri.decodeComponent(
                                                      directModelUrl,
                                                    );
                                                // Then encode it properly for the query parameter
                                                encodedModelUrl =
                                                    Uri.encodeComponent(
                                                      decodedUrl,
                                                    );
                                              } catch (e) {
                                                // If decoding fails, encode as-is (fallback)
                                                encodedModelUrl =
                                                    Uri.encodeComponent(
                                                      directModelUrl,
                                                    );
                                              }

                                              // Use Google Scene Viewer URL format to directly open AR
                                              // This will trigger Scene Viewer directly without showing the cube first
                                              // Use the properly encoded URL
                                              final sceneViewerUrl =
                                                  'https://arvr.google.com/scene-viewer/1.0?file=$encodedModelUrl&mode=ar_only';

                                              if (kDebugMode) {
                                                print(
                                                  '=== Google Scene Viewer Debug ===',
                                                );
                                                print(
                                                  'Direct Model URL: $directModelUrl',
                                                );
                                                print(
                                                  'Encoded URL: $encodedModelUrl',
                                                );
                                                print(
                                                  'Scene Viewer URL: $sceneViewerUrl',
                                                );
                                                print(
                                                  'Note: URL is decoded then encoded to avoid double-encoding',
                                                );
                                                print(
                                                  '================================',
                                                );
                                              }

                                              // Track AR view before launching
                                              if (_product.id != null) {
                                                final analyticsService =
                                                    AnalyticsService();
                                                await analyticsService
                                                    .trackARView(_product.id!);
                                              }

                                              // Try to launch Scene Viewer directly
                                              final uri = Uri.parse(
                                                sceneViewerUrl,
                                              );
                                              final launched = await launchUrl(
                                                uri,
                                                mode: LaunchMode
                                                    .externalApplication,
                                              );

                                              if (!launched && mounted) {
                                                if (kDebugMode) {
                                                  print(
                                                    'Google Scene Viewer launch failed, trying fallback',
                                                  );
                                                }
                                                // Fallback: Navigate to AR view screen if direct launch fails
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ARViewScreen(
                                                          product: _product,
                                                          modelUrl:
                                                              directModelUrl,
                                                        ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (kDebugMode) {
                                                print(
                                                  'Error launching Google Scene Viewer: $e',
                                                );
                                              }
                                              // Fallback: Navigate to AR view screen on error
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error launching AR: ${e.toString()}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        const Color(0xFFED1F24),
                                                    duration: const Duration(
                                                      seconds: 3,
                                                    ),
                                                  ),
                                                );
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ARViewScreen(
                                                          product: _product,
                                                          modelUrl:
                                                              _product
                                                                  .glbFileUrl ??
                                                              _product
                                                                  .modelUrl ??
                                                              '',
                                                        ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        } catch (outerError) {
                                          // Catch any unhandled errors from the entire AR launch flow
                                          if (kDebugMode) {
                                            print(
                                              'Unexpected error in AR launch: $outerError',
                                            );
                                            print(
                                              'Stack trace: ${StackTrace.current}',
                                            );
                                          }
                                          if (mounted) {
                                            // Always try to open AR view screen as fallback
                                            final fallbackUrl =
                                                _product.glbFileUrl ??
                                                _product.usdzFileUrl ??
                                                _product.modelUrl ??
                                                '';
                                            if (fallbackUrl.isNotEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Opening AR view...',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFFED1F24,
                                                  ),
                                                  duration: Duration(
                                                    seconds: 1,
                                                  ),
                                                ),
                                              );
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ARViewScreen(
                                                        product: _product,
                                                        modelUrl: fallbackUrl,
                                                      ),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'No 3D model file available for this product.',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Color(
                                                    0xFFED1F24,
                                                  ),
                                                  duration: Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    : () {
                                        // Show message when clicked on desktop/web
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'AR is only available on mobile, tablet, and iPad devices. Please open this website on your mobile or tablet to experience AR.',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: Color(0xFFED1F24),
                                            duration: Duration(seconds: 5),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isARSupported
                                      ? const Color(0xFFDC2626)
                                      : Colors.grey[400],
                                  foregroundColor: Colors.white,
                                  padding: buttonPadding,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'View In My Space',
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
                                    Icon(Icons.view_in_ar, size: iconSize),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final uri = Uri.parse(
                                  'https://wa.me/916369869996',
                                );
                                if (!await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                )) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not open WhatsApp',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFED1F24),
                                side: const BorderSide(
                                  color: Color(0xFFDC2626),
                                  width: 1.5,
                                ),
                                padding: buttonPadding,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Enquire now',
                                      style: TextStyle(
                                        color: const Color(0xFFDC2626),
                                        fontSize: buttonFontSize,
                                        fontWeight: FontWeight.w600,
                                        height: 1.43,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 4 : 8),
                                  FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    size: iconSize,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: buttonSpacing),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final isMobile =
                                    DeviceDetectionService.isMobile(context);
                                final isTablet =
                                    DeviceDetectionService.isTablet(context);
                                final isIOS =
                                    DeviceDetectionService.isIOS(context) ||
                                    DeviceDetectionService.isProbablyIPad(
                                      context,
                                    );
                                final isARSupported =
                                    isMobile || isTablet || isIOS;

                                return ElevatedButton(
                                  onPressed: isARSupported
                                      ? () async {
                                          // Launch AR view - simplified for Row layout
                                          // Full logic is in the Column layout above
                                          final hasModel =
                                              _product.glbFileUrl != null &&
                                                  _product
                                                      .glbFileUrl!
                                                      .isNotEmpty ||
                                              _product.usdzFileUrl != null &&
                                                  _product
                                                      .usdzFileUrl!
                                                      .isNotEmpty ||
                                              _product.modelUrl != null &&
                                                  _product.modelUrl!.isNotEmpty;

                                          if (hasModel && mounted) {
                                            final modelUrl =
                                                _product.glbFileUrl ??
                                                _product.usdzFileUrl ??
                                                _product.modelUrl ??
                                                '';
                                            if (modelUrl.isNotEmpty) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ARViewScreen(
                                                        product: _product,
                                                        modelUrl: modelUrl,
                                                      ),
                                                ),
                                              );
                                            }
                                          } else if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'No 3D model file available for this product.',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor: Color(
                                                  0xFFED1F24,
                                                ),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      : () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'AR is only available on mobile, tablet, and iPad devices.',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Color(
                                                0xFFED1F24,
                                              ),
                                              duration: Duration(seconds: 5),
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isARSupported
                                        ? const Color(0xFFDC2626)
                                        : Colors.grey[400],
                                    foregroundColor: Colors.white,
                                    padding: buttonPadding,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'View In My Space',
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
                                      Icon(Icons.view_in_ar, size: iconSize),
                                    ],
                                  ),
                                );
                              },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Prevent Row overflow on medium/narrow widths (common on web)
        final isDesktop = ResponsiveHelper.isDesktop(context);
        final canShowTwoColumns = isDesktop && constraints.maxWidth >= 520;

        // Always left-align for all devices
        final crossAxisAlignment = CrossAxisAlignment.start;

        Widget featureItem(String text) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '• $text',
              softWrap: true,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF1A1B2D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.71,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Text(
              'Key Features',
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color(0xFF090919),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.75,
              ),
            ),
            const SizedBox(height: 12),
            if (canShowTwoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: features
                          .asMap()
                          .entries
                          .where((e) => e.key % 2 == 0)
                          .map((e) => featureItem(e.value))
                          .toList(),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: features
                          .asMap()
                          .entries
                          .where((e) => e.key % 2 == 1)
                          .map((e) => featureItem(e.value))
                          .toList(),
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: crossAxisAlignment,
                children: features.map(featureItem).toList(),
              ),
          ],
        );
      },
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
                  const SizedBox(
                    width: 48,
                  ), // Increased spacing between columns
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
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final horizontalPadding = _getHorizontalPadding(context);

    if (_isLoadingSimilar) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      );
    }

    if (_similarProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Similar Products',
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
              mobile: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
          // Similar Products Grid - 2-column (4-square) grid matching homepage
          LayoutBuilder(
            builder: (context, constraints) {
              // 2-column grid (4-square) for mobile only, more columns for tablet/desktop
              final crossAxisCount = isDesktop
                  ? 3 // 3 columns for desktop (like homepage)
                  : (isTablet
                        ? 3 // 3 columns for tablet (not 4-square)
                        : 2); // 2 columns (4-square grid) for mobile only

              // Use same aspect ratios as main product grid for consistency
              final childAspectRatio = isDesktop
                  ? 0.68 // Same as main product grid desktop
                  : (isTablet
                        ? 0.62 // Same as main product grid tablet
                        : 0.58); // Same as main product grid mobile

              // Use same spacing as main product grid
              final crossAxisSpacing = ResponsiveHelper.getResponsiveSpacing(
                context,
                mobile: 16.0,
                tablet: 24.0,
                desktop: 32.0,
              );

              final mainAxisSpacing = ResponsiveHelper.getResponsiveSpacing(
                context,
                mobile: 16.0,
                tablet: 24.0,
                desktop: 32.0,
              );

              // Use same padding as main product grid
              final gridPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: crossAxisSpacing,
                  mainAxisSpacing: mainAxisSpacing,
                ),
                padding: EdgeInsets.all(gridPadding),
                itemCount: _similarProducts.length,
                itemBuilder: (context, index) {
                  final product = _similarProducts[index];
                  return ProductCard(product: product);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// Format product details as structured text for sharing
  String _formatProductDetailsForSharing() {
    final StringBuffer buffer = StringBuffer();

    // Product name with emoji
    buffer.writeln('🏷️ Product: ${_product.name}');

    // Category if available
    if (_product.category.isNotEmpty) {
      buffer.writeln('📂 Category: ${_product.category}');
    }

    // Description if available
    if (_product.description != null && _product.description!.isNotEmpty) {
      buffer.writeln('📝 Description: ${_product.description}');
    }

    // Technical specs if available
    if (_product.defaultTechnicalSpecs.isNotEmpty) {
      buffer.writeln('\n⚙️ Technical Specifications:');
      _product.defaultTechnicalSpecs.forEach((key, value) {
        buffer.writeln('• $key: $value');
      });
    }

    // Key features if available
    if (_product.defaultKeyFeatures.isNotEmpty) {
      buffer.writeln('\n✨ Key Features:');
      for (final feature in _product.defaultKeyFeatures) {
        buffer.writeln('• $feature');
      }
    }

    // Add branding
    buffer.writeln('\n🔗 From RedWolf Media - Creative Visibility');

    return buffer.toString();
  }
}
