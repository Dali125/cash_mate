import 'dart:io';
import 'dart:typed_data';

import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/inventory_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class InventoryController extends GetxController {
  final Rxn<FilePickerResult> result = Rxn<FilePickerResult>();
  final RxList<InventoryModel> inventoryList = <InventoryModel>[].obs;
  final RxList<Map<String, dynamic>> mainInventoryList =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString loadingMessage = ''.obs;
  final db = Get.find<Config>();

  @override
  void onInit() {
    super.onInit();
    fetchInventory();
  }

  Future<void> fetchInventory({String? query}) async {
    try {
      isLoading.value = true;
      final data = await db.getInventory(searchQuery: query);
      if (data != null) {
        mainInventoryList.assignAll(data);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to fetch inventory: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick Excel file (.xlsx) - optimized for large files
  Future<void> pickFile() async {
    try {
      isLoading.value = true;
      loadingMessage.value = 'Opening file picker...';

      // Don't load file data during picking - much faster for large files
      final pickedResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: false, // Changed: Don't load bytes during picking
      );

      if (pickedResult == null) {
        isLoading.value = false;
        loadingMessage.value = '';
        return;
      }

      result.value = pickedResult;
      await readExcelFile();
    } catch (e) {
      _showErrorSnackbar('Failed to pick file: $e');
    } finally {
      isLoading.value = false;
      loadingMessage.value = '';
    }
  }

  /// Read and parse Excel using spreadsheet_decoder - runs heavy work in isolate
  Future<void> readExcelFile() async {
    try {
      final file = result.value?.files.first;
      if (file == null) {
        _showErrorSnackbar('No file selected');
        return;
      }

      loadingMessage.value = 'Reading file...';

      // Read bytes from file path (works on all platforms)
      Uint8List? bytes;
      if (file.path != null) {
        bytes = await compute(_readFileBytes, file.path!);
      } else if (file.bytes != null) {
        bytes = file.bytes;
      }

      if (bytes == null || bytes.isEmpty) {
        _showErrorSnackbar('Selected file is empty or unreadable');
        return;
      }

      // XLSX files are ZIP-based
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        _showErrorSnackbar('Invalid file format. Please upload a .xlsx file');
        return;
      }

      loadingMessage.value = 'Processing Excel data...';

      // Parse Excel in a separate isolate to avoid UI freeze
      final parsedItems = await compute(_parseExcelInIsolate, bytes);

      if (parsedItems == null) {
        _showErrorSnackbar(
          'Invalid headers. Expected: Name, Price, Quantity',
        );
        return;
      }

      if (parsedItems.isEmpty) {
        _showErrorSnackbar('No valid inventory rows found');
        return;
      }

      // Update the list on main thread
      inventoryList.assignAll(parsedItems);

      debugPrint('Imported ${inventoryList.length} items');

      Get.snackbar(
        'Success',
        'Imported ${inventoryList.length} items',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stack) {
      debugPrint(stack.toString());
      _showErrorSnackbar('Failed to read Excel file: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> bulkInsert(List<InventoryModel> list) async {
    if (list.isEmpty) {
      _showErrorSnackbar('No items to import');
      return;
    }

    try {
      isLoading.value = true;
      loadingMessage.value = 'Saving ${list.length} items...';
      await db.bulkInserInventory(list);
      // Clear the temporary list after successful import
      inventoryList.clear();
      result.value = null;

      // Refresh the main inventory list
      await fetchInventory();

      // Navigate back to the inventory page
      Get.back(result: true);
    } catch (e) {
      _showErrorSnackbar('Failed to complete import: $e');
    } finally {
      isLoading.value = false;
      loadingMessage.value = '';
    }
  }

  Future<void> fetchItemByBarcode(String barcode) async {}
}

// Top-level functions for isolate execution (must be static/top-level)

/// Reads file bytes in isolate - prevents UI freeze for large files
Uint8List _readFileBytes(String path) {
  return File(path).readAsBytesSync();
}

/// Parses Excel file in isolate - all CPU-intensive work happens here
/// Returns null if headers are invalid, empty list if no valid rows
List<InventoryModel>? _parseExcelInIsolate(Uint8List bytes) {
  try {
    final decoder = SpreadsheetDecoder.decodeBytes(
      bytes,
      update: false, // Don't need update capability, saves memory
    );

    if (decoder.tables.isEmpty) {
      return [];
    }

    final List<InventoryModel> items = [];
    int unnamedCounter = 1;

    for (final tableName in decoder.tables.keys) {
      final sheet = decoder.tables[tableName];
      if (sheet == null || sheet.rows.isEmpty) continue;

      final headers = sheet.rows.first;

      // Validate headers (case-insensitive)
      if (headers.length < 3) return null;

      final h0 = headers[0]?.toString().trim().toLowerCase() ?? '';
      final h1 = headers[1]?.toString().trim().toLowerCase() ?? '';
      final h2 = headers[2]?.toString().trim().toLowerCase() ?? '';

      if (h0 != 'name' || h1 != 'price' || h2 != 'quantity') {
        return null; // Invalid headers
      }

      // Pre-allocate list capacity for better performance
      final rowCount = sheet.rows.length - 1;
      if (items.isEmpty) {
        items.length = 0; // Reset
      }

      // Process all rows (skip header)
      for (int i = 1; i <= rowCount; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        // Parse name with default
        String name = _parseString(row.length > 0 ? row[0] : null);
        if (name.isEmpty) {
          name = 'Unnamed Item $unnamedCounter';
          unnamedCounter++;
        }

        // Parse price with default (handles null, empty, "-", invalid)
        final double price =
            _parseDouble(row.length > 1 ? row[1] : null, defaultValue: 0.0);

        // Parse quantity with default (handles null, empty, "-", invalid)
        final int quantity =
            _parseInt(row.length > 2 ? row[2] : null, defaultValue: 0);

        items.add(
          InventoryModel(
            name: name,
            price: price,
            quantity: quantity,
          ),
        );
      }
    }

    return items;
  } catch (e) {
    // Can't use debugPrint in isolate, just return empty
    return [];
  }
}

/// Parse string value, returns empty string if null/invalid
String _parseString(dynamic value) {
  if (value == null) return '';
  final str = value.toString().trim();
  if (str == '-' || str == 'null' || str == 'N/A' || str == 'n/a') return '';
  return str;
}

/// Parse double value with fallback default
double _parseDouble(dynamic value, {required double defaultValue}) {
  if (value == null) return defaultValue;
  final str = value.toString().trim();
  if (str.isEmpty || str == '-' || str == 'null' || str == 'N/A') {
    return defaultValue;
  }
  // Remove currency symbols and commas
  final cleaned = str.replaceAll(RegExp(r'[^\d.-]'), '');
  return double.tryParse(cleaned) ?? defaultValue;
}

/// Parse int value with fallback default
int _parseInt(dynamic value, {required int defaultValue}) {
  if (value == null) return defaultValue;
  final str = value.toString().trim();
  if (str.isEmpty || str == '-' || str == 'null' || str == 'N/A') {
    return defaultValue;
  }
  // Handle decimal quantities by truncating
  final cleaned = str.replaceAll(RegExp(r'[^\d.-]'), '');
  final asDouble = double.tryParse(cleaned);
  if (asDouble != null) return asDouble.toInt();
  return int.tryParse(cleaned) ?? defaultValue;
}
