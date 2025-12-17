import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/product_controller.dart';
import '../../models/category.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ProductController>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return isWeb
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 25,
            children: [
              Container(
                width: 430,
                child: _buildSearchField(context, controller),
              ),
              Container(
                width: 240,
                child: _buildCategoryDropdown(context, controller),
              ),
              Container(
                width: 240,
                child: _buildSortDropdown(context, controller),
              ),
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
    final categories = Category.getDefaultCategories();

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
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'category: ',
                            style: TextStyle(
                              color: Color(0xFF8C8D96),
                              fontSize: 14,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                          ),
                          TextSpan(
                            text: category.id == 'all' ? 'All' : category.name,
                            style: const TextStyle(
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
                  );
                }).toList(),
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
}
