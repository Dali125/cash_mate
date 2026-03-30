import 'package:cash_app/models/cart_item.dart';
import 'package:get/get.dart';

class CartController extends GetxController {
  var cart = <CartItem>[].obs;
  var total = 0.0.obs;

  void _calculateTotal() {
    total.value = cart.fold(
        0.0, (sum, item) => sum + ((item.price ?? 0.0) * (item.quantity ?? 0)));
  }

  void addToCart(Map<dynamic, dynamic> itemData, int stock) {
    final itemName = itemData["name"] as String?;
    final itemDiscount = (itemData["discount"] as num?)?.toDouble() ?? 0.0;
    double? itemPrice = (itemData["price"] as num?)?.toDouble();


    if (itemName == null || itemPrice == null) {
      Get.snackbar('Error', 'Error adding item: Missing details.');
      return;
    }
    if (itemDiscount > 0){
      itemPrice = itemPrice * (1 - itemDiscount / 100);
    }

    int index = cart.indexWhere((item) => item.name == itemName);
    if (index != -1) {
      CartItem existingItem = cart[index];
      if (existingItem.quantity! < (itemData['quantity'] ?? double.infinity)) {
        cart[index] =
            existingItem.copyWith(quantity: (existingItem.quantity ?? 0) + 1);
      }
    } else if (itemData['quantity'] < 1) {
      Get.snackbar('Error', 'Item is out of stock.');
    } else {
      cart.add(CartItem(
          name: itemName, price: itemPrice, quantity: 1, stock: stock));
    }
    _calculateTotal();
  }

  void incrementQuantity(int index) {
    // Check if the current quantity in the cart is less than the available stock
    if ((cart[index].quantity ?? 0) < (cart[index].stock ?? 0)) {
      cart[index] =
          cart[index].copyWith(quantity: (cart[index].quantity ?? 0) + 1);
    } else {
      // Show an error or notification that stock limit is reached
      Get.snackbar(
          'Error', 'Cannot exceed stock quantity or Stock is unavailable');
    }
    _calculateTotal();
  }

  void decrementQuantity(int index, int currentQuantity) {
    if (currentQuantity > 1) {
      cart[index] = cart[index].copyWith(quantity: currentQuantity - 1);
    } else {
      cart.removeAt(index);
    }
    _calculateTotal();
  }

  void removeFromCart(int index) {
    cart.removeAt(index);
    _calculateTotal();
  }

  void clearCart() {
    cart.clear();
    _calculateTotal();
  }
}
