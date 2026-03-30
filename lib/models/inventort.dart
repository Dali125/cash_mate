import 'package:hive/hive.dart';

part 'inventort.g.dart'; // Required for Hive's type adapter generation

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  double discount;

  @HiveField(5)
  String imageUrl;

  Item({
    this.id = 0,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.discount = 0.0,
  });

  /// Convert Item object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'discount': discount,
      'image_url': imageUrl,
    };
  }

  /// Create an Item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      discount: json['discount']?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] ?? '',
    );
  }
}
