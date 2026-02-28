import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/ui/components/alert_banner.dart';
import 'package:cash_app/ui/components/image_selector.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BarcodeSummaryPage extends StatefulWidget {
  final List<String> scannedValues;
  const BarcodeSummaryPage({super.key, required this.scannedValues});

  @override
  State<BarcodeSummaryPage> createState() => _BarcodeSummaryPageState();
}

class _BarcodeSummaryPageState extends State<BarcodeSummaryPage> {
  TextEditingController imagePath = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  TextEditingController itemAmountController = TextEditingController();
  TextEditingController itemPriceController = TextEditingController();
  bool _isSaving = false;

  final MediaController mc = Get.find<MediaController>();
  final Config db = Get.find<Config>();
  final InventoryController inventoryController =
      Get.find<InventoryController>();

  Future<void> _saveItem() async {
    if (_isSaving) return;

    if (itemNameController.text.isEmpty ||
        itemAmountController.text.isEmpty ||
        itemPriceController.text.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields before saving.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      Item newItem = Item(
        name: itemNameController.text,
        price: double.tryParse(itemPriceController.text) ?? 0.0,
        quantity: int.tryParse(itemAmountController.text) ?? 0,
        imageUrl: imagePath.text,
      );

      if (kDebugMode) {
        print("Saving item: $newItem");
      }

      await db.addItemsWithBarCodes(newItem, widget.scannedValues);
      await inventoryController.fetchInventory();

      // Use Navigator.pop for more reliable navigation
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saving item with barcodes: $e");
      }
      Get.snackbar(
        "Error",
        "Failed to save item. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            children: [
              alertBanner(
                  "Please add the relevant information for the scanned items. The Barcodes will be saved alongside the item details.",
                  Colors.yellow.shade800,
                  Colors.yellow.shade100,
                  12,
                  0,
                  double.infinity,
                  Icons.warning_amber_rounded),
              const SizedBox(height: 20),
              TextField(
                controller: itemNameController,
                decoration: _dec("Item Name", Icons.label),
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.numberWithOptions(),
                controller: itemAmountController,
                decoration: _dec("Item Amount", Icons.description),
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.numberWithOptions(
                    decimal: true, signed: false),
                controller: itemPriceController,
                decoration: _dec("Item Price", Icons.price_change),
              ),
              const SizedBox(height: 20),
              imageSelector(imagePath, setState, mc: mc),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bluePrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Save Item",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
