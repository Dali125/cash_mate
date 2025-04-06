import 'package:hive/hive.dart';

part 'inventort.g.dart'; // Required for Hive's type adapter generation

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double price;

  @HiveField(2)
  int quantity;

  @HiveField(4)
  String imageUrl;

  Item({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  /// Convert Item object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }

  /// Create an Item from JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      quantity: json['quantity'] ?? 0,
      imageUrl: json['image_url'] ?? '',
    );
  }
}
