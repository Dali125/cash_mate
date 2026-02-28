class CartItem {
  final int? id;
  final String? name;
  final double? price;
  final int? stock;
  int?
      quantity; // Make quantity mutable if needed for direct updates, or use copyWith

  CartItem({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.quantity = 1, // Default quantity
  });

  @override
  String toString() {
    return 'CartItem(id: $id, name: $name, price: $price, quantity: $quantity, stock: $stock)';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'stock': stock,
    };
  }

  // Add copyWith method here if not using extension
  CartItem copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    int? stock,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
    );
  }
}
