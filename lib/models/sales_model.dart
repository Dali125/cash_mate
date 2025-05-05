import 'package:cash_app/models/cart_item.dart';
import 'package:hive/hive.dart';

part 'sales_model.g.dart';

@HiveType(typeId: 0)
class SalesModel extends HiveObject {
  @HiveField(0)
  String? date;

  @HiveField(1)
  double? total;

  @HiveField(2)
  List<CartItem>? itemsSold;

  @HiveField(3)
  String? transactionType;

  SalesModel({
    this.date,
    this.total,
    this.itemsSold,
    this.transactionType,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'total': total,
      'itemsSold': itemsSold,
      'transactionType': transactionType,
    };
  }

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    return SalesModel(
      date: json['date'],
      total: json['total'],
      itemsSold: json['itemsSold'],
      transactionType: json['transactionType'],
    );
  }
}
