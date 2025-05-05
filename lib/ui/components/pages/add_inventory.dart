import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/ui/components/custom_text_field.dart';
import 'package:cash_app/ui/components/image_picker_custom.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddInventoryPage extends StatefulWidget {
  const AddInventoryPage({super.key});

  @override
  State<AddInventoryPage> createState() => _AddInventoryPageState();
}

class _AddInventoryPageState extends State<AddInventoryPage> {
  TextEditingController itemName = TextEditingController();
  TextEditingController price = TextEditingController();
  TextEditingController quantity = TextEditingController();
  TextEditingController imagePath = TextEditingController();

  // Function to create TextField widgets

  @override
  Widget build(BuildContext context) {
    final mc = Get.find<MediaController>();
    final db = Get.find<Config>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blueTertiary),
          onPressed: () {
            Get.back();
            setState(() {});
          },
        ),
        title: Text(
          'Add Inventory',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: blueTertiary),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a price, quantity, image, and description',
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
                controller: quantity,
                hintText: 'Quantity',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                       ImagePickerWidget(mc: mc, imagePath: imagePath),
                       Text('Choose From Gallery')
                    ],
                  )

               , 
      
                ],
              ),
             

            
            
              
              SizedBox(height: 20),
              Button(
                width: DeviceProperties().getWidth(context),
                height: 50,
                color: blueTertiary,
                text: 'Add Inventory',
                onPressed: () async {
                  if (itemName.text.isNotEmpty &&
                      price.text.isNotEmpty &&
                      quantity.text.isNotEmpty &&
                      imagePath.text.isNotEmpty) {
                    Item myItem = Item(
                      name: itemName.text,
                      price: double.parse(price.text),
                      quantity: int.parse(quantity.text),
                      imageUrl: imagePath.text,
                    );
                    await db.addInventory(myItem);
                    Get.snackbar('Success', 'Inventory added successfully');

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
