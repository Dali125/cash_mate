import 'dart:io';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final inventoryDB = Get.find<Config>();
    inventoryDB.initDatabase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: TextStyle(
              fontSize: 30, color: bluePrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 60,
                child: SearchBar(
                  elevation: MaterialStateProperty.all(2),
                  backgroundColor: MaterialStateProperty.all(onBluePrimary),
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
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              height: DeviceProperties().getHeight(context),
              width: DeviceProperties().getWidth(context),
              child: FutureBuilder<List<Map<String, dynamic>>?>(
                future: inventoryDB.getInventory(
                    searchQuery: _searchController.text),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<Map<String, dynamic>>? data = snapshot.data;
                  if (data == null || data.isEmpty) {
                    return const Center(
                        child: Text('No inventory data available.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final itemData = data[index];
                      final imagePath =
                          itemData['image_url'] ?? ''; // Ensure null safety

                      return InkWell(
                        onTap: () {
                          // Handle item selection
                          Get.toNamed('/inventory-item-overview',
                              arguments: itemData);
                        },
                        child: ListTile(
                          leading: imagePath.isNotEmpty
                              ? Image.file(
                                  filterQuality: FilterQuality.medium,
                                  File(imagePath),
                                  height: 100,
                                  width: 60,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported),
                          title: Text(
                            itemData['name'] ?? 'Unnamed Item',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 25),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Text('Price: K ${itemData['price']}'),
                              Text('Quantity: ${itemData['quantity']}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                color: blueSecondary,
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // Handle edit action
                                  Get.toNamed('/edit-inventory',
                                      arguments: itemData);
                                },
                              ),
                              IconButton(
                                color: Colors.redAccent,
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  // Handle delete action

                                  await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Delete Item'),
                                          content: Text(
                                              'Are you sure you want to delete this item?'),
                                          actions: [
                                            TextButton(
                                              child: Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.grey)),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                            ),
                                            TextButton(
                                              child: Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                              onPressed: () async {
                                                await inventoryDB
                                                    .deleteInventory(
                                                        itemData['id'] as int);
                                                // Handle delete action
                                                Navigator.pop(context);
                                                setState(() {});
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
