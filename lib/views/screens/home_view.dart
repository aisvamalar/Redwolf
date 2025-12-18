import 'package:flutter/material.dart';
import '../widgets/header_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/footer_widget.dart';
import '../../services/device_detection_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _productsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProducts() {
    final context = _productsKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  double _getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Reduced padding for more usable width
    if (width > 1200) return 24; // Reduced padding for desktop
    if (width > 800) return 24; // Reduced padding for tablet
    return 16; // Reduced padding for mobile
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = _getHorizontalPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 1200 ? 1200.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
          child: Container(
            width: maxWidth,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Color(0xFFE5E5E5)),
                    ),
                  ),
                  child: const HeaderWidget(),
                ),
                // Hero Section
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: 64, // Spacing from header
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth > 1200 ? 1000.0 : double.infinity,
                      ),
                      child: HeroSection(onExplorePressed: _scrollToProducts),
                    ),
                  ),
                ),
                // Products Title
                Padding(
                  padding: EdgeInsets.only(top: DeviceDetectionService.isMobile(context) ? 48 : 64),
                  child: Center(
                    child: Text(
                      'Explore Our Products',
                      key: _productsKey,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: DeviceDetectionService.isMobile(context) ? 22 : 26,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.23,
                      ),
                    ),
                  ),
                ),
                // Search and Filter Bar
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth > 1200 ? 1000.0 : double.infinity,
                      ),
                      child: const SearchFilterBar(),
                    ),
                  ),
                ),
                // Product Grid
                Padding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    top: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth > 1200 ? 1000.0 : double.infinity,
                      ),
                      child: const ProductGrid(),
                    ),
                  ),
                ),
                // Footer
                const Padding(
                  padding: EdgeInsets.only(top: 64, bottom: 32),
                  child: Center(child: FooterWidget()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
