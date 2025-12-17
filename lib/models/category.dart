class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  static List<Category> getDefaultCategories() {
    return [
      Category(id: 'all', name: 'All'),
      Category(id: 'standees', name: 'Standees'),
      Category(id: 'electronics', name: 'Electronics'),
      Category(id: 'food', name: 'Food & Beverages'),
      Category(id: 'clothing', name: 'Clothing'),
      Category(id: 'home', name: 'Home & Living'),
    ];
  }
}
