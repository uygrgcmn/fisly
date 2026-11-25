class Category {
  const Category({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
}
