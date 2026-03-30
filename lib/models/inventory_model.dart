class InventoryModel {
  final String name;
  final double price;
  final int quantity;
  final double discount;

  InventoryModel(
      {required this.name, required this.price, required this.quantity, this.discount = 0.0});

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
        'discount': discount,
      };
}
