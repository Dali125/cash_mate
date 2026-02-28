import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/ui/components/alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryExcelPage extends StatefulWidget {
  const InventoryExcelPage({super.key});

  @override
  State<InventoryExcelPage> createState() => _InventoryExcelPageState();
}

class _InventoryExcelPageState extends State<InventoryExcelPage> {
  final inventoryController = Get.find<InventoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Inventory Import',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  alertBanner(
                    "Ensure your Excel file (.xlsx) contains a single sheet with 'Name', 'Price', and 'Quantity' headers in the first row.",
                    Colors.amber[900]!,
                    Colors.amber[50]!,
                    12,
                    0, // Ignored by updated alertBanner
                    double.infinity,
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Upload File",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 40,
                            color: Colors.blue[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(() {
                          final hasFile =
                              inventoryController.result.value != null;
                          final fileName = inventoryController
                                  .result.value?.files.first.name ??
                              'No file selected';
                          return Column(
                            children: [
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: hasFile
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: hasFile ? Colors.black87 : Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (hasFile) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "${(inventoryController.result.value!.files.first.size / 1024).toStringAsFixed(2)} KB",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ],
                          );
                        }),
                        const SizedBox(height: 30),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: inventoryController.isLoading.value
                                  ? null
                                  : () => inventoryController.pickFile(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file),
                                  SizedBox(width: 10),
                                  Text(
                                    'Choose Excel File',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: inventoryController.isLoading.value ||
                                      inventoryController.inventoryList.isEmpty
                                  ? null
                                  : () => inventoryController.bulkInsert(
                                      inventoryController.inventoryList),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  inventoryController.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  const SizedBox(width: 10),
                                  Text(
                                    inventoryController.inventoryList.isEmpty
                                        ? 'No Items to Import'
                                        : 'Import ${inventoryController.inventoryList.length} Items',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Instructions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStepItem(
                      "1", "Prepare your file in .xlsx format (Excel)."),
                  _buildStepItem(
                      "2", "Include columns: Name, Price, and Quantity."),
                  _buildStepItem(
                      "3", "Ensure Price and Quantity are valid numbers."),
                  _buildStepItem(
                      "4", "The first sheet will be analyzed by default."),
                ],
              ),
            ),
          ),
          // Loading overlay
          Obx(() {
            if (!inventoryController.isLoading.value) {
              return const SizedBox.shrink();
            }
            return Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        inventoryController.loadingMessage.value.isNotEmpty
                            ? inventoryController.loadingMessage.value
                            : 'Please wait...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
