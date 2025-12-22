class AdminCategory {
  final String id;
  final String name;

  AdminCategory({
    required this.id,
    required this.name,
  });

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  AdminCategory copyWith({
    String? id,
    String? name,
  }) {
    return AdminCategory(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}



