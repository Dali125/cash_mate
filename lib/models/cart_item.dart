class CartItem {
  final String? name;
  final double? price;
  final int? stock;
  int?
      quantity; // Make quantity mutable if needed for direct updates, or use copyWith

  CartItem({
    required this.name,
    required this.price,
    required this.stock,
    this.quantity = 1, // Default quantity
  });

  @override
  String toString() {
    return 'CartItem(name: $name, price: $price, quantity: $quantity, stock: $stock)';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'stock': stock,
    };
  }

  // Add copyWith method here if not using extension
  CartItem copyWith({
    String? name,
    double? price,
    int? quantity,
    int? stock,
  }) {
    return CartItem(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
    );
  }
}
