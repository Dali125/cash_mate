import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/ui/components/image_picker_custom.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../models/inventort.dart';

class EditInventoryPage extends StatefulWidget {
  const EditInventoryPage({Key? key}) : super(key: key);
  @override
  State<EditInventoryPage> createState() => _EditInventoryPageState();
}

class _EditInventoryPageState extends State<EditInventoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController itemName = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController imagePath = TextEditingController();
  bool _saving = false;
  late dynamic id;

  final db = Get.find<Config>();
  final inventoryController = Get.find<InventoryController>();

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: blueSecondary),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bluePrimary.withOpacity(.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bluePrimary.withOpacity(.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bluePrimary, width: 1.4),
        ),
      );

  @override
  void initState() {
    super.initState();
    final args = Get.arguments ?? {};
    id = args['id'];
    itemName.text = args['name']?.toString() ?? '';
    price.text = args['price']?.toString() ?? '';
    quantityController.text = args['quantity']?.toString() ?? '';
    imagePath.text = args['image_url']?.toString() ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      Item myItem = Item(
        name: itemName.text.trim(),
        price: double.parse(price.text.trim()),
        quantity: int.parse(quantityController.text.trim()),
        imageUrl: imagePath.text.trim(),
      );
      await db.updateInventory(id, myItem);

      // Refresh inventory in background - don't await to avoid blocking navigation
      inventoryController.fetchInventory();

      Get.back();

      // Show snackbar after navigation to ensure it's visible
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar('Success', 'Inventory updated successfully',
            snackPosition: SnackPosition.BOTTOM);
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mc = Get.find<MediaController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: bluePrimary),
          onPressed: () => Get.back(),
        ),
        title: Text('Edit Inventory',
            style: TextStyle(color: bluePrimary, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update item details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800)),
              const SizedBox(height: 18),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: itemName,
                        decoration:
                            _dec('Product Name', Icons.inventory_2_outlined),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: price,
                        decoration:
                            _dec('Price (K)', Icons.attach_money_rounded),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*[.]?[0-9]{0,2}'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null) return 'Invalid number';
                          if (val < 0) return 'Must be positive';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: quantityController,
                        decoration: _dec('Quantity', Icons.numbers_rounded),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = int.tryParse(v);
                          if (val == null) return 'Invalid number';
                          if (val < 0) return 'Must be positive';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Image',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                              ),
                              child: Column(
                                children: [
                                  ImagePickerWidget(
                                      mc: mc, imagePath: imagePath),
                                  const SizedBox(height: 8),
                                  Text(
                                    imagePath.text.isEmpty
                                        ? 'Select from gallery'
                                        : 'Selected',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: imagePath.text.isEmpty
                                            ? Colors.grey
                                            : Colors.green),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : Button(
                        width: DeviceProperties().getWidth(context),
                        height: 54,
                        color: bluePrimary,
                        text: 'Update Inventory',
                        onPressed: _submit,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
