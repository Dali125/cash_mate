import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/ui/components/custom_text_field.dart';
import 'package:cash_app/ui/components/image_picker_custom.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/inventort.dart';

class EditInventoryPage extends StatelessWidget {
  const EditInventoryPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final mc = Get.find<MediaController>();
    final db = Get.find<Config>();
    final arguments = Get.arguments;
    final id = arguments['id'] ?? '';
    final priceDB = arguments['price'] ?? 0;
    final name = arguments['name'] ?? '';
    final photo = arguments['image_url'] ?? '';
    final quantity = arguments['quantity'] ?? 0;

    TextEditingController itemName = TextEditingController();
    TextEditingController price = TextEditingController();
    TextEditingController quantityController = TextEditingController();
    TextEditingController imagePath = TextEditingController();
    itemName.text = name;
    price.text = priceDB.toString();
    quantityController.text = quantity.toString();
    imagePath.text = photo;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Inventory'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit price, quantity, image, and description',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 20),
              buildTextField(
                controller: itemName,
                hintText: 'Product Name',
                icon: Icons.abc,
              ),
              buildTextField(
                controller: price,
                hintText: 'Price',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              buildTextField(
                controller: quantityController,
                hintText: 'Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              ImagePickerWidget(mc: mc, imagePath: imagePath),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextField(
                controller: imagePath,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add item description',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: blueSecondary),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Button(
                width: DeviceProperties().getWidth(context),
                height: 50,
                color: blueTertiary,
                text: 'Update Inventory',
                onPressed: () async {
                  if (itemName.text.isNotEmpty &&
                      price.text.isNotEmpty &&
                      quantityController.text.isNotEmpty &&
                      imagePath.text.isNotEmpty) {
                    Item myItem = Item(
                      name: itemName.text,
                      price: double.parse(price.text),
                      quantity: int.parse(quantityController.text),
                      imageUrl: imagePath.text,
                    );
                    await db.updateInventory(id, myItem);
                    Get.snackbar('Success', 'Inventory updated successfully');

                    Get.offAllNamed('/');
                  } else {
                    Get.snackbar('Error', 'Please fill all fields');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
