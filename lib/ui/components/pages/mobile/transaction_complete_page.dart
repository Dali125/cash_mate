import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/controllers/payment_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionCompletePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    PaymentController pc = Get.find<PaymentController>();
    Config db = Get.find<Config>();
    CartController cartController = Get.find<CartController>();
    InventoryController inventoryController = Get.find<InventoryController>();

    final args = Get.arguments;
    print(args["amount paid"]);
    SalesModel items = SalesModel(
        date: args["sales"].date,
        total: args["sales"].total,
        itemsSold: args["sales"].itemsSold,
        transactionType: args["transaction_type"]);
    List<CartItem>? itemsSold = items.itemsSold;
    print(items.total);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text("Reciept"),
              LimitedBox(
                maxHeight: DeviceProperties().getHeight(context) / 1.6,
                child: ListView.builder(
                    itemCount: itemsSold?.length,
                    itemBuilder: (context, index) {
                      int total = itemsSold![index].price!.toInt() *
                          (itemsSold[index].quantity as int);
                      return ListTile(
                        title: Text(
                            "${itemsSold[index].name as String} x ${itemsSold[index].quantity}"),
                        trailing: Text(
                          "K $total",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      );
                    }),
              ),
              ListTile(
                title: Text("Total"),
                trailing: Text(
                  "K ${items.total?.roundToDouble().toString()}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              ListTile(
                title: Text("Amount Paid"),
                trailing: Text(
                  "K ${args["amount paid"]}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              ListTile(
                title: Text("Change"),
                trailing: Text(
                  "K ${pc.calculateChange(items.total as double, double.parse(args["amount paid"]))}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Button(
                  width: DeviceProperties().getWidth(context),
                  height: 50,
                  color: bluePrimary,
                  text: "Record Purchase",
                  onPressed: () async {
                    // Await the sale to ensure inventory is updated
                    await db.addSale(items);

                    // Refresh inventory to reflect stock changes
                    await inventoryController.fetchInventory();

                    // Clear the cart after recording the sale
                    cartController.clearCart();

                    Get.snackbar("Success", "Purchase recorded successfully",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: Duration(seconds: 2),
                        snackPosition: SnackPosition.BOTTOM);
                    Get.offAllNamed("/");
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
