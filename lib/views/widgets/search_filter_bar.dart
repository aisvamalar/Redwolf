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
          const SizedBox(width: 16),
          // Compact layout toggle button
          _buildLayoutToggleButton(context, controller),
        ],
      );
    } else if (isTablet) {
      // Tablet: 2 rows
      return Column(
        children: [
          _buildSearchField(context, controller),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCategoryDropdown(context, controller)),
              const SizedBox(width: 12),
              Expanded(child: _buildSortDropdown(context, controller)),
              const SizedBox(width: 12),
              _buildLayoutToggleButton(context, controller),
            ],
          ),
        ],
      );
    } else {
      // Mobile: Stacked vertically with better spacing
      return Column(
        children: [
          _buildSearchField(context, controller),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildCategoryDropdown(context, controller),
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _buildSortDropdown(context, controller)),
              const SizedBox(width: 8),
              _buildLayoutToggleButton(context, controller),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildSearchField(BuildContext context, ProductController controller) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 10 : 12,
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
    // Build options from actual products so the list shows
    // "Easel Standee", "Totem Standee", etc. instead of generic categories.
    final products = controller.products;
    final isMobile = ResponsiveHelper.isMobile(context);
    final textStyleValue = TextStyle(
      color: const Color(0xFF2C2C34),
      fontSize: isMobile ? 13 : 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.43,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 10 : 12,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedCategory,
                isExpanded: true,
                style: textStyleValue,
                items: [
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Text(
                      'All',
                      style: textStyleValue,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...products.map(
                    (product) => DropdownMenuItem<String>(
                      value: product.id,
                      child: Text(
                        product.name,
                        style: textStyleValue,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                selectedItemBuilder: (context) {
                  final items = <String>['all', ...products.map((p) => p.id)];
                  return items.map((id) {
                    final name = id == 'all'
                        ? 'All'
                        : products.firstWhere((p) => p.id == id).name;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
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
          ),
          SizedBox(width: isMobile ? 4 : 12),
          Container(
            width: isMobile ? 16 : 20,
            height: isMobile ? 16 : 20,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: isMobile ? 16 : 20,
              color: const Color(0xFF8C8D96),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(
    BuildContext context,
    ProductController controller,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);

    // On mobile, show shorter text without "sort by:" prefix
    final sortTextStyle = TextStyle(
      color: const Color(0xFF2C2C34),
      fontSize: isMobile ? 12 : 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.43,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 10 : 12,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                value: controller.sortOption,
                isExpanded: true,
                style: sortTextStyle,
                items: isMobile
                    ? [
                        // Mobile: Short labels
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
                            'A-Z',
                            style: sortTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: SortOption.nameDesc,
                          child: Text(
                            'Z-A',
                            style: sortTextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    : [
                        // Desktop/Tablet: Full labels with "sort by:"
                        DropdownMenuItem(
                          value: SortOption.defaultSort,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'sort by: ',
                                  style: TextStyle(
                                    color: Color(0xFF8C8D96),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Default',
                                  style: TextStyle(
                                    color: Color(0xFF2C2C34),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: SortOption.nameAsc,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'sort by: ',
                                  style: TextStyle(
                                    color: const Color(0xFF8C8D96),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Name (A-Z)',
                                  style: TextStyle(
                                    color: const Color(0xFF2C2C34),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: SortOption.nameDesc,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'sort by: ',
                                  style: TextStyle(
                                    color: const Color(0xFF8C8D96),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Name (Z-A)',
                                  style: TextStyle(
                                    color: const Color(0xFF2C2C34),
                                    fontSize: 14,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.43,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                selectedItemBuilder: (context) {
                  if (isMobile) {
                    // Mobile: Show short labels
                    return [
                      Text(
                        'Default',
                        style: sortTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'A-Z',
                        style: sortTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Z-A',
                        style: sortTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ];
                  } else {
                    // Desktop/Tablet: Show full labels
                    return [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'sort by: ',
                              style: TextStyle(
                                color: Color(0xFF8C8D96),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                            TextSpan(
                              text: 'Default',
                              style: TextStyle(
                                color: Color(0xFF2C2C34),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'sort by: ',
                              style: TextStyle(
                                color: Color(0xFF8C8D96),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                            TextSpan(
                              text: 'Name (A-Z)',
                              style: TextStyle(
                                color: Color(0xFF2C2C34),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'sort by: ',
                              style: TextStyle(
                                color: Color(0xFF8C8D96),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                            TextSpan(
                              text: 'Name (Z-A)',
                              style: TextStyle(
                                color: Color(0xFF2C2C34),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }
                },
                onChanged: (value) {
                  if (value != null) {
                    controller.setSortOption(value);
                  }
                },
              ),
            ),
          ),
          SizedBox(width: isMobile ? 4 : 12),
          Container(
            width: isMobile ? 16 : 20,
            height: isMobile ? 16 : 20,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: isMobile ? 16 : 20,
              color: const Color(0xFF8C8D96),
            ),
          ),
        ],
      ),
    );
  }

  /// Small pill button that toggles between list (single column)
  /// and grid (two-column) layouts.
  Widget _buildLayoutToggleButton(
    BuildContext context,
    ProductController controller,
  ) {
    final isGrid = controller.layout == ProductLayout.grid2;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      width: isMobile ? 40 : 44,
      height: isMobile ? 40 : 44,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        shadows: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 40,
            offset: Offset(0, 0),
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: controller.toggleLayout,
        child: Icon(
          isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
          size: isMobile ? 18 : 20,
          color: const Color(0xFF2C2C34),
        ),
      ),
    );
  }
}
