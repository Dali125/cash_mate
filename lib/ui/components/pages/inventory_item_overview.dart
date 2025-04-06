import 'dart:io';

import 'package:cash_app/services/device_properties.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryItemOverview extends StatelessWidget {
  const InventoryItemOverview({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;

    final id = arguments['id'] ?? '';
    final name = arguments['name'] ?? '';
    final photo = arguments['image_url'] ?? '';
    final quantity = arguments['quantity'] ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            flexibleSpace: photo.isNotEmpty
                ? Center(
                    child: SizedBox(
                      width: DeviceProperties().getWidth(context),
                      child: Image.file(
                        File(photo),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : null,
            toolbarHeight: DeviceProperties().getHeight(context) / 4,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Product Name : $name",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(
                    'Quantity: $quantity',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        quantity > 60
                            ? 'In Stock'
                            : quantity < 10 && quantity > 1
                                ? 'Low Stock'
                                : quantity == 0
                                    ? 'Out of stock'
                                    : 'Available',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: quantity > 60
                              ? Colors.green
                              : quantity < 10 && quantity > 1
                                  ? Colors.yellow
                                  : quantity == 0
                                      ? Colors.red
                                      : Colors.green,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
