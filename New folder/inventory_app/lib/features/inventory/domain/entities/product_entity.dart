class ProductEntity {
  final int? id;
  final String name;
  final String category;
  final int quantity;
  final double price;

  ProductEntity({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.price,
  });

  ProductEntity copyWith({
    int? id,
    String? name,
    String? category,
    int? quantity,
    double? price,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
