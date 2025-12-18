import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProductController>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return isWeb
        ? Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 16,
            children: [
              // Search takes remaining space
              Expanded(flex: 3, child: _buildSearchField(context, controller)),
              // Category and sort share space
              Expanded(
                flex: 2,
                child: _buildCategoryDropdown(context, controller),
              ),
              Expanded(flex: 2, child: _buildSortDropdown(context, controller)),
              // Compact layout toggle button
              _buildLayoutToggleButton(controller),
            ],
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildSearchField(context, controller),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryDropdown(context, controller),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSortDropdown(context, controller)),
                    const SizedBox(width: 12),
                    _buildLayoutToggleButton(controller),
                  ],
                ),
              ],
            ),
          );
  }

  Widget _buildSearchField(BuildContext context, ProductController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        spacing: 12,
        children: [
          Container(
            width: 20,
            height: 20,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: const Icon(Icons.search, size: 20, color: Color(0xFF8C8D96)),
          ),
          Expanded(
            child: TextField(
              onChanged: (value) => controller.setSearchQuery(value),
              decoration: const InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: Color(0xFF8C8D96),
                  fontSize: 14,
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
    final textStyleValue = const TextStyle(
      color: Color(0xFF2C2C34),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.43,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        spacing: 12,
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedCategory,
                isExpanded: true,
                items: [
                  DropdownMenuItem<String>(
                    value: 'all',
                    child: Text('All', style: textStyleValue),
                  ),
                  ...products.map(
                    (product) => DropdownMenuItem<String>(
                      value: product.id,
                      child: Text(product.name, style: textStyleValue),
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
          Container(
            width: 20,
            height: 20,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF8C8D96),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        spacing: 12,
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SortOption>(
                value: controller.sortOption,
                isExpanded: true,
                items: const [
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
                  ),
                  DropdownMenuItem(
                    value: SortOption.nameDesc,
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
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.setSortOption(value);
                  }
                },
              ),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(),
            child: const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF8C8D96),
            ),
          ),
        ],
      ),
    );
  }

  /// Small pill button that toggles between list (single column)
  /// and grid (two-column) layouts.
  Widget _buildLayoutToggleButton(ProductController controller) {
    final isGrid = controller.layout == ProductLayout.grid2;

    return Container(
      width: 44,
      height: 44,
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
          size: 20,
          color: const Color(0xFF2C2C34),
        ),
      ),
    );
  }
}
