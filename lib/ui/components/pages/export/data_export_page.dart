import 'dart:convert';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({Key? key}) : super(key: key);

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  final Config db = Get.find<Config>();
  bool _isExporting = false;
  
  // Export options
  bool _exportSales = true;
  bool _exportInventory = true;
  bool _includeImages = false;
  String _dateRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _exportToCSV() async {
    if (!_exportSales && !_exportInventory) {
      Get.snackbar(
        'Error',
        'Please select at least one data type to export',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final List<XFile> files = [];
      final List<String> fileNames = [];

      // Export Sales Data
      if (_exportSales) {
        final salesCSV = await _generateSalesCSV();
        final salesFileName = 'sales_export_$timestamp.csv';
        files.add(
          XFile.fromData(
            utf8.encode(salesCSV),
            mimeType: 'text/csv',
            name: salesFileName,
          ),
        );
        fileNames.add(salesFileName);
      }

      // Export Inventory Data
      if (_exportInventory) {
        final inventoryCSV = await _generateInventoryCSV();
        final inventoryFileName = 'inventory_export_$timestamp.csv';
        files.add(
          XFile.fromData(
            utf8.encode(inventoryCSV),
            mimeType: 'text/csv',
            name: inventoryFileName,
          ),
        );
        fileNames.add(inventoryFileName);
      }

      // On web this triggers file download/share. On mobile it opens share sheet.
      if (files.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            text: 'CashMate Data Export - $timestamp',
            files: files,
            fileNameOverrides: fileNames,
          ),
        );

        Get.snackbar(
          'Success',
          kIsWeb
              ? 'Data exported successfully! CSV download has started.'
              : 'Data exported successfully! Files have been shared.',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Export failed: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<String> _generateSalesCSV() async {
    final salesRows = await db.getSalesExportRows();
    if (salesRows.isEmpty) {
      return 'No sales data available\n';
    }

    final buffer = StringBuffer();

    // CSV headers tailored for business users (one row per sold item)
    buffer.writeln(
      'Sale ID,Transaction Type,Date,Time,Item Name,Quantity Sold,Unit Price (K),Line Total (K),Sale Total (K)',
    );

    final filteredSales = _filterSalesByDate(
      salesRows
          .map((row) => {
                ...row,
                'date': row['sale_date'],
              })
          .toList(),
    );

    for (final row in filteredSales) {
      final saleDate = _parseDateTime(row['sale_date']);
      final saleId = row['sale_id']?.toString() ?? '';
      final transactionType = row['transaction_type']?.toString() ?? 'Unknown';
      final itemName = (row['item_name']?.toString().trim().isNotEmpty ?? false)
          ? row['item_name'].toString()
          : 'N/A';
      final quantitySold = _asIntString(row['quantity_sold']);
      final unitPrice = _formatMoney(row['unit_price']);
      final lineTotal = _formatMoney(row['line_total']);
      final saleTotal = _formatMoney(row['sale_total']);

      buffer.writeln([
        _csvCell(saleId),
        _csvCell(transactionType),
        _csvCell(_formatDate(saleDate, row['sale_date']?.toString() ?? '')),
        _csvCell(_formatTime(saleDate)),
        _csvCell(itemName),
        _csvCell(quantitySold),
        _csvCell(unitPrice),
        _csvCell(lineTotal),
        _csvCell(saleTotal),
      ].join(','));
    }

    return buffer.toString();
  }

  Future<String> _generateInventoryCSV() async {
    final inventoryData = await db.getInventory();
    if (inventoryData == null || inventoryData.isEmpty) {
      return 'No inventory data available\n';
    }

    final buffer = StringBuffer();
    
    // CSV headers with user-friendly labels
    if (_includeImages) {
      buffer.writeln(
          'Item Name,Current Stock,Unit Price (K),Stock Value (K),Stock Status,Image URL');
    } else {
      buffer.writeln(
          'Item Name,Current Stock,Unit Price (K),Stock Value (K),Stock Status');
    }

    for (final item in inventoryData) {
      final name = item['name']?.toString() ?? '';
      final unitPrice = _formatMoney(item['price']);
      final quantity = _asIntString(item['quantity']);
      final imageUrl = item['image_url'] ?? '';

      // Calculate stock status
      final qty = (item['quantity'] ?? 0) as num;
      String stockStatus = 'In Stock';
      if (qty == 0) {
        stockStatus = 'Out of Stock';
      } else if (qty < 5) {
        stockStatus = 'Critical';
      } else if (qty < 10) {
        stockStatus = 'Low Stock';
      }

      // Calculate stock value
      final stockValue = _formatMoney(((item['price'] ?? 0) as num) * qty);

      if (_includeImages) {
        buffer.writeln([
          _csvCell(name),
          _csvCell(quantity),
          _csvCell(unitPrice),
          _csvCell(stockValue),
          _csvCell(stockStatus),
          _csvCell(imageUrl.toString()),
        ].join(','));
      } else {
        buffer.writeln([
          _csvCell(name),
          _csvCell(quantity),
          _csvCell(unitPrice),
          _csvCell(stockValue),
          _csvCell(stockStatus),
        ].join(','));
      }
    }

    return buffer.toString();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime? date, String fallback) {
    if (date == null) return fallback;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _asIntString(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is num) return value.toInt().toString();
    return int.tryParse(value.toString())?.toString() ?? '0';
  }

  String _formatMoney(dynamic value) {
    if (value == null) return '0.00';
    final number = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0.0;
    return number.toStringAsFixed(2);
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  List<Map<String, dynamic>> _filterSalesByDate(List<Map<String, dynamic>> salesData) {
    if (_dateRange == 'all') return salesData;

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_dateRange) {
      case 'week':
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case 'year':
        cutoffDate = now.subtract(const Duration(days: 365));
        break;
      case 'custom':
        if (_startDate == null || _endDate == null) return salesData;
        return salesData.where((sale) {
          final dateStr = sale['date']?.toString();
          if (dateStr == null) return false;
          final saleDate = DateTime.tryParse(dateStr);
          if (saleDate == null) return false;
          return saleDate.isAfter(_startDate!) && saleDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }).toList();
      default:
        return salesData;
    }

    return salesData.where((sale) {
      final dateStr = sale['date']?.toString();
      if (dateStr == null) return false;
      final saleDate = DateTime.tryParse(dateStr);
      if (saleDate == null) return false;
      return saleDate.isAfter(cutoffDate);
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? bluePrimary.withOpacity(0.3) : Colors.grey.shade200,
          width: value ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: icon != null
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: value ? bluePrimary.withOpacity(0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: value ? bluePrimary : Colors.grey.shade600,
                  size: 24,
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: value ? bluePrimary : Colors.grey.shade800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.3,
          ),
        ),
        trailing: Transform.scale(
          scale: 1.1,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: bluePrimary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bluePrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.date_range, color: bluePrimary, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'Export Date Range',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildDateChip('All Time', 'all'),
              _buildDateChip('Last Week', 'week'),
              _buildDateChip('Last Month', 'month'),
              _buildDateChip('Last Year', 'year'),
              _buildDateChip('Custom Range', 'custom'),
            ],
          ),
          if (_dateRange == 'custom') ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectDateRange,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: bluePrimary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.calendar_today, color: bluePrimary),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Select Date Range',
                  style: TextStyle(
                    fontSize: 14,
                    color: bluePrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, String value) {
    final isSelected = _dateRange == value;
    return InkWell(
      onTap: () => setState(() => _dateRange = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bluePrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? bluePrimary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: bluePrimary,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bluePrimary.withOpacity(0.1), Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.file_download_outlined, size: 28, color: bluePrimary),
                      const SizedBox(width: 12),
                      Text(
                        'Data Export',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: bluePrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Export your business data to CSV files for backup, analysis, or sharing with your accountant. Choose what data to include and customize your export options.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Data Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildOptionCard(
              title: 'Sales Data',
              subtitle: 'Each row shows item sold, quantity, payment type, date, and time',
              value: _exportSales,
              onChanged: (value) => setState(() => _exportSales = value),
              icon: Icons.point_of_sale,
            ),
            
            _buildOptionCard(
              title: 'Inventory Data',
              subtitle: 'Shows item name, stock on hand, unit price, and stock value',
              value: _exportInventory,
              onChanged: (value) => setState(() => _exportInventory = value),
              icon: Icons.inventory_2,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Export Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildOptionCard(
              title: 'Include Image URLs',
              subtitle: 'Include product image paths in inventory export',
              value: _includeImages,
              onChanged: (value) => setState(() => _includeImages = value),
              icon: Icons.image,
            ),
            
            const SizedBox(height: 16),
            
            if (_exportSales) _buildDateRangeCard(),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportToCSV,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bluePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  shadowColor: bluePrimary.withOpacity(0.3),
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white, size: 24),
                label: Text(
                  _isExporting ? 'Exporting Data...' : 'Export to CSV',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Information',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CSV files can be opened in Excel, Google Sheets, or any spreadsheet application for further analysis. Files will be shared through your device\'s sharing options.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
