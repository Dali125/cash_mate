import 'dart:io';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryPageTablet extends StatefulWidget {
  const InventoryPageTablet({super.key});

  @override
  State<InventoryPageTablet> createState() => _InventoryPageTabletState();
}

class _InventoryPageTabletState extends State<InventoryPageTablet> {
  final double _cardWidth = 300; // Fixed width for grid items

  @override
  Widget build(BuildContext context) {
    final inventoryDB = Get.find<Config>();
    inventoryDB.initDatabase();

    return Scaffold(
      appBar: AppBar(
          title: Text(
            'Inventory',
            style: TextStyle(
                fontSize: 36, // Larger font for tablet
                color: bluePrimary,
                fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                // Search functionality
              },
            ),
          ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // More padding for tablet
        child: Column(
          children: [
            Container(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SearchBar(
                    leading: Icon(Icons.search, color: Colors.white),
                    hintText: 'Search Inventory',
                    hintStyle:
                        WidgetStatePropertyAll(TextStyle(color: Colors.white)),
                    backgroundColor: WidgetStatePropertyAll(onBluePrimary),
                  ),
                  SizedBox(width: 16),
                  Material(
                    borderRadius: BorderRadius.circular(12),
                    elevation: 10,
                    shadowColor: Colors.blue,
                    child: InkWell(
                        child: Container(
                          width: 150,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text('Add Item',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        mouseCursor: MouseCursor.defer,
                        onTap: () => Get.toNamed('/add-inventory-tablet'),
                        onHover: (value) {
                          if (value) {
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                            );
                          } else {}
                        }),
                  ),
                ],
              ),
            ),
            FutureBuilder(
              future: inventoryDB.getInventory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.data == null) {
                  return Center(child: Text('No inventory items available'));
                } else {
                  final inventory = snapshot.data!;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _calculateCrossAxisCount(context),
                    ),
                    itemBuilder: (context, index) {
                      return _buildInventoryCard(
                        inventory[index],
                        inventory[index]['image_path'],
                        inventoryDB,
                      );
                    },
                    itemCount: inventory.length,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / _cardWidth).floor().clamp(2, 4);
  }

  Widget _buildInventoryCard(
      Map<String, dynamic> itemData, String imagePath, Config inventoryDB) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            Get.toNamed('/inventory-item-overview', arguments: itemData),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Center(
                child: imagePath.isNotEmpty
                    ? Image.file(
                        File(imagePath),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      )
                    : Icon(Icons.image_not_supported, size: 60),
              ),

              SizedBox(height: 12),

              // Item Name
              Text(
                itemData['name'] ?? 'Unnamed Item',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22, // Larger text
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),

              SizedBox(height: 8),

              // Price and Quantity
              Text(
                'Price: \$${itemData['price']}',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                'Quantity: ${itemData['quantity']}',
                style: TextStyle(fontSize: 18),
              ),

              Spacer(),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    iconSize: 28, // Larger icons
                    color: blueSecondary,
                    icon: Icon(Icons.edit),
                    onPressed: () => Get.toNamed('/edit-inventory-tablet',
                        arguments: itemData),
                  ),
                  IconButton(
                    iconSize: 28,
                    color: Colors.redAccent,
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(itemData, inventoryDB),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
      Map<String, dynamic> itemData, Config inventoryDB) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Item',
            style: TextStyle(fontSize: 24), // Larger text
          ),
          content: Text(
            'Are you sure you want to delete this item?',
            style: TextStyle(fontSize: 20), // Larger text
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style:
                    TextStyle(color: Colors.grey, fontSize: 20), // Larger text
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                'Delete',
                style:
                    TextStyle(color: Colors.red, fontSize: 20), // Larger text
              ),
              onPressed: () async {
                await inventoryDB.deleteInventory(itemData['id'] as int);
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}
