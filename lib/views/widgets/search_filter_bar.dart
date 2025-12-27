import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../utils/responsive_helper.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProductController>(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    if (isDesktop) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search takes remaining space
          Expanded(flex: 3, child: _buildSearchField(context, controller)),
          const SizedBox(width: 16),
          // Category and sort share space
          Expanded(flex: 2, child: _buildCategoryDropdown(context, controller)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildSortDropdown(context, controller)),
          // Grid toggle button removed for desktop/web
        ],
      );
    } else if (isTablet) {
      // Tablet: 2 rows
      return Column(
        children: [
          _buildSearchField(context, controller),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildCategoryDropdown(context, controller)),
              const SizedBox(width: 12),
              Expanded(child: _buildSortDropdown(context, controller)),
              // Grid toggle button removed for tablet/web
            ],
          ),
        ],
      );
    } else {
      // Mobile: Stacked vertically with better spacing
      // Grid toggle button removed - always use 4-square grid
      return Column(
        children: [
          _buildSearchField(context, controller),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildCategoryDropdown(context, controller)),
              const SizedBox(width: 12),
              Expanded(child: _buildSortDropdown(context, controller)),
              // Grid toggle button removed
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSearchField(BuildContext context, ProductController controller) {
    final isMobile = ResponsiveHelper.isMobile(context);
    // Use exact same height as filter dropdowns for uniform appearance
    final height = isMobile ? 40.0 : 44.0;

    return Container(
      height: height, // Exact height matching filter dropdowns
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 0,
      ),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(82)),
        shadows: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 40,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isMobile ? 18 : 20,
            height: isMobile ? 18 : 20,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Icon(
              Icons.search,
              size: isMobile ? 18 : 20,
              color: const Color(0xFF8C8D96),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (value) => controller.setSearchQuery(value),
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.43,
              ),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: const Color(0xFF8C8D96),
                  fontSize: isMobile ? 13 : 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true, // Reduce internal padding to match height
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(
    BuildContext context,
    ProductController controller,
  ) {
    // Extract unique categories from all products
    final allProducts = controller.allProducts;
    final uniqueCategories =
        allProducts
            .map((p) => p.category.isNotEmpty ? p.category : 'Portable')
            .toSet()
            .toList()
          ..sort();

    final isMobile = ResponsiveHelper.isMobile(context);
    final textStyleValue = TextStyle(
      color: const Color(0xFF2C2C34),
      fontSize: isMobile ? 13 : 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.43,
    );

    return Container(
      height: isMobile ? 40 : 44,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: 0,
      ),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadows: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 40,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedCategory,
          isExpanded: true,
          style: textStyleValue,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: isMobile ? 18 : 20,
            color: const Color(0xFF8C8D96),
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'all',
              child: Text(
                'All',
                style: textStyleValue,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...uniqueCategories.map(
              (category) => DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: textStyleValue,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          selectedItemBuilder: (context) {
            final items = <String>['all', ...uniqueCategories];
            return items.map((category) {
              final displayName = category == 'all' ? 'All' : category;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  displayName,
                  style: textStyleValue,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList();
          },
          onChanged: (value) {
            if (value != null) {
              controller.setCategory(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSortDropdown(
    BuildContext context,
    ProductController controller,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);

    // Use consistent text style matching the category dropdown
    final sortTextStyle = TextStyle(
      color: const Color(0xFF2C2C34),
      fontSize: isMobile ? 13 : 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.43,
    );

    return Container(
      height: isMobile ? 40 : 44,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 20,
        vertical: 0,
      ),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadows: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 40,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: controller.sortOption,
          isExpanded: true,
          style: sortTextStyle,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: isMobile ? 18 : 20,
            color: const Color(0xFF8C8D96),
          ),
          items: [
            // All devices: Simple labels without "sort by:" prefix
            DropdownMenuItem(
              value: SortOption.defaultSort,
              child: Text(
                'Default',
                style: sortTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: SortOption.nameAsc,
              child: Text(
                isMobile ? 'A-Z' : 'Name (A-Z)',
                style: sortTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: SortOption.nameDesc,
              child: Text(
                isMobile ? 'Z-A' : 'Name (Z-A)',
                style: sortTextStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          selectedItemBuilder: (context) {
            // All devices: Simple labels without "sort by:" prefix
            return [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Default',
                  style: sortTextStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isMobile ? 'A-Z' : 'Name (A-Z)',
                  style: sortTextStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isMobile ? 'Z-A' : 'Name (Z-A)',
                  style: sortTextStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ];
          },
          onChanged: (value) {
            if (value != null) {
              controller.setSortOption(value);
            }
          },
        ),
      ),
    );
  }
}
