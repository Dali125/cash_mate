class InventoryModel {
  final String name;
  final double price;
  final int quantity;

  InventoryModel(
      {required this.name, required this.price, required this.quantity});

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };
}
