import 'dart:io';

import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/ui/components/button.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/cart_controller.dart';
import '../../../services/device_properties.dart';
import '../../../utils/color.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final CartController cartController = Get.put(CartController());

  final db = Get.find<Config>();

  final deviceProperties = DeviceProperties();

  final _searchController = TextEditingController();
  List<int> stockQuantities = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Sale',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bluePrimary,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 10),
                SearchBar(
                  elevation: WidgetStateProperty.all(2),
                  backgroundColor: WidgetStateProperty.all(onBluePrimary),
                  leading: Icon(Icons.search, color: Colors.blueGrey),
                  hintText: 'Search inventory',
                  controller: _searchController,
                  onChanged: (value) {
                    // Handle search logic here
                    setState(() {
                      _searchController.text = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder(
                    future:
                        db.getInventory(searchQuery: _searchController.text),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No inventory data available.'));
                      }

                      final inventoryItems = snapshot.data!;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              deviceProperties.isTablet(context) ? 4 : 2,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: inventoryItems.length,
                        itemBuilder: (context, index) {
                          final itemData = inventoryItems[index];
                          final stockQuantity =
                              (itemData['quantity'] as num?)?.toInt();
                          stockQuantities.add(stockQuantity ?? 0);
                          final itemName = itemData['name'] as String?;

                          final itemPrice =
                              (itemData['price'] as num?)?.toDouble();
                          return InkWell(
                            onTap: () => cartController.addToCart(
                                itemData, stockQuantities[index]),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Card(
                                  elevation: 2,
                                  shadowColor: bluePrimary,
                                  color: ColorScheme.fromSeed(
                                          seedColor: bluePrimary)
                                      .surfaceContainer,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image.file(
                                          File(itemData['image_url'] ?? ''),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image,
                                                  size: 50),
                                        ),
                                      ),
                                      Text(itemName ?? 'Unnamed Item',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          "K ${itemPrice?.toStringAsFixed(2) ?? 'N/A'}"),
                                    ],
                                  ),
                                ),
                                itemData['quantity'] < 1
                                    ? Center(
                                        child: Positioned(
                                          left: 1,
                                          top: 1,
                                          child: Transform.rotate(
                                            angle: 1,
                                            child: Text('Out Of Stock',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 30,
                                                )),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            child: DraggableScrollableSheet(
              builder: (context, controller) {
                return Material(
                  elevation: 20,
                  shadowColor: bluePrimary,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Obx(
                      () => ListView.builder(
                        controller: controller,
                        itemCount: cartController.cart.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                                cartController.cart[index].name.toString()),
                            subtitle:
                                Text("K ${cartController.cart[index].price}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      cartController.decrementQuantity(
                                          index,
                                          cartController.cart[index].quantity
                                              as int);
                                      print(stockQuantities[index]);
                                    }),
                                Text(cartController.cart[index].quantity
                                    .toString()),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () =>
                                      cartController.incrementQuantity(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: deviceProperties.getWidth(context),
              height: 100,
              color: Colors.white,
              child: Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Total: K ${cartController.total}',
                        style: TextStyle(fontSize: 28)),
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                      child: Button(
                        width: deviceProperties.getWidth(context),
                        height: 50,
                        color: bluePrimary,
                        text: 'Confirm Transaction',
                        onPressed: () async {
                          SalesModel item = SalesModel(
                            date: DateTime.now().toString(),
                            total: cartController.total.value,
                            itemsSold: cartController.cart,
                          );
                          // await db.addSale(item);
                          // Get.snackbar(
                          //     'Success', 'Inventory added successfully',
                          //     backgroundColor: Colors.green,
                          //     colorText: Colors.white);

                          // cartController.clearCart();
                          Get.toNamed('/payment_page', arguments: item);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
