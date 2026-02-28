import 'dart:io';

import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class InventoryItemOverview extends StatefulWidget {
  const InventoryItemOverview({Key? key}) : super(key: key);

  @override
  State<InventoryItemOverview> createState() => _InventoryItemOverviewState();
}

class _InventoryItemOverviewState extends State<InventoryItemOverview> {
  final Config _config = Get.find<Config>();
  List<String> _barcodes = [];
  bool _isLoadingBarcodes = true;

  late final int id;
  late final String name;
  late final String photo;
  late final int quantity;
  late final double price;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    id = arguments['id'] ?? 0;
    name = arguments['name'] ?? '';
    photo = arguments['image_url'] ?? '';
    quantity = arguments['quantity'] ?? 0;
    price = (arguments['price'] ?? 0).toDouble();
    _loadBarcodes();
  }

  Future<void> _loadBarcodes() async {
    setState(() => _isLoadingBarcodes = true);
    final barcodes = await _config.getBarcodesForItem(id);
    setState(() {
      _barcodes = barcodes;
      _isLoadingBarcodes = false;
    });
  }

  Future<void> _addBarcodeManually() async {
    final TextEditingController controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Barcode'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter barcode value',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: bluePrimary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _config.addBarcodeToItem(id, result);
      if (success) {
        _loadBarcodes();
      }
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _BarcodeScannerSheet(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await _config.addBarcodeToItem(id, result);
      if (success) {
        _loadBarcodes();
      }
    }
  }

  Future<void> _deleteBarcode(String barcode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Barcode'),
        content:
            Text('Are you sure you want to remove this barcode?\n\n$barcode'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _config.deleteBarcodeFromItem(id, barcode);
      if (success) {
        _loadBarcodes();
      }
    }
  }

  void _copyBarcode(String barcode) {
    Clipboard.setData(ClipboardData(text: barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Barcode copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                : Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          size: 80, color: Colors.grey),
                    ),
                  ),
            toolbarHeight: DeviceProperties().getHeight(context) / 4,
          ),
          SliverToBoxAdapter(
            key: Key('inventory-item-overview-$id'),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Info Section
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Price', value: 'K $price'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Quantity', value: '$quantity'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      _StatusChip(quantity: quantity),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Barcodes Section
                  _BarcodesSection(
                    barcodes: _barcodes,
                    isLoading: _isLoadingBarcodes,
                    onAddManually: _addBarcodeManually,
                    onScan: _scanBarcode,
                    onDelete: _deleteBarcode,
                    onCopy: _copyBarcode,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final int quantity;
  const _StatusChip({required this.quantity});

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    if (quantity == 0) {
      statusText = 'Out of Stock';
      statusColor = Colors.red;
    } else if (quantity < 10) {
      statusText = 'Low Stock';
      statusColor = Colors.orange;
    } else if (quantity > 60) {
      statusText = 'In Stock';
      statusColor = Colors.green;
    } else {
      statusText = 'Available';
      statusColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}

class _BarcodesSection extends StatelessWidget {
  final List<String> barcodes;
  final bool isLoading;
  final VoidCallback onAddManually;
  final VoidCallback onScan;
  final Function(String) onDelete;
  final Function(String) onCopy;

  const _BarcodesSection({
    required this.barcodes,
    required this.isLoading,
    required this.onAddManually,
    required this.onScan,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2, color: bluePrimary),
                const SizedBox(width: 8),
                const Text(
                  'Barcodes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (!isLoading)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: bluePrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${barcodes.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: bluePrimary,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Scan barcode',
                  onPressed: onScan,
                  icon: Icon(Icons.qr_code_scanner, color: bluePrimary),
                ),
                IconButton(
                  tooltip: 'Add manually',
                  onPressed: onAddManually,
                  icon: Icon(Icons.add_circle_outline, color: bluePrimary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (barcodes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(Icons.qr_code_2, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'No barcodes linked to this item',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onScan,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onAddManually,
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Add Manually',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: bluePrimary),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: barcodes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final barcode = barcodes[index];
              return _BarcodeCard(
                barcode: barcode,
                onDelete: () => onDelete(barcode),
                onCopy: () => onCopy(barcode),
              );
            },
          ),
      ],
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  final String barcode;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const _BarcodeCard({
    required this.barcode,
    required this.onDelete,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bluePrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code, color: bluePrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              barcode,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: Icon(Icons.copy, color: Colors.grey.shade600, size: 20),
            onPressed: onCopy,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// A simple barcode scanner sheet for adding a single barcode
class _BarcodeScannerSheet extends StatefulWidget {
  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  String? _scannedBarcode;
  bool _hasScanned = false;

  void _handleBarcode(BarcodeCapture barcodes) {
    if (_hasScanned) return;
    final barcode = barcodes.barcodes.first.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        _scannedBarcode = barcode;
        _hasScanned = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(onDetect: _handleBarcode),
            // Scanning overlay
            Center(
              child: Container(
                width: 280,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: bluePrimary, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Bottom panel
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_scannedBarcode != null) ...[
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Barcode Scanned!',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _scannedBarcode!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _scannedBarcode = null;
                                  _hasScanned = false;
                                });
                              },
                              child: const Text('Scan Again'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, _scannedBarcode),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: bluePrimary),
                              child: const Text('Add Barcode',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Icon(Icons.qr_code_scanner, size: 40, color: bluePrimary),
                      const SizedBox(height: 12),
                      const Text(
                        'Position barcode within the frame',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
