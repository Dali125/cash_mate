import 'dart:async';
import 'dart:io';

import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/ui/components/pages/analytics/sales_analytics_page.dart';
import 'package:cash_app/ui/components/pages/export/data_export_page.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';

class _CatalogDocResult {  // Moved to top-level
  final pw.Document doc;
  final DateTime timestamp;
  _CatalogDocResult(this.doc, this.timestamp);
}

class MoreToolsPage extends StatefulWidget {
  const MoreToolsPage({super.key});

  @override
  State<MoreToolsPage> createState() => _MoreToolsPageState();
}

class _MoreToolsPageState extends State<MoreToolsPage> {
  bool _generating = false;
  final db = Get.find<Config>();

  // Catalog builder options
  Color _catalogBg = Colors.white;
  String? _catalogBgImage;
  double _bgOpacity = 0.1;
  bool _includeImages = true;
  bool _includePrice = true;
  bool _includeQuantity = true;
  double _imageSize = 60;
  double _cardElevation = 2;
  Color _cardColor = Colors.white;
  int _columns = 2; // 2-4 columns supported
  String _sort = 'name_asc';
  double _borderRadius = 14;

  pdf.PdfColor _pdfColor(Color c) => pdf.PdfColor.fromInt(c.value);

  Future<List<SalesModel>> _fetchSales() async {
    try {
      final raw = await db.getSalesHistory();
      if (raw == null) return [];
      return raw.map((m) => SalesModel(
        date: m['date'] as String?,
        total: (m['amount'] as num?)?.toDouble(),
        itemsSold: [], // not reconstructing detailed items from text blob
        transactionType: m['transaction_type'] as String?,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _printIncomeStatement() async {
    setState(() => _generating = true);
    final doc = pw.Document();
    final sales = await _fetchSales();
    double totalRevenue = 0;
    int totalItems = 0;
    for (final s in sales) {
      totalRevenue += s.total ?? 0;
      totalItems += (s.itemsSold?.fold<int>(0, (p, c) => p + (c.quantity ?? 0))) ?? 0;
    }
    final now = DateTime.now();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Income Statement', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold))),
          pw.Text('Generated: ${now.toIso8601String()}'),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Sales Count', sales.length.toString()],
              ['Total Items Sold', totalItems.toString()],
              ['Total Revenue', 'K ${totalRevenue.toStringAsFixed(2)}'],
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Detail (First 20 Sales)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Date', 'Total', 'Items'],
            data: sales.take(20).map((s) => [s.date ?? '-', 'K ${(s.total ?? 0).toStringAsFixed(2)}', (s.itemsSold?.length ?? 0).toString()]).toList(),
          ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'income_statement_${now.toIso8601String()}.pdf');
    if (mounted) setState(() => _generating = false);
  }

  Future<_CatalogDocResult> _buildCatalogDocument() async {
    final rawInventory = await db.getInventory() ?? [];
    final inventory = rawInventory.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    inventory.sort((a, b) {
      switch (_sort) {
        case 'name_desc': return (b['name'] ?? '').toString().toLowerCase().compareTo((a['name'] ?? '').toString().toLowerCase());
        case 'price_asc': return ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num);
        case 'price_desc': return ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num);
        case 'qty_asc': return ((a['quantity'] ?? 0) as num).compareTo((b['quantity'] ?? 0) as num);
        case 'qty_desc': return ((b['quantity'] ?? 0) as num).compareTo((a['quantity'] ?? 0) as num);
        case 'name_asc':
        default:
          return (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase());
      }
    });

    final images = <int, pw.MemoryImage>{};
    if (_includeImages) {
      for (int i = 0; i < inventory.length; i++) {
        final p = inventory[i]['image_url']?.toString();
        if (p != null && p.isNotEmpty) {
          final file = File(p);
          if (await file.exists()) {
            try { images[i] = pw.MemoryImage(await file.readAsBytes()); } catch (_) {}
          }
        }
      }
    }

    final doc = pw.Document();
    final now = DateTime.now();
    pw.MemoryImage? bgImage;
    if (_catalogBgImage != null) {
      try {
        final bgFile = File(_catalogBgImage!);
        if (await bgFile.exists()) {
          bgImage = pw.MemoryImage(await bgFile.readAsBytes());
        }
      } catch (e) {
        print('Error loading background image: $e');
      }
    }

    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (ctx) => pw.Stack(
        children: [
          pw.Container(color: _pdfColor(_catalogBg)),
          if (bgImage != null)
            pw.Opacity(
              opacity: _bgOpacity,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  image: pw.DecorationImage(
                    image: bgImage,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
      pageFormat: pdf.PdfPageFormat.a4,
    );

    pw.Widget itemCard(Map<String, dynamic> item, int index) {
      final name = (item['name'] ?? '').toString();
      final price = (item['price'] ?? 0).toString();
      final qty = (item['quantity'] ?? 0).toString();
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _pdfColor(_cardColor),
          borderRadius: pw.BorderRadius.circular(_borderRadius),
          border: pw.Border.all(
            color: _pdfColor(Colors.grey.shade300),
            width: 0.5,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_includeImages && images[index] != null)
              pw.Center(
                child: pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: pw.Image(images[index]!, width: _imageSize, height: _imageSize, fit: pw.BoxFit.cover),
                ),
              ),
            if (_includeImages) pw.SizedBox(height: 8),
            pw.Text(name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            if (_includePrice) pw.Text('K $price', style: pw.TextStyle(fontSize: 10)),
            if (_includeQuantity) pw.Text('Items Left: $qty', style: pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey600)),
          ],
        ),
      );
    }

    final rows = <pw.Widget>[];
    final chunk = <Map<String, dynamic>>[];
    for (int i = 0; i < inventory.length; i++) {
      chunk.add(inventory[i]);
      if (chunk.length == _columns || i == inventory.length - 1) {
        rows.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < chunk.length; j++)
                pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: itemCard(chunk[j], i - (chunk.length - 1) + j))),
              if (chunk.length < _columns)
                for (int k = 0; k < _columns - chunk.length; k++) pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        );
        rows.add(pw.SizedBox(height: 14));
        chunk.clear();
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10, left: 4, right: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Product Catalog', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _catalogBg == Colors.black ? pdf.PdfColors.white : pdf.PdfColors.black)),
              pw.Text('Generated: ${now.toIso8601String()}', style: pw.TextStyle(fontSize: 9, color: _catalogBg == Colors.black ? pdf.PdfColors.white : pdf.PdfColors.grey600)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: pw.Column(children: rows),
          ),
        ],
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, right: 4),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}', style: pw.TextStyle(fontSize: 9, color: _catalogBg == Colors.black ? pdf.PdfColors.white : pdf.PdfColors.grey600)),
            ),
        ),
      ),
    );
    return _CatalogDocResult(doc, now);
  }

  Future<void> _previewCatalogPdf() async {
    setState(() => _generating = true);
    try {
      final result = await _buildCatalogDocument();
      if (!mounted) return;
      await Get.to(() => _CatalogPreviewPage(result: result));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateCatalogPdf() async {
    setState(() => _generating = true);
    try {
      final result = await _buildCatalogDocument();
      await Printing.sharePdf(bytes: await result.doc.save(), filename: 'catalog_${result.timestamp.toIso8601String()}.pdf');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _openCatalogBuilder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void update(VoidCallback fn) { setSheet(fn); }
            final presets = <Color>[Colors.white, const Color(0xFFF5F6FA), Colors.blue.shade50, Colors.green.shade50, Colors.orange.shade50, Colors.purple.shade50, Colors.grey.shade200, Colors.black];
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Build Catalog', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_generating) const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close))
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Customize your catalog PDF.', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Background Color', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: presets.map((c) {
                                  final bool selected = c == _catalogBg;
                                  return GestureDetector(
                                    onTap: () => update(() => _catalogBg = c),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: c,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: selected ? bluePrimary : Colors.grey.shade300, width: selected ? 2.5 : 1),
                                      ),
                                      child: selected ? Icon(Icons.check, size: 20, color: c == Colors.white ? Colors.black : Colors.white) : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _labeled(
                            'Background Image',
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _catalogBgImage != null ? 'Image selected' : 'No image selected',
                                            style: TextStyle(
                                              color: _catalogBgImage != null ? Colors.green.shade600 : Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (_catalogBgImage != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () => update(() => _catalogBgImage = null),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bluePrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    final mc = Get.find<MediaController>();
                                    final image = await mc.pickImage();
                                    if (image != null) {
                                      update(() => _catalogBgImage = image.path);
                                    }
                                  },
                                  icon: const Icon(Icons.image, size: 18),
                                  label: const Text('Choose'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_catalogBgImage != null) ...[
                      const SizedBox(height: 12),
                      _labeled(
                        'Background Opacity (${(_bgOpacity * 100).toInt()}%)',
                        Slider(
                          value: _bgOpacity,
                          min: 0.05,
                          max: 0.3,
                          divisions: 25,
                          label: '${(_bgOpacity * 100).toInt()}%',
                          onChanged: (v) => update(() => _bgOpacity = v),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(children: [
                      Expanded(child: _optionSwitch('Images', _includeImages, (v) => update(() => _includeImages = v))),
                      Expanded(child: _optionSwitch('Price', _includePrice, (v) => update(() => _includePrice = v))),
                      Expanded(child: _optionSwitch('Quantity', _includeQuantity, (v) => update(() => _includeQuantity = v))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: _labeled(
                          'Columns',
                          DropdownButton<int>(
                            value: _columns,
                            isExpanded: true,
                            items: [2,3,4].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                            onChanged: (v) => update(() => _columns = v ?? 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _labeled(
                          'Sort',
                          DropdownButton<String>(
                            value: _sort,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 'name_asc', child: Text('Name A-Z')),
                              DropdownMenuItem(value: 'name_desc', child: Text('Name Z-A')),
                              DropdownMenuItem(value: 'price_asc', child: Text('Price Low-High')),
                              DropdownMenuItem(value: 'price_desc', child: Text('Price High-Low')),
                              DropdownMenuItem(value: 'qty_asc', child: Text('Qty Low-High')),
                              DropdownMenuItem(value: 'qty_desc', child: Text('Qty High-Low')),
                            ],
                            onChanged: (v) => update(() => _sort = v ?? 'name_asc'),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _labeled(
                      'Image Size (${_imageSize.toInt()}px)',
                      Slider(
                        value: _imageSize,
                        min: 40,
                        max: 120,
                        divisions: 8,
                        label: _imageSize.toInt().toString(),
                        onChanged: (v) => update(() => _imageSize = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _labeled(
                      'Card Style',
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _labeled(
                                  'Border Radius',
                                  Slider(
                                    value: _borderRadius,
                                    min: 0,
                                    max: 24,
                                    divisions: 24,
                                    label: _borderRadius.toInt().toString(),
                                    onChanged: (v) => update(() => _borderRadius = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _labeled(
                                  'Card Color',
                                  Container(
                                    height: 42,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: _cardColor,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DropdownButton<Color>(
                                            value: _cardColor,
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items: [
                                              Colors.white,
                                              Colors.grey.shade50,
                                              Colors.blue.shade50,
                                              Colors.green.shade50,
                                              Colors.orange.shade50,
                                            ].map((c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c == Colors.white ? 'White' : 'Light ${c.toString().split('(')[0]}'),
                                            )).toList(),
                                            onChanged: (c) => update(() => _cardColor = c ?? Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _labeled(
                                  'Card Elevation',
                                  Slider(
                                    value: _cardElevation,
                                    min: 0,
                                    max: 8,
                                    divisions: 8,
                                    label: _cardElevation.toInt().toString(),
                                    onChanged: (v) => update(() => _cardElevation = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.grey.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                onPressed: _generating ? null : () async {
                                  Navigator.pop(ctx);
                                  await _previewCatalogPdf();
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Preview'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: bluePrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                                onPressed: _generating ? null : () async {
                                  Navigator.pop(ctx);
                                  await _generateCatalogPdf();
                                },
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Generate'),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _optionSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
        Switch(value: value, onChanged: onChanged, activeColor: bluePrimary),
      ],
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  void _exportData() async {
    Get.to(() => const DataExportPage());
  }

  void _backupData() async {
    Get.snackbar('Backup', 'Backup feature coming soon');
  }

  void _showSalesAnalytics() async {
    final sales = await _fetchSales();
    if (!mounted) return;
    
    Get.to(() => SalesAnalyticsPage(sales: sales));
  }

  void _showProfitCalculator() {
    final costController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculateProfit() {
              final cost = double.tryParse(costController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;
              final quantity = int.tryParse(quantityController.text) ?? 1;
              
              final totalCost = cost * quantity;
              final revenue = price * quantity;
              final profit = revenue - totalCost;
              final margin = price > 0 ? (profit / revenue) * 100 : 0;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profit Analysis'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profitMetric('Total Cost', 'K ${totalCost.toStringAsFixed(2)}'),
                      _profitMetric('Revenue', 'K ${revenue.toStringAsFixed(2)}'),
                      _profitMetric('Profit', 'K ${profit.toStringAsFixed(2)}'),
                      _profitMetric('Margin', '${margin.toStringAsFixed(1)}%'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Profit Calculator', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: costController,
                    decoration: _dec('Cost per item (K)', Icons.money_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: _dec('Selling price (K)', Icons.sell_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: _dec('Quantity', Icons.numbers_outlined),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: calculateProfit,
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Calculate'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStockAlerts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder(
              future: db.getInventory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final inventory = (snapshot.data as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
                final lowStock = inventory.where((item) {
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                  return quantity < 10;
                }).toList();

                return Container(
                  padding: const EdgeInsets.all(24),
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Stock Alerts', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Low Stock Items (< 10)', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800)
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: lowStock.isEmpty
                            ? Center(
                                child: Text(
                                  'All items are well stocked!',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              )
                            : ListView.builder(
                                itemCount: lowStock.length,
                                itemBuilder: (context, index) {
                                  final item = lowStock[index];
                                  final quantity = item['quantity'] as int? ?? 0;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      title: Text(item['name']?.toString() ?? ''),
                                      subtitle: Text('Current stock: $quantity'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: quantity < 5 ? Colors.red.shade100 : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          quantity < 5 ? 'Critical' : 'Low',
                                          style: TextStyle(
                                            color: quantity < 5 ? Colors.red.shade900 : Colors.orange.shade900,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCustomerList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Customer List', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Customer management coming soon!',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track customer information and purchase history',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTaxCalculator() {
    final amountController = TextEditingController();
    final taxRateController = TextEditingController(text: '16'); // Default VAT rate

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculateTax() {
              final amount = double.tryParse(amountController.text) ?? 0;
              final taxRate = double.tryParse(taxRateController.text) ?? 0;
              
              final taxAmount = amount * (taxRate / 100);
              final totalWithTax = amount + taxAmount;
              final netAmount = amount / (1 + (taxRate / 100));
              final taxFromGross = amount - netAmount;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tax Calculation'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base Amount: K ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Tax Rate: ${taxRate.toStringAsFixed(1)}%'),
                      const Divider(),
                      Text('Tax on Net: K ${taxAmount.toStringAsFixed(2)}'),
                      Text('Total with Tax: K ${totalWithTax.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Text('Net from Gross: K ${netAmount.toStringAsFixed(2)}'),
                      Text('Tax from Gross: K ${taxFromGross.toStringAsFixed(2)}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tax Calculator', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    decoration: _dec('Amount (K)', Icons.money_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: taxRateController,
                    decoration: _dec('Tax Rate (%)', Icons.percent_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: calculateTax,
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Calculate Tax'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCashFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return FutureBuilder(
          future: _getCashFlowData(),
          builder: (context, snapshot) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Cash Flow Analysis', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!snapshot.hasData)
                    const Center(child: CircularProgressIndicator())
                  else
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _metricCard(
                                  'Cash In',
                                  'K ${snapshot.data!['cashIn']?.toStringAsFixed(2)}',
                                  Icons.arrow_downward,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _metricCard(
                                  'Cash Out',
                                  'K ${snapshot.data!['cashOut']?.toStringAsFixed(2)}',
                                  Icons.arrow_upward,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _metricCard(
                            'Net Cash Flow',
                            'K ${snapshot.data!['netFlow']?.toStringAsFixed(2)}',
                            Icons.trending_up,
                            snapshot.data!['netFlow']! >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Detailed cash flow tracking coming soon!\nThis will include expense categorization and forecasting.',
                                style: TextStyle(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, double>> _getCashFlowData() async {
    final sales = await _fetchSales();
    final totalRevenue = sales.fold<double>(0, (sum, sale) => sum + (sale.total ?? 0));
    
    // For now, assume 30% of revenue as expenses (this could be enhanced with actual expense tracking)
    final estimatedExpenses = totalRevenue * 0.3;
    
    return {
      'cashIn': totalRevenue,
      'cashOut': estimatedExpenses,
      'netFlow': totalRevenue - estimatedExpenses,
    };
  }

  void _showExpenseTracker() {
    final expenseController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Expense Tracker', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: expenseController,
                decoration: _dec('Amount (K)', Icons.money_outlined),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: _dec('Category (e.g., Rent, Supplies)', Icons.category_outlined),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: _dec('Description', Icons.description_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: bluePrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Get.snackbar('Coming Soon', 'Full expense tracking functionality will be added soon!');
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Expense'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Full expense tracking with categorization, reporting, and tax deduction calculations coming soon!',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInvoiceGenerator() {
    Get.snackbar(
      'Coming Soon',
      'Professional invoice generator with customizable templates, automatic numbering, and PDF export coming soon!',
      duration: const Duration(seconds: 4),
    );
  }

  void _showFinancialReports() {
    Get.snackbar(
      'Coming Soon',
      'Comprehensive financial reports including P&L statements, balance sheets, and key financial ratios coming soon!',
      duration: const Duration(seconds: 4),
    );
  }

  void _showBreakEvenAnalysis() {
    final fixedCostsController = TextEditingController();
    final variableCostController = TextEditingController();
    final sellingPriceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculateBreakEven() {
              final fixedCosts = double.tryParse(fixedCostsController.text) ?? 0;
              final variableCost = double.tryParse(variableCostController.text) ?? 0;
              final sellingPrice = double.tryParse(sellingPriceController.text) ?? 0;
              
              if (sellingPrice <= variableCost) {
                Get.snackbar('Error', 'Selling price must be higher than variable cost per unit');
                return;
              }

              final contributionMargin = sellingPrice - variableCost;
              final breakEvenUnits = fixedCosts / contributionMargin;
              final breakEvenRevenue = breakEvenUnits * sellingPrice;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Break-Even Analysis'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fixed Costs: K ${fixedCosts.toStringAsFixed(2)}'),
                      Text('Variable Cost per Unit: K ${variableCost.toStringAsFixed(2)}'),
                      Text('Selling Price per Unit: K ${sellingPrice.toStringAsFixed(2)}'),
                      const Divider(),
                      Text('Contribution Margin: K ${contributionMargin.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Break-Even Units: ${breakEvenUnits.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Break-Even Revenue: K ${breakEvenRevenue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Break-Even Analysis', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: fixedCostsController,
                    decoration: _dec('Fixed Costs (K)', Icons.home_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: variableCostController,
                    decoration: _dec('Variable Cost per Unit (K)', Icons.trending_down_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sellingPriceController,
                    decoration: _dec('Selling Price per Unit (K)', Icons.sell_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: calculateBreakEven,
                      icon: const Icon(Icons.balance_outlined),
                      label: const Text('Calculate Break-Even'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBudgetPlanner() {
    Get.snackbar(
      'Coming Soon',
      'Budget planning with income/expense forecasting, variance analysis, and budget vs actual reporting coming soon!',
      duration: const Duration(seconds: 4),
    );
  }

  void _showCurrencyConverter() {
    final amountController = TextEditingController();
    final fromCurrency = 'ZMW'.obs;
    final toCurrency = 'USD'.obs;
    final convertedAmount = 0.0.obs;

    // Sample exchange rates (in a real app, these would come from an API)
    final exchangeRates = {
      'ZMW_USD': 0.037,
      'ZMW_EUR': 0.034,
      'ZMW_GBP': 0.029,
      'USD_ZMW': 27.0,
      'EUR_ZMW': 29.5,
      'GBP_ZMW': 34.2,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void convertCurrency() {
              final amount = double.tryParse(amountController.text) ?? 0;
              final rateKey = '${fromCurrency.value}_${toCurrency.value}';
              final rate = exchangeRates[rateKey] ?? 1.0;
              convertedAmount.value = amount * rate;
              setState(() {});
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Currency Converter', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bluePrimary)
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    decoration: _dec('Amount', Icons.money_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: fromCurrency.value,
                          decoration: const InputDecoration(
                            labelText: 'From',
                            border: OutlineInputBorder(),
                          ),
                          items: ['ZMW', 'USD', 'EUR', 'GBP']
                              .map((currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            fromCurrency.value = value ?? 'ZMW';
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: toCurrency.value,
                          decoration: const InputDecoration(
                            labelText: 'To',
                            border: OutlineInputBorder(),
                          ),
                          items: ['ZMW', 'USD', 'EUR', 'GBP']
                              .map((currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            toCurrency.value = value ?? 'USD';
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: convertCurrency,
                      icon: const Icon(Icons.currency_exchange_outlined),
                      label: const Text('Convert'),
                    ),
                  ),
                  if (convertedAmount.value > 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Converted Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            '${convertedAmount.value.toStringAsFixed(2)} ${toCurrency.value}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Exchange rates are sample values. Use real-time rates for actual transactions.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _profitMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: bluePrimary),
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

  Widget _toolCard({required String title, required String description, required IconData icon, required VoidCallback onTap, Color? color}) {
    final c = color ?? bluePrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _generating ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.withOpacity(.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: c, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withOpacity(.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'OPEN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : width > 650 ? 3 : 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Tools'),
        backgroundColor: bluePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Get.snackbar('About', 'CashMate Business Tools v1.0.0'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bluePrimary.withOpacity(0.1), Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business, size: 32, color: bluePrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Tools & Analytics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: bluePrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage reports, analytics, and financial tools',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reports & Analytics Section
                _buildSectionHeader('Reports & Analytics', Icons.analytics_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _toolCard(
                      title: 'Sales Analytics',
                      description: 'View sales trends, best-selling items, and revenue insights.',
                      icon: Icons.trending_up_outlined,
                      color: Colors.green,
                      onTap: () => _showSalesAnalytics(),
                    ),
                    _toolCard(
                      title: 'Income Statement',
                      description: 'Generate & share revenue summary PDF.',
                      icon: Icons.analytics_outlined,
                      onTap: _printIncomeStatement,
                    ),
                    _toolCard(
                      title: 'Build Catalog',
                      description: 'Interactive product catalog builder PDF.',
                      icon: Icons.inventory_2_outlined,
                      onTap: _openCatalogBuilder,
                    ),
                    _toolCard(
                      title: 'Export Data',
                      description: 'Export sales & inventory as CSV files.',
                      icon: Icons.file_download_outlined,
                      onTap: _exportData,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Financial Tools Section
                _buildSectionHeader('Financial Tools', Icons.calculate_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _toolCard(
                      title: 'Profit Calculator',
                      description: 'Calculate profit margins and set optimal prices.',
                      icon: Icons.calculate_outlined,
                      color: Colors.orange,
                      onTap: () => _showProfitCalculator(),
                    ),
                    _toolCard(
                      title: 'Tax Calculator',
                      description: 'Calculate taxes and VAT for your business.',
                      icon: Icons.receipt_outlined,
                      color: Colors.indigo,
                      onTap: () => _showTaxCalculator(),
                    ),
                    _toolCard(
                      title: 'Break-even Analysis',
                      description: 'Calculate your break-even point.',
                      icon: Icons.balance_outlined,
                      color: Colors.cyan,
                      onTap: () => _showBreakEvenAnalysis(),
                    ),
                    _toolCard(
                      title: 'Currency Converter',
                      description: 'Convert currencies for international sales.',
                      icon: Icons.currency_exchange_outlined,
                      color: Colors.lightGreen,
                      onTap: () => _showCurrencyConverter(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Business Management Section
                _buildSectionHeader('Business Management', Icons.business_center_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _toolCard(
                      title: 'Cash Flow',
                      description: 'Track money in and out of your business.',
                      icon: Icons.trending_up_outlined,
                      color: Colors.teal,
                      onTap: () => _showCashFlow(),
                    ),
                    _toolCard(
                      title: 'Expense Tracker',
                      description: 'Track and categorize business expenses.',
                      icon: Icons.receipt_outlined,
                      color: Colors.brown,
                      onTap: () => _showExpenseTracker(),
                    ),
                    _toolCard(
                      title: 'Stock Alerts',
                      description: 'Set low stock alerts and reorder notifications.',
                      icon: Icons.notification_important_outlined,
                      color: Colors.red,
                      onTap: () => _showStockAlerts(),
                    ),
                    _toolCard(
                      title: 'Budget Planner',
                      description: 'Plan and track your business budget.',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.amber,
                      onTap: () => _showBudgetPlanner(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Coming Soon Section
                _buildSectionHeader('Coming Soon', Icons.upcoming_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _toolCard(
                      title: 'Invoice Generator',
                      description: 'Create professional invoices for customers.',
                      icon: Icons.description_outlined,
                      color: Colors.deepOrange,
                      onTap: () => _showInvoiceGenerator(),
                    ),
                    _toolCard(
                      title: 'Financial Reports',
                      description: 'Comprehensive financial statements and ratios.',
                      icon: Icons.assessment_outlined,
                      color: Colors.deepPurple,
                      onTap: () => _showFinancialReports(),
                    ),
                    _toolCard(
                      title: 'Customer List',
                      description: 'Manage customer information and purchase history.',
                      icon: Icons.people_outline,
                      color: Colors.purple,
                      onTap: () => _showCustomerList(),
                    ),
                    _toolCard(
                      title: 'Backup',
                      description: 'Backup local database (coming soon).',
                      icon: Icons.cloud_upload_outlined,
                      onTap: _backupData,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_generating)
            Container(
              color: Colors.black.withOpacity(.25),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: bluePrimary, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: bluePrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bluePrimary.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}class _CatalogPreviewPage extends StatelessWidget {
  final _CatalogDocResult result; // Updated type reference
  const _CatalogPreviewPage({required this.result});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog Preview')),
      body: PdfPreview(
        canChangePageFormat: false,
        canChangeOrientation: false,
        build: (format) async => result.doc.save(),
        initialPageFormat: pdf.PdfPageFormat.a4,
        pdfFileName: 'catalog_${result.timestamp.toIso8601String()}.pdf',
      ),
    );
  }
}