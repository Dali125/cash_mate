import 'dart:io';

import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesPageTablet extends StatefulWidget {
  const SalesPageTablet({super.key});

  @override
  State<SalesPageTablet> createState() => _SalesPageTabletState();
}

class _SalesPageTabletState extends State<SalesPageTablet> {
  final CartController cartController = Get.put(CartController());
  final db = Get.find<Config>();
  final deviceProperties = DeviceProperties();
  final _searchController = TextEditingController();
  List<int> stockQuantities = [];

  @override
  Widget build(BuildContext context) {
    final bool isTablet = deviceProperties.isTablet(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current Sale',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bluePrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 10),
        child: Column(
          children: [
            SearchBar(
              elevation: WidgetStateProperty.all(2),
              backgroundColor: WidgetStateProperty.all(onBluePrimary),
              leading: const Icon(Icons.search, color: Colors.blueGrey),
              hintText: 'Search inventory',
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchController.text = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder(
                future: db.getInventory(searchQuery: _searchController.text),
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
                      crossAxisCount: isTablet ? 3 : 2,
                      childAspectRatio: isTablet ? 0.9 : 0.8,
                      crossAxisSpacing: isTablet ? 20 : 10,
                      mainAxisSpacing: isTablet ? 20 : 10,
                    ),
                    itemCount: inventoryItems.length,
                    itemBuilder: (context, index) {
                      final itemData = inventoryItems[index];
                      final stockQuantity =
                          (itemData['quantity'] as num?)?.toInt();
                      stockQuantities.add(stockQuantity ?? 0);
                      final itemName = itemData['name'] as String?;
                      final itemPrice = (itemData['price'] as num?)?.toDouble();

                      return InkWell(
                        onTap: () => cartController.addToCart(
                            itemData, stockQuantities[index]),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Card(
                              elevation: 4,
                              shadowColor: bluePrimary,
                              color:
                                  ColorScheme.fromSeed(seedColor: bluePrimary)
                                      .surfaceContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(itemData['image_url'] ?? ''),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image,
                                                  size: 50),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      itemName ?? 'Unnamed Item',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                        "K ${itemPrice?.toStringAsFixed(2) ?? 'N/A'}"),
                                  ],
                                ),
                              ),
                            ),
                            if (itemData['quantity'] < 1)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: const Center(
                                    child: Text(
                                      'Out Of Stock',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.7,
              builder: (context, controller) {
                return Material(
                  elevation: 10,
                  shadowColor: bluePrimary,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 15 : 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Obx(
                      () => ListView.builder(
                        controller: controller,
                        itemCount: cartController.cart.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 20 : 10),
                            title: Text(
                                cartController.cart[index].name.toString()),
                            subtitle:
                                Text("K ${cartController.cart[index].price}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    cartController.decrementQuantity(
                                        index,
                                        cartController.cart[index].quantity
                                            as int);
                                  },
                                ),
                                Text(cartController.cart[index].quantity
                                    .toString()),
                                IconButton(
                                  icon: const Icon(Icons.add),
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
            const SizedBox(height: 20),
            Container(
              width: deviceProperties.getWidth(context),
              padding: EdgeInsets.all(isTablet ? 20 : 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total: K ${cartController.total}',
                      style: TextStyle(
                          fontSize: isTablet ? 32 : 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Button(
                      width: deviceProperties.getWidth(context) * 0.8,
                      height: isTablet ? 60 : 50,
                      color: bluePrimary,
                      text: 'Confirm Transaction',
                      onPressed: () async {
                        SalesModel item = SalesModel(
                          date: DateTime.now().toString(),
                          total: cartController.total.value,
                          itemsSold: cartController.cart,
                        );
                        await db.addSale(item);
                        Get.snackbar('Success', 'Inventory added successfully');
                        Get.back();
                        cartController.clearCart();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
