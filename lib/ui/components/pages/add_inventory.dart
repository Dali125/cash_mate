import 'dart:io';
import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _showValidationErrors = false;

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: blueSecondary),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = Get.find<Config>();
      Item myItem = Item(
        name: itemName.text.trim(),
        price: double.parse(price.text.trim()),
        quantity: int.parse(quantity.text.trim()),
        imageUrl: imagePath.text.trim(),
      );
      await db.addInventory(myItem);
      Get.snackbar('Success', 'Inventory added successfully',
          snackPosition: SnackPosition.BOTTOM);
      Get.offAllNamed('/');
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
    final isWide = MediaQuery.of(context).size.width > 640;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: bluePrimary),
          onPressed: () => Get.back(),
        ),
        title: Text('Add Inventory',
            style: TextStyle(
                color: bluePrimary, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _showValidationErrors ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: LayoutBuilder(
          builder: (context, constraints) {
            Widget fields = Column(
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: price,
                        decoration:
                            _dec('Price (K)', Icons.attach_money_rounded),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]*[.]?[0-9]{0,2}'))
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null) return 'Invalid';
                          if (val < 0) return 'Positive only';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: quantity,
                        decoration: _dec('Quantity', Icons.numbers_rounded),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final val = int.tryParse(v);
                          if (val == null) return 'Invalid';
                          if (val < 0) return 'Positive only';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );

            Widget imageSelector = AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
       
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'hero-new-item-image',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        color: Colors.white,
                        child: imagePath.text.isEmpty
                            ? Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400)
                            : Image.file(
                                File(imagePath.text),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, size: 64, color: Colors.redAccent),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.photo_library, color: blueSecondary, size: 32),
                            onPressed: () async {
                              final image = await mc.pickImage();
                              if (image != null) {
                                setState(() {
                                  imagePath.text = image.path;
                                });
                              }
                            },
                          ),
                          Text('Gallery', style: TextStyle(fontSize: 12, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.camera_alt, color: blueSecondary, size: 32),
                            onPressed: () async {
                              final image = await mc.takeImageFromCamera();
                              if (image != null) {
                                setState(() {
                                  imagePath.text = image.path;
                                });
                              }
                            },
                          ),
                          Text('Camera', style: TextStyle(fontSize: 12, color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    imagePath.text.isEmpty ? 'Choose image from gallery or take a photo' : 'Image selected',
                    style: TextStyle(fontSize: 12, color: imagePath.text.isEmpty ? Colors.black : Colors.green),
                  ),
                ],
              ),
            );

            return RefreshIndicator(
              onRefresh: () async { itemName.clear(); price.clear(); quantity.clear(); imagePath.clear(); },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Item Details',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800)),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: fields),
                                  const SizedBox(width: 22),
                                  Expanded(child: imageSelector),
                                ],
                              )
                            : Column(
                                children: [
                                  fields,
                                  const SizedBox(height: 24),
                                  imageSelector,
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _saving
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: bluePrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                ),
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('Save Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                onPressed: () {
                                  if (!_formKey.currentState!.validate()) {
                                    setState(() => _showValidationErrors = true);
                                    return;
                                  }
                                  _submit();
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
