import 'package:flutter/material.dart';
import '../widgets/header_widget.dart';
import '../widgets/hero_section.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/product_grid.dart';
import '../widgets/footer_widget.dart';
import '../../utils/responsive_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getHorizontalPadding(context);
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Section
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 16,
                              ),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(width: 1, color: Color(0xFFE5E5E5)),
                                ),
                              ),
                              child: const HeaderWidget(),
                            ),
                            // Hero Section - Hidden on mobile
                            // Products Title
                            Padding(
                              padding: const EdgeInsets.only(top: 32),
                              child: Center(
                                child: Text(
                                  'Explore Our Products',
                                  key: _productsKey,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      mobile: 22,
                                      tablet: 24,
                                      desktop: 26,
                                    ),
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
                                top: 20,
                              ),
                              child: const SearchFilterBar(),
                            ),
                            // Product Grid - no horizontal padding on mobile (handled by grid itself)
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: const ProductGrid(),
                            ),
                          ],
                        ),
                        // Footer
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 48,
                            bottom: 24,
                          ),
                          child: const Center(child: FooterWidget()),
                        ),
                      ],
                    )
                    : Center(
                        child: Container(
                          width: maxWidth,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(color: Colors.white),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header Section
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding,
                                      vertical: isTablet ? 20 : 24,
                                    ),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(width: 1, color: Color(0xFFE5E5E5)),
                                      ),
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: maxWidth),
                                        child: const HeaderWidget(),
                                      ),
                                    ),
                                  ),
                                  // Hero Section
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: horizontalPadding,
                                      right: horizontalPadding,
                                      top: isTablet ? 48 : 64,
                                    ),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(maxWidth: maxWidth),
                                        child: HeroSection(onExplorePressed: _scrollToProducts),
                                      ),
                                    ),
                                  ),
                                  // Products Title
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: isTablet ? 48 : 64,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Explore Our Products',
                                        key: _productsKey,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                                            context,
                                            mobile: 22,
                                            tablet: 24,
                                            desktop: 26,
                                          ),
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
                                        constraints: BoxConstraints(maxWidth: maxWidth),
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
                                        constraints: BoxConstraints(maxWidth: maxWidth),
                                        child: const ProductGrid(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Footer
                              Padding(
                                padding: EdgeInsets.only(
                                  top: isTablet ? 56 : 64,
                                  bottom: 32,
                                ),
                                child: const Center(child: FooterWidget()),
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
          );
        },
      ),
    );
  }
}
