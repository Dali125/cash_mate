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
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';

class _CatalogDocResult {
  // Moved to top-level
  final pw.Document doc;
  final DateTime timestamp;
  _CatalogDocResult(this.doc, this.timestamp);
}

class _IncomeStatementData {
  final DateTime generatedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final int transactionCount;
  final int totalItemsSold;
  final double salesRevenue;
  final double? salesReturns;
  final double netSales;
  final double? costOfGoodsSold;
  final double? grossProfit;
  final double? operatingExpenses;
  final double? operatingIncome;
  final double? netIncome;
  final double averageTicketSize;
  final List<MapEntry<String, double>> paymentBreakdown;
  final List<Map<String, dynamic>> topItems;
  final List<String> notes;

  const _IncomeStatementData({
    required this.generatedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.transactionCount,
    required this.totalItemsSold,
    required this.salesRevenue,
    required this.salesReturns,
    required this.netSales,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.operatingIncome,
    required this.netIncome,
    required this.averageTicketSize,
    required this.paymentBreakdown,
    required this.topItems,
    required this.notes,
  });
}

class _CatalogInsights {
  final int productCount;
  final int totalUnits;
  final int lowStockCount;
  final int criticalStockCount;
  final double inventoryValue;
  final double averagePrice;

  const _CatalogInsights({
    required this.productCount,
    required this.totalUnits,
    required this.lowStockCount,
    required this.criticalStockCount,
    required this.inventoryValue,
    required this.averagePrice,
  });
}

class _ToolsOverviewData {
  final int totalProducts;
  final int lowStockCount;
  final int salesCount;
  final double totalRevenue;

  const _ToolsOverviewData({
    required this.totalProducts,
    required this.lowStockCount,
    required this.salesCount,
    required this.totalRevenue,
  });
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
  bool _includeDiscount = true;
  bool _includeCatalogSummary = true;
  bool _highlightLowStock = true;
  double _imageSize = 60;
  double _cardElevation = 2;
  Color _cardColor = Colors.white;
  int _columns = 2; // 2-4 columns supported
  String _sort = 'name_asc';
  double _borderRadius = 14;
  String _catalogLayout = 'editorial';
  String _catalogTitle = 'CashMate Product Catalog';
  String _catalogSubtitle =
      'Polished pricing and stock highlights for your customers.';
  Color _catalogAccent = const Color(0xFF1C64F2);

  pdf.PdfColor _pdfColor(Color c) => pdf.PdfColor.fromInt(c.toARGB32());

  Future<List<SalesModel>> _fetchSales() async {
    try {
      final raw = await db.getSalesHistory();
      if (raw == null) return [];
      return raw
          .map((m) => SalesModel(
                date: m['date'] as String?,
                total: (m['amount'] as num?)?.toDouble(),
                itemsSold: [], // not reconstructing detailed items from text blob
                transactionType: m['transaction_type'] as String?,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<_ToolsOverviewData> _loadToolsOverviewData() async {
    final inventory = await db.getInventory() ?? [];
    final sales = await db.getSalesHistory() ?? [];

    var lowStock = 0;
    for (final item in inventory) {
      if (_asInt(item['quantity']) <= 10) {
        lowStock++;
      }
    }

    var totalRevenue = 0.0;
    for (final sale in sales) {
      totalRevenue += _asDouble(sale['amount']);
    }

    return _ToolsOverviewData(
      totalProducts: inventory.length,
      lowStockCount: lowStock,
      salesCount: sales.length,
      totalRevenue: totalRevenue,
    );
  }

  Future<void> _printIncomeStatement() async {
    setState(() => _generating = true);
    try {
      final data = await _buildIncomeStatementData();
      final doc = pw.Document();
      final periodLabel = _periodLabel(data.periodStart, data.periodEnd);
      final money = NumberFormat.currency(
          locale: 'en_ZM', symbol: 'K ', decimalDigits: 2);
      final percent = NumberFormat.decimalPercentPattern(decimalDigits: 1);
      final generatedLabel =
          DateFormat('dd MMM yyyy HH:mm').format(data.generatedAt);

      pw.Widget lineItem(
        String label,
        String value, {
        bool isBold = false,
        bool isTotal = false,
        bool indent = false,
      }) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: pw.BoxDecoration(
            color: isTotal ? pdf.PdfColors.blue50 : pdf.PdfColors.white,
            border: pw.Border(
              bottom: pw.BorderSide(
                color: isTotal ? pdf.PdfColors.blue300 : pdf.PdfColors.grey300,
                width: isTotal ? 1.1 : 0.5,
              ),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  indent ? '   $label' : label,
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: (isBold || isTotal)
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: (isBold || isTotal)
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }

      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
            pageFormat: pdf.PdfPageFormat.a4,
          ),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: pdf.PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: pdf.PdfColors.blue200, width: 0.8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CashMate',
                      style: pw.TextStyle(
                          fontSize: 11, color: pdf.PdfColors.blue800)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Income Statement',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('For period: $periodLabel',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Generated on: $generatedLabel',
                      style: const pw.TextStyle(fontSize: 9.5)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Prepared from recorded sales activity only. Untracked accounts are shown as unavailable rather than estimated.',
                    style: const pw.TextStyle(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text('Revenue',
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            lineItem('Sales Revenue', money.format(data.salesRevenue)),
            lineItem(
              'Less: Sales Returns & Allowances',
              data.salesReturns == null
                  ? 'Not tracked'
                  : money.format(data.salesReturns),
              indent: true,
            ),
            lineItem('Net Sales', money.format(data.netSales), isTotal: true),
            pw.SizedBox(height: 12),
            pw.Text(
              'Cost of Goods Sold',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            lineItem(
              'COGS',
              data.costOfGoodsSold == null
                  ? 'Unavailable in current data'
                  : money.format(data.costOfGoodsSold),
              indent: true,
            ),
            lineItem(
              'Gross Profit',
              data.grossProfit == null
                  ? 'Unavailable in current data'
                  : money.format(data.grossProfit),
              isTotal: true,
            ),
            pw.SizedBox(height: 12),
            pw.Text('Operating Expenses',
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            lineItem(
              'Operating Expenses',
              data.operatingExpenses == null
                  ? 'Unavailable in current data'
                  : money.format(data.operatingExpenses),
              indent: true,
            ),
            lineItem(
              'Operating Income',
              data.operatingIncome == null
                  ? 'Unavailable in current data'
                  : money.format(data.operatingIncome),
              isTotal: true,
            ),
            lineItem(
              'Net Income',
              data.netIncome == null
                  ? 'Unavailable in current data'
                  : money.format(data.netIncome),
              isTotal: true,
              isBold: true,
            ),
            pw.SizedBox(height: 16),
            pw.Text('Key Metrics',
                style:
                    pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border:
                  pw.TableBorder.all(color: pdf.PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: pdf.PdfColors.grey200),
                  children: [
                    _pdfCell('Total Transactions', isHeader: true),
                    _pdfCell('Items Sold', isHeader: true),
                    _pdfCell('Average Ticket', isHeader: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('${data.transactionCount}'),
                    _pdfCell('${data.totalItemsSold}'),
                    _pdfCell(money.format(data.averageTicketSize)),
                  ],
                ),
              ],
            ),
            if (data.paymentBreakdown.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text('Revenue by Payment Method',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: pdf.PdfColors.grey200),
                cellAlignment: pw.Alignment.centerLeft,
                headers: const ['Payment Method', 'Revenue', '% of Sales'],
                data: data.paymentBreakdown
                    .map((e) => [
                          e.key,
                          money.format(e.value),
                          data.salesRevenue > 0
                              ? percent.format(e.value / data.salesRevenue)
                              : '0.0%',
                        ])
                    .toList(),
              ),
            ],
            if (data.topItems.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text('Top Selling Items',
                  style: pw.TextStyle(
                      fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: pdf.PdfColors.grey200),
                headers: const ['Item', 'Qty Sold', 'Revenue'],
                data: data.topItems.map((row) {
                  final name = row['item_name']?.toString() ?? 'Unknown';
                  final qty = _asInt(row['total_quantity']).toString();
                  final revenue = money.format(_asDouble(row['total_revenue']));
                  return [name, qty, revenue];
                }).toList(),
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pdf.PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(4),
                border:
                    pw.Border.all(color: pdf.PdfColors.amber200, width: 0.7),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Notes & Assumptions',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10.5)),
                  pw.SizedBox(height: 4),
                  for (int i = 0; i < data.notes.length; i++)
                    pw.Text(
                      '${i + 1}. ${data.notes[i]}',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                ],
              ),
            ),
          ],
          footer: (ctx) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey600),
            ),
          ),
        ),
      );

      await Printing.sharePdf(
        bytes: await doc.save(),
        filename:
            'income_statement_${DateFormat('yyyy-MM-dd_HH-mm').format(data.generatedAt)}.pdf',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate income statement: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<_IncomeStatementData> _buildIncomeStatementData() async {
    final sales = await db.getSalesHistory() ?? [];
    final allItems = await db.getAllItemsSold();
    final topItems = await db.getTopSellingItems(limit: 5);
    final generatedAt = DateTime.now();

    DateTime? periodStart;
    DateTime? periodEnd;
    final paymentRevenue = <String, double>{};

    double salesRevenue = 0;
    for (final row in sales) {
      final amount = _asDouble(row['amount']);
      salesRevenue += amount;

      final txTypeRaw = row['transaction_type']?.toString().trim();
      final txType =
          (txTypeRaw == null || txTypeRaw.isEmpty) ? 'Unspecified' : txTypeRaw;
      paymentRevenue[txType] = (paymentRevenue[txType] ?? 0) + amount;

      final date = DateTime.tryParse(row['date']?.toString() ?? '');
      if (date != null) {
        if (periodStart == null || date.isBefore(periodStart)) {
          periodStart = date;
        }
        if (periodEnd == null || date.isAfter(periodEnd)) {
          periodEnd = date;
        }
      }
    }

    int totalItemsSold = 0;
    for (final row in allItems) {
      totalItemsSold += _asInt(row['quantity']);
    }

    final netSales = salesRevenue;

    final sortedPayment = paymentRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _IncomeStatementData(
      generatedAt: generatedAt,
      periodStart: periodStart,
      periodEnd: periodEnd,
      transactionCount: sales.length,
      totalItemsSold: totalItemsSold,
      salesRevenue: salesRevenue,
      salesReturns: null,
      netSales: netSales,
      costOfGoodsSold: null,
      grossProfit: null,
      operatingExpenses: null,
      operatingIncome: null,
      netIncome: null,
      averageTicketSize: sales.isEmpty ? 0 : salesRevenue / sales.length,
      paymentBreakdown: sortedPayment,
      topItems: topItems,
      notes: const [
        'Sales revenue is based on recorded sale totals after any line-item discounts applied at checkout.',
        'Sales returns, allowances, cost of goods sold, and operating expenses are not stored separately in the current app data.',
        'Because those accounts are not tracked yet, gross profit, operating income, and net income are intentionally left unavailable instead of being estimated.',
      ],
    );
  }

  String _periodLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'No sales period available';
    final fmt = DateFormat('dd MMM yyyy');
    return '${fmt.format(start)} to ${fmt.format(end)}';
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  _CatalogInsights _catalogInsights(List<Map<String, dynamic>> inventory) {
    var totalUnits = 0;
    var lowStockCount = 0;
    var criticalStockCount = 0;
    var inventoryValue = 0.0;

    for (final item in inventory) {
      final quantity = _asInt(item['quantity']);
      final price = _asDouble(item['price']);
      totalUnits += quantity;
      inventoryValue += quantity * price;
      if (quantity <= 3) {
        criticalStockCount++;
      } else if (quantity <= 10) {
        lowStockCount++;
      }
    }

    return _CatalogInsights(
      productCount: inventory.length,
      totalUnits: totalUnits,
      lowStockCount: lowStockCount,
      criticalStockCount: criticalStockCount,
      inventoryValue: inventoryValue,
      averagePrice:
          inventory.isEmpty ? 0 : inventoryValue / totalUnits.clamp(1, 1 << 30),
    );
  }

  Future<_CatalogDocResult> _buildCatalogDocument() async {
    final rawInventory = await db.getInventory() ?? [];
    final businessProfile = await db.getBusinessProfile();
    final inventory = rawInventory
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
    inventory.sort((a, b) {
      switch (_sort) {
        case 'name_desc':
          return (b['name'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((a['name'] ?? '').toString().toLowerCase());
        case 'price_asc':
          return ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num);
        case 'price_desc':
          return ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num);
        case 'qty_asc':
          return ((a['quantity'] ?? 0) as num)
              .compareTo((b['quantity'] ?? 0) as num);
        case 'qty_desc':
          return ((b['quantity'] ?? 0) as num)
              .compareTo((a['quantity'] ?? 0) as num);
        case 'name_asc':
        default:
          return (a['name'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['name'] ?? '').toString().toLowerCase());
      }
    });

    final images = <int, pw.MemoryImage>{};
    if (_includeImages) {
      for (int i = 0; i < inventory.length; i++) {
        final p = inventory[i]['image_url']?.toString();
        if (p != null && p.isNotEmpty) {
          final file = File(p);
          if (await file.exists()) {
            try {
              images[i] = pw.MemoryImage(await file.readAsBytes());
            } catch (_) {}
          }
        }
      }
    }

    final money =
        NumberFormat.currency(locale: 'en_ZM', symbol: 'K ', decimalDigits: 2);
    final generatedLabel =
        DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
    final catalogTitle = _catalogTitle.trim().isEmpty
        ? 'CashMate Product Catalog'
        : _catalogTitle.trim();
    final catalogSubtitle = _catalogSubtitle.trim().isEmpty
        ? 'Polished pricing and stock highlights for your customers.'
        : _catalogSubtitle.trim();
    final insights = _catalogInsights(inventory);

    final doc = pw.Document();
    final now = DateTime.now();
    pw.MemoryImage? bgImage;
    if (_catalogBgImage != null) {
      try {
        final bgFile = File(_catalogBgImage!);
        if (await bgFile.exists()) {
          bgImage = pw.MemoryImage(await bgFile.readAsBytes());
        }
      } catch (_) {}
    }

    final pageTheme = pw.PageTheme(
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (ctx) => pw.Stack(
        children: [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _pdfColor(_catalogBg),
              gradient: pw.LinearGradient(
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
                colors: [
                  _pdfColor(_catalogBg),
                  _pdfColor(Color.lerp(_catalogBg, _catalogAccent, 0.12) ??
                      _catalogBg),
                ],
              ),
            ),
          ),
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

    pw.Widget insightTile(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: pdf.PdfColors.white,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(
              color: _pdfColor(Color.lerp(_catalogAccent, Colors.white, 0.65) ??
                  _catalogAccent),
              width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8.5,
                color: pdf.PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: _pdfColor(_catalogAccent),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget stockBadge(int quantity) {
      final bool critical = quantity <= 3;
      final bool low = quantity <= 10;
      final badgeColor = critical
          ? pdf.PdfColor.fromInt(appDanger.toARGB32())
          : low
              ? pdf.PdfColor.fromInt(appWarning.toARGB32())
              : pdf.PdfColor.fromInt(appSuccess.toARGB32());
      final badgeBg = critical
          ? pdf.PdfColor.fromInt(const Color(0xFFFDECEC).toARGB32())
          : low
              ? pdf.PdfColor.fromInt(const Color(0xFFFFF4DE).toARGB32())
              : pdf.PdfColor.fromInt(const Color(0xFFEAF8F1).toARGB32());

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          color: badgeBg,
          borderRadius: pw.BorderRadius.circular(20),
        ),
        child: pw.Text(
          critical
              ? 'Critical: $quantity left'
              : low
                  ? 'Low stock: $quantity left'
                  : 'In stock: $quantity',
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: badgeColor,
          ),
        ),
      );
    }

    pw.Widget itemCard(Map<String, dynamic> item, int index) {
      final name = (item['name'] ?? '').toString();
      final price = _asDouble(item['price']);
      final qty = _asInt(item['quantity']);
      final discount = _asDouble(item['discount']);
      final discountedPrice = price - ((discount / 100) * price);
      final hasImage = images[index] != null;
      final bool criticalStock = qty <= 3;
      final bool lowStock = qty <= 10;
      final accentTint = _pdfColor(
          Color.lerp(_catalogAccent, Colors.white, 0.82) ?? _catalogAccent);
      final placeholderTint = _pdfColor(
          Color.lerp(_catalogAccent, Colors.white, 0.9) ?? _catalogAccent);
      final trimmedName = name.trim();
      final placeholderLabel = trimmedName.isEmpty
          ? 'IT'
          : trimmedName
              .substring(0, trimmedName.length > 2 ? 2 : trimmedName.length)
              .toUpperCase();
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _pdfColor(_cardColor),
          borderRadius: pw.BorderRadius.circular(_borderRadius),
          border: pw.Border.all(
            color: lowStock && _highlightLowStock
                ? _pdfColor(criticalStock ? appDanger : appWarning)
                : _pdfColor(Colors.grey.shade300),
            width: lowStock && _highlightLowStock ? 1.1 : 0.6,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              height: 5,
              decoration: pw.BoxDecoration(
                color: _pdfColor(_catalogAccent),
                borderRadius: pw.BorderRadius.circular(30),
              ),
            ),
            pw.SizedBox(height: 10),
            if (_includeImages)
              pw.Container(
                width: double.infinity,
                height: _catalogLayout == 'editorial' ? 120 : 88,
                decoration: pw.BoxDecoration(
                  color: hasImage ? accentTint : placeholderTint,
                  borderRadius: pw.BorderRadius.circular(_borderRadius * 0.8),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: hasImage
                    ? pw.Center(
                        child: pw.ClipRRect(
                          horizontalRadius: 10,
                          verticalRadius: 10,
                          child: pw.Image(
                            images[index]!,
                            width: _imageSize *
                                (_catalogLayout == 'editorial' ? 1.5 : 1.0),
                            height: _imageSize *
                                (_catalogLayout == 'editorial' ? 1.5 : 1.0),
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      )
                    : pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            width: 44,
                            height: 44,
                            decoration: pw.BoxDecoration(
                              color: _pdfColor(_catalogAccent),
                              borderRadius: pw.BorderRadius.circular(14),
                            ),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              placeholderLabel,
                              style: pw.TextStyle(
                                color: pdf.PdfColors.white,
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'No product photo',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: _pdfColor(_catalogAccent),
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Catalog-ready placeholder',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: pdf.PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
              ),
            if (_includeImages) pw.SizedBox(height: 8),
            pw.Text(
              name,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              maxLines: 2,
            ),
            pw.SizedBox(height: 6),
            if (_includePrice)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    money.format(discount > 0 ? discountedPrice : price),
                    style: pw.TextStyle(
                      fontSize: _catalogLayout == 'editorial' ? 16 : 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfColor(_catalogAccent),
                    ),
                  ),
                  if (_includeDiscount && discount > 0) ...[
                    pw.SizedBox(width: 6),
                    pw.Text(
                      money.format(price),
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: pdf.PdfColors.grey600,
                        decoration: pw.TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            if (_includeDiscount && discount > 0) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                '${discount.toStringAsFixed(discount.truncateToDouble() == discount ? 0 : 1)}% off',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: pdf.PdfColor.fromInt(appSuccess.toARGB32()),
                ),
              ),
            ],
            if (_includeQuantity) ...[
              pw.SizedBox(height: 8),
              stockBadge(qty),
            ],
            if (!_includeQuantity && lowStock && _highlightLowStock) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                criticalStock ? 'Restock urgently' : 'Restock soon',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfColor(criticalStock ? appDanger : appWarning),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final rows = <pw.Widget>[
      pw.Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (int i = 0; i < inventory.length; i++)
            pw.SizedBox(
              width: (pdf.PdfPageFormat.a4.availableWidth -
                      ((_columns - 1) * 10) -
                      64) /
                  _columns,
              child: itemCard(inventory[i], i),
            ),
        ],
      ),
    ];

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12, left: 4, right: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: pdf.PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(
                      color: _pdfColor(
                          Color.lerp(_catalogAccent, Colors.white, 0.55) ??
                              _catalogAccent),
                      width: 0.9),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(10),
                          decoration: pw.BoxDecoration(
                            color: _pdfColor(_catalogAccent),
                            borderRadius: pw.BorderRadius.circular(14),
                          ),
                          child: pw.Text(
                            'CM',
                            style: pw.TextStyle(
                              color: pdf.PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                businessProfile['company_name']?.toString() ??
                                    'CashMate Business',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: _pdfColor(_catalogAccent),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                catalogTitle,
                                style: pw.TextStyle(
                                    fontSize: 22,
                                    fontWeight: pw.FontWeight.bold),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                catalogSubtitle,
                                style: pw.TextStyle(
                                    fontSize: 10.5,
                                    color: pdf.PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Generated',
                              style: pw.TextStyle(
                                  fontSize: 8.5, color: pdf.PdfColors.grey600),
                            ),
                            pw.Text(
                              generatedLabel,
                              style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_includeCatalogSummary) ...[
                      pw.SizedBox(height: 14),
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: insightTile(
                                  'Products', '${insights.productCount}')),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                              child: insightTile(
                                  'Units in stock', '${insights.totalUnits}')),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                              child: insightTile('Avg. price',
                                  money.format(insights.averagePrice))),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                              child: insightTile('Low stock',
                                  '${insights.lowStockCount + insights.criticalStockCount}')),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          if (inventory.isEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: pdf.PdfColors.white,
                borderRadius: pw.BorderRadius.circular(18),
              ),
              child: pw.Text(
                'No inventory items were found, so this catalog is empty.',
                style: pw.TextStyle(fontSize: 12, color: pdf.PdfColors.grey700),
              ),
            )
          else
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: pw.Column(children: rows),
            ),
        ],
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8, right: 4),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              '${businessProfile['company_name'] ?? 'CashMate Business'}  •  Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: pdf.PdfColors.grey700),
            ),
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
      await Printing.sharePdf(
          bytes: await result.doc.save(),
          filename: 'catalog_${result.timestamp.toIso8601String()}.pdf');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _openCatalogBuilder() {
    final titleController = TextEditingController(text: _catalogTitle);
    final subtitleController = TextEditingController(text: _catalogSubtitle);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            void update(VoidCallback fn) => setSheet(fn);
            final presets = <Color>[
              Colors.white,
              const Color(0xFFF5F6FA),
              Colors.blue.shade50,
              Colors.green.shade50,
              Colors.orange.shade50,
              Colors.purple.shade50,
              Colors.grey.shade200,
              Colors.black,
            ];
            final accentPresets = <Color>[
              bluePrimary,
              const Color(0xFF0F9D7A),
              const Color(0xFFF59F0B),
              const Color(0xFF8B5CF6),
              const Color(0xFFE25555),
            ];

            Widget panel(String title, Widget child) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: appBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: bluePrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    child,
                  ],
                ),
              );
            }

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Build Catalog',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (_generating)
                          const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a cleaner, sales-ready catalog with stronger branding, pricing hierarchy, and stock messaging.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    panel(
                      'Catalog identity',
                      Column(
                        children: [
                          TextField(
                            controller: titleController,
                            decoration:
                                _dec('Catalog title', Icons.title_outlined),
                            onChanged: (value) =>
                                update(() => _catalogTitle = value),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: subtitleController,
                            maxLines: 2,
                            decoration: _dec('Subtitle or selling message',
                                Icons.edit_note_outlined),
                            onChanged: (value) =>
                                update(() => _catalogSubtitle = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    panel(
                      'Visual system',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _labeled(
                            'Accent Color',
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: accentPresets.map((c) {
                                final selected =
                                    c.toARGB32() == _catalogAccent.toARGB32();
                                return GestureDetector(
                                  onTap: () => update(() => _catalogAccent = c),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: c,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: selected
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 18)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _labeled(
                            'Layout',
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'editorial',
                                  label: Text('Editorial'),
                                  icon:
                                      Icon(Icons.dashboard_customize_outlined),
                                ),
                                ButtonSegment<String>(
                                  value: 'compact',
                                  label: Text('Compact'),
                                  icon: Icon(Icons.grid_view_rounded),
                                ),
                              ],
                              selected: {_catalogLayout},
                              onSelectionChanged: (value) =>
                                  update(() => _catalogLayout = value.first),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    panel(
                      'Page styling',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Background Color',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
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
                                    border: Border.all(
                                        color: selected
                                            ? bluePrimary
                                            : Colors.grey.shade300,
                                        width: selected ? 2.5 : 1),
                                  ),
                                  child: selected
                                      ? Icon(Icons.check,
                                          size: 20,
                                          color: c == Colors.white
                                              ? Colors.black
                                              : Colors.white)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          _labeled(
                            'Background Image',
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _catalogBgImage != null
                                                ? 'Image selected'
                                                : 'No image selected',
                                            style: TextStyle(
                                              color: _catalogBgImage != null
                                                  ? Colors.green.shade600
                                                  : Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (_catalogBgImage != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear,
                                                size: 18),
                                            onPressed: () => update(
                                                () => _catalogBgImage = null),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bluePrimary,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    final mc = Get.find<MediaController>();
                                    final image = await mc.pickImage();
                                    if (image != null) {
                                      update(
                                          () => _catalogBgImage = image.path);
                                    }
                                  },
                                  icon: const Icon(Icons.image, size: 18),
                                  label: const Text('Choose'),
                                ),
                              ],
                            ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    panel(
                      'Product details',
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _optionSwitch('Images', _includeImages,
                                      (v) => update(() => _includeImages = v))),
                              Expanded(
                                  child: _optionSwitch('Price', _includePrice,
                                      (v) => update(() => _includePrice = v))),
                              Expanded(
                                  child: _optionSwitch(
                                      'Quantity',
                                      _includeQuantity,
                                      (v) =>
                                          update(() => _includeQuantity = v))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                  child: _optionSwitch(
                                      'Discounts',
                                      _includeDiscount,
                                      (v) =>
                                          update(() => _includeDiscount = v))),
                              Expanded(
                                  child: _optionSwitch(
                                      'Summary',
                                      _includeCatalogSummary,
                                      (v) => update(
                                          () => _includeCatalogSummary = v))),
                              Expanded(
                                  child: _optionSwitch(
                                      'Low stock',
                                      _highlightLowStock,
                                      (v) => update(
                                          () => _highlightLowStock = v))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _labeled(
                                  'Columns',
                                  DropdownButton<int>(
                                    value: _columns,
                                    isExpanded: true,
                                    items: [2, 3, 4]
                                        .map((c) => DropdownMenuItem(
                                            value: c, child: Text('$c')))
                                        .toList(),
                                    onChanged: (v) =>
                                        update(() => _columns = v ?? 2),
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
                                      DropdownMenuItem(
                                          value: 'name_asc',
                                          child: Text('Name A-Z')),
                                      DropdownMenuItem(
                                          value: 'name_desc',
                                          child: Text('Name Z-A')),
                                      DropdownMenuItem(
                                          value: 'price_asc',
                                          child: Text('Price Low-High')),
                                      DropdownMenuItem(
                                          value: 'price_desc',
                                          child: Text('Price High-Low')),
                                      DropdownMenuItem(
                                          value: 'qty_asc',
                                          child: Text('Qty Low-High')),
                                      DropdownMenuItem(
                                          value: 'qty_desc',
                                          child: Text('Qty High-Low')),
                                    ],
                                    onChanged: (v) =>
                                        update(() => _sort = v ?? 'name_asc'),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    panel(
                      'Card style',
                      Column(
                        children: [
                          _labeled(
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
                          const SizedBox(height: 8),
                          _labeled(
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
                                      border: Border.all(
                                          color: Colors.grey.shade300),
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
                                      ]
                                          .map((c) => DropdownMenuItem(
                                                value: c,
                                                child: Text(c == Colors.white
                                                    ? 'White'
                                                    : 'Soft tint'),
                                              ))
                                          .toList(),
                                      onChanged: (c) => update(
                                          () => _cardColor = c ?? Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _labeled(
                            'Card Elevation',
                            Slider(
                              value: _cardElevation,
                              min: 0,
                              max: 8,
                              divisions: 8,
                              label: _cardElevation.toInt().toString(),
                              onChanged: (v) =>
                                  update(() => _cardElevation = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _catalogAccent.withValues(alpha: 0.12),
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: appBorder),
                      ),
                      child: Text(
                        'Current setup: $_columns columns, ${_catalogLayout == 'editorial' ? 'larger showcase cards' : 'denser compact cards'}, ${_includeCatalogSummary ? 'summary header enabled' : 'summary header hidden'}.',
                        style: TextStyle(color: appMutedText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.grey.shade700,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _generating
                                ? null
                                : () async {
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
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: bluePrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _generating
                                ? null
                                : () async {
                                    Navigator.pop(ctx);
                                    await _generateCatalogPdf();
                                  },
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Generate'),
                          ),
                        ),
                      ],
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: bluePrimary,
        ),
      ],
    );
  }

  Widget _labeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
              final markup = cost > 0 ? ((price - cost) / cost) * 100 : 0;
              final target30 = cost / (1 - 0.30);
              final target40 = cost / (1 - 0.40);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profit Analysis'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profitMetric(
                          'Total Cost', 'K ${totalCost.toStringAsFixed(2)}'),
                      _profitMetric(
                          'Revenue', 'K ${revenue.toStringAsFixed(2)}'),
                      _profitMetric('Profit', 'K ${profit.toStringAsFixed(2)}'),
                      _profitMetric('Margin', '${margin.toStringAsFixed(1)}%'),
                      _profitMetric('Markup', '${markup.toStringAsFixed(1)}%'),
                      const Divider(),
                      _profitMetric('Price for 30% margin',
                          'K ${target30.toStringAsFixed(2)}'),
                      _profitMetric('Price for 40% margin',
                          'K ${target40.toStringAsFixed(2)}'),
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
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Profit Calculator',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bluePrimary)),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    decoration: _dec('Selling price (K)', Icons.sell_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder(
              future: db.getInventory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final inventory = (snapshot.data as List?)
                        ?.map((e) => Map<String, dynamic>.from(e))
                        .toList() ??
                    [];
                final lowStock = inventory.where((item) {
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                  return quantity < 10;
                }).toList()
                  ..sort((a, b) =>
                      _asInt(a['quantity']).compareTo(_asInt(b['quantity'])));
                final criticalStock = inventory.where((item) {
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                  return quantity <= 3;
                }).toList();
                final totalValueAtRisk = lowStock.fold<double>(
                  0,
                  (sum, item) =>
                      sum +
                      (_asDouble(item['price']) * _asInt(item['quantity'])),
                );

                return Container(
                  padding: const EdgeInsets.all(24),
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Stock Alerts',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: bluePrimary)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              'Critical',
                              '${criticalStock.length}',
                              Icons.error_outline,
                              appDanger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              'Low Stock',
                              '${lowStock.length}',
                              Icons.warning_amber_rounded,
                              appWarning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: appBorder),
                        ),
                        child: Text(
                          lowStock.isEmpty
                              ? 'Every item is above the low-stock threshold.'
                              : 'Stock value sitting in low-stock items: K ${totalValueAtRisk.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: appMutedText, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Items needing attention',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800)),
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
                                  final quantity =
                                      item['quantity'] as int? ?? 0;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ListTile(
                                      title:
                                          Text(item['name']?.toString() ?? ''),
                                      subtitle: Text(
                                        'Current stock: $quantity  •  Reorder target: ${quantity <= 3 ? 20 : 15}',
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: quantity < 5
                                              ? Colors.red.shade100
                                              : Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          quantity < 5 ? 'Critical' : 'Low',
                                          style: TextStyle(
                                            color: quantity < 5
                                                ? Colors.red.shade900
                                                : Colors.orange.shade900,
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: bluePrimary)),
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
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Customer management coming soon!',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Track customer information and purchase history',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
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
    final taxRateController =
        TextEditingController(text: '16'); // Default VAT rate

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
              final marginNeededToAbsorbTax =
                  amount == 0 ? 0.0 : (taxAmount / amount) * 100;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tax Calculation'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Base Amount: K ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Tax Rate: ${taxRate.toStringAsFixed(1)}%'),
                      const Divider(),
                      Text('Tax on Net: K ${taxAmount.toStringAsFixed(2)}'),
                      Text(
                          'Total with Tax: K ${totalWithTax.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Text('Net from Gross: K ${netAmount.toStringAsFixed(2)}'),
                      Text(
                          'Tax from Gross: K ${taxFromGross.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Text(
                          'Tax share of amount: ${marginNeededToAbsorbTax.toStringAsFixed(1)}%'),
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
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tax Calculator',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bluePrimary)),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: taxRateController,
                    decoration: _dec('Tax Rate (%)', Icons.percent_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return FutureBuilder(
          future: _getCashFlowData(),
          builder: (context, snapshot) {
            final sheetHeight = MediaQuery.of(context).size.height * 0.8;
            return Container(
              padding: const EdgeInsets.all(24),
              height: sheetHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Cash Flow Analysis',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bluePrimary)),
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
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final metricWidth =
                                    (constraints.maxWidth - 12) / 2;
                                final fullWidth = constraints.maxWidth;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 16,
                                  children: [
                                    SizedBox(
                                      width: metricWidth,
                                      child: _metricCard(
                                        'Cash In',
                                        'K ${snapshot.data!['cashIn']?.toStringAsFixed(2)}',
                                        Icons.arrow_downward,
                                        Colors.green,
                                      ),
                                    ),
                                    SizedBox(
                                      width: metricWidth,
                                      child: _metricCard(
                                        'Cash Out',
                                        'K ${snapshot.data!['cashOut']?.toStringAsFixed(2)}',
                                        Icons.arrow_upward,
                                        Colors.red,
                                      ),
                                    ),
                                    SizedBox(
                                      width: fullWidth,
                                      child: _metricCard(
                                        'Net Cash Flow',
                                        'K ${snapshot.data!['netFlow']?.toStringAsFixed(2)}',
                                        Icons.trending_up,
                                        snapshot.data!['netFlow']! >= 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    SizedBox(
                                      width: metricWidth,
                                      child: _metricCard(
                                        'Avg Sale',
                                        'K ${snapshot.data!['averageSale']?.toStringAsFixed(2)}',
                                        Icons.payments_outlined,
                                        bluePrimary,
                                      ),
                                    ),
                                    SizedBox(
                                      width: metricWidth,
                                      child: _metricCard(
                                        'This Month',
                                        'K ${snapshot.data!['monthlyRevenue']?.toStringAsFixed(2)}',
                                        Icons.calendar_month_outlined,
                                        Colors.teal,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: appBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Working insights',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${snapshot.data!['transactionCount']} sales recorded so far, with an estimated expense load of ${((snapshot.data!['expenseRatio'] as double) * 100).toStringAsFixed(0)}% of revenue.',
                                    style: TextStyle(color: appMutedText),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.data!['netFlow'] >= 0
                                        ? 'Cash is trending positive. Keep an eye on low-stock items so revenue stays healthy.'
                                        : 'Cash is trending negative. Review pricing, restocks, and operating costs closely.',
                                    style: TextStyle(
                                      color: snapshot.data!['netFlow'] >= 0
                                          ? appSuccess
                                          : appDanger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: sheetHeight < 620 ? 8 : 0),
                                ],
                              ),
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
      },
    );
  }

  Future<Map<String, dynamic>> _getCashFlowData() async {
    final sales = await _fetchSales();
    final totalRevenue =
        sales.fold<double>(0, (sum, sale) => sum + (sale.total ?? 0));
    final estimatedExpenses = totalRevenue * 0.3;
    final averageSale = sales.isEmpty ? 0.0 : totalRevenue / sales.length;
    final monthlyRevenue = sales.where((sale) {
      final parsed = DateTime.tryParse(sale.date ?? '');
      final now = DateTime.now();
      return parsed != null &&
          parsed.year == now.year &&
          parsed.month == now.month;
    }).fold<double>(0, (sum, sale) => sum + (sale.total ?? 0));

    return {
      'cashIn': totalRevenue,
      'cashOut': estimatedExpenses,
      'netFlow': totalRevenue - estimatedExpenses,
      'averageSale': averageSale,
      'monthlyRevenue': monthlyRevenue,
      'transactionCount': sales.length,
      'expenseRatio':
          totalRevenue == 0 ? 0.0 : estimatedExpenses / totalRevenue,
    };
  }

  void _showExpenseTracker() {
    final expenseController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Expense Tracker',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: bluePrimary)),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: _dec(
                    'Category (e.g., Rent, Supplies)', Icons.category_outlined),
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    final amount = double.tryParse(expenseController.text) ?? 0;
                    final category = categoryController.text.trim().isEmpty
                        ? 'Uncategorized'
                        : categoryController.text.trim();
                    final description = descriptionController.text.trim();
                    final monthlyEquivalent = amount * 4;
                    final annualEquivalent = amount * 52;

                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Expense Snapshot'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profitMetric('Category', category),
                            _profitMetric('One-time amount',
                                'K ${amount.toStringAsFixed(2)}'),
                            _profitMetric('Monthly equivalent',
                                'K ${monthlyEquivalent.toStringAsFixed(2)}'),
                            _profitMetric('Annual equivalent',
                                'K ${annualEquivalent.toStringAsFixed(2)}'),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(description,
                                  style:
                                      TextStyle(color: Colors.grey.shade700)),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Analyze Expense'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Use this to pressure-test regular spending and estimate what it does to monthly and annual cash flow.',
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculateBreakEven() {
              final fixedCosts =
                  double.tryParse(fixedCostsController.text) ?? 0;
              final variableCost =
                  double.tryParse(variableCostController.text) ?? 0;
              final sellingPrice =
                  double.tryParse(sellingPriceController.text) ?? 0;

              if (sellingPrice <= variableCost) {
                Get.snackbar('Error',
                    'Selling price must be higher than variable cost per unit');
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
                      Text(
                          'Variable Cost per Unit: K ${variableCost.toStringAsFixed(2)}'),
                      Text(
                          'Selling Price per Unit: K ${sellingPrice.toStringAsFixed(2)}'),
                      const Divider(),
                      Text(
                          'Contribution Margin: K ${contributionMargin.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          'Break-Even Units: ${breakEvenUnits.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          'Break-Even Revenue: K ${breakEvenRevenue.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Break-Even Analysis',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bluePrimary)),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: variableCostController,
                    decoration: _dec('Variable Cost per Unit (K)',
                        Icons.trending_down_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sellingPriceController,
                    decoration:
                        _dec('Selling Price per Unit (K)', Icons.sell_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
    final revenueController = TextEditingController();
    final essentialsController = TextEditingController();
    final growthController = TextEditingController();
    final cushionController = TextEditingController(text: '10');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void buildBudget() {
              final revenue = double.tryParse(revenueController.text) ?? 0;
              final essentials =
                  double.tryParse(essentialsController.text) ?? 0;
              final growth = double.tryParse(growthController.text) ?? 0;
              final cushionRate = double.tryParse(cushionController.text) ?? 0;
              final cushion = revenue * (cushionRate / 100);
              final remaining = revenue - essentials - growth - cushion;

              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Budget Plan'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profitMetric(
                          'Planned revenue', 'K ${revenue.toStringAsFixed(2)}'),
                      _profitMetric(
                          'Essentials', 'K ${essentials.toStringAsFixed(2)}'),
                      _profitMetric(
                          'Growth spend', 'K ${growth.toStringAsFixed(2)}'),
                      _profitMetric(
                          'Cash cushion', 'K ${cushion.toStringAsFixed(2)}'),
                      const Divider(),
                      _profitMetric('Remaining budget',
                          'K ${remaining.toStringAsFixed(2)}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Budget Planner',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bluePrimary)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: revenueController,
                    decoration:
                        _dec('Target revenue (K)', Icons.payments_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: essentialsController,
                    decoration:
                        _dec('Essential spend (K)', Icons.home_work_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: growthController,
                    decoration:
                        _dec('Growth budget (K)', Icons.rocket_launch_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cushionController,
                    decoration:
                        _dec('Cash cushion (%)', Icons.savings_outlined),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: bluePrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: buildBudget,
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Build Plan'),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Currency Converter',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bluePrimary)),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: fromCurrency.value,
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
                          initialValue: toCurrency.value,
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: appMutedText, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bluePrimary.withValues(alpha: .25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bluePrimary.withValues(alpha: .15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: bluePrimary, width: 1.4),
        ),
      );

  Widget _toolCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    String badge = 'Tool',
  }) {
    final c = color ?? bluePrimary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _generating ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: appSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
          border: Border.all(color: appBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Icon(icon, color: c, size: 28),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                    color: appMutedText,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: .08),
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
    final crossAxisCount = width > 900
        ? 4
        : width > 650
            ? 3
            : 2;
    final toolCardAspectRatio = width < 420
        ? 0.82
        : width < 650
            ? 0.88
            : 0.95;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Tools'),
        backgroundColor: Colors.white,
        foregroundColor: bluePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () =>
                Get.snackbar('About', 'CashMate Business Tools v1.0.0'),
          ),
        ],
      ),
      backgroundColor: appBackground,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bluePrimary, blueSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: bluePrimary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.business_center_outlined,
                            size: 32, color: Colors.white),
                      ),
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
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Reports, calculators, stock planning, and polished sales collateral in one place.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<_ToolsOverviewData>(
                  future: _loadToolsOverviewData(),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    return Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            'Products',
                            '${data?.totalProducts ?? 0}',
                            Icons.inventory_2_outlined,
                            bluePrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            'Low Stock',
                            '${data?.lowStockCount ?? 0}',
                            Icons.warning_amber_rounded,
                            appWarning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            'Revenue',
                            'K ${(data?.totalRevenue ?? 0).toStringAsFixed(0)}',
                            Icons.payments_outlined,
                            appSuccess,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                    'Reports & Analytics', Icons.analytics_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: toolCardAspectRatio,
                  children: [
                    _toolCard(
                      title: 'Sales Analytics',
                      description:
                          'View sales trends, best-selling items, and revenue insights.',
                      icon: Icons.trending_up_outlined,
                      color: Colors.green,
                      badge: 'Insights',
                      onTap: () => _showSalesAnalytics(),
                    ),
                    _toolCard(
                      title: 'Income Statement',
                      description:
                          'Generate a professional P&L with revenue, COGS, expenses, and net income.',
                      icon: Icons.analytics_outlined,
                      badge: 'Report',
                      onTap: _printIncomeStatement,
                    ),
                    _toolCard(
                      title: 'Build Catalog',
                      description:
                          'Build a cleaner branded catalog with summary metrics, discounts, and stock-aware product cards.',
                      icon: Icons.inventory_2_outlined,
                      badge: 'Catalog',
                      onTap: _openCatalogBuilder,
                    ),
                    _toolCard(
                      title: 'Export Data',
                      description: 'Export sales & inventory as CSV files.',
                      icon: Icons.file_download_outlined,
                      badge: 'Export',
                      onTap: _exportData,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                    'Financial Tools', Icons.calculate_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: toolCardAspectRatio,
                  children: [
                    _toolCard(
                      title: 'Profit Calculator',
                      description:
                          'Calculate profit margins and set optimal prices.',
                      icon: Icons.calculate_outlined,
                      color: Colors.orange,
                      badge: 'Pricing',
                      onTap: () => _showProfitCalculator(),
                    ),
                    _toolCard(
                      title: 'Tax Calculator',
                      description: 'Calculate taxes and VAT for your business.',
                      icon: Icons.receipt_outlined,
                      color: Colors.indigo,
                      badge: 'Tax',
                      onTap: () => _showTaxCalculator(),
                    ),
                    _toolCard(
                      title: 'Break-even Analysis',
                      description: 'Calculate your break-even point.',
                      icon: Icons.balance_outlined,
                      color: Colors.cyan,
                      badge: 'Planning',
                      onTap: () => _showBreakEvenAnalysis(),
                    ),
                    _toolCard(
                      title: 'Currency Converter',
                      description:
                          'Convert currencies for international sales.',
                      icon: Icons.currency_exchange_outlined,
                      color: Colors.lightGreen,
                      badge: 'Rates',
                      onTap: () => _showCurrencyConverter(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                    'Business Management', Icons.business_center_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: toolCardAspectRatio,
                  children: [
                    _toolCard(
                      title: 'Cash Flow',
                      description: 'Track money in and out of your business.',
                      icon: Icons.trending_up_outlined,
                      color: Colors.teal,
                      badge: 'Flow',
                      onTap: () => _showCashFlow(),
                    ),
                    _toolCard(
                      title: 'Expense Tracker',
                      description:
                          'Analyze expense impact and estimate what recurring spend does to your cash position.',
                      icon: Icons.receipt_outlined,
                      color: Colors.brown,
                      badge: 'Cost',
                      onTap: () => _showExpenseTracker(),
                    ),
                    _toolCard(
                      title: 'Stock Alerts',
                      description:
                          'Review critical stock risks, reorder targets, and value tied up in low inventory.',
                      icon: Icons.notification_important_outlined,
                      color: Colors.red,
                      badge: 'Stock',
                      onTap: () => _showStockAlerts(),
                    ),
                    _toolCard(
                      title: 'Budget Planner',
                      description:
                          'Build a simple revenue, spend, growth, and safety-cushion plan.',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.amber,
                      badge: 'Budget',
                      onTap: () => _showBudgetPlanner(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Growth Tools', Icons.upcoming_outlined),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: toolCardAspectRatio,
                  children: [
                    _toolCard(
                      title: 'Invoice Generator',
                      description:
                          'Create professional invoices for customers.',
                      icon: Icons.description_outlined,
                      color: Colors.deepOrange,
                      badge: 'Next up',
                      onTap: () => _showInvoiceGenerator(),
                    ),
                    _toolCard(
                      title: 'Financial Reports',
                      description:
                          'Comprehensive financial statements and ratios.',
                      icon: Icons.assessment_outlined,
                      color: Colors.deepPurple,
                      badge: 'Next up',
                      onTap: () => _showFinancialReports(),
                    ),
                    _toolCard(
                      title: 'Customer List',
                      description:
                          'Manage customer information and purchase history.',
                      icon: Icons.people_outline,
                      color: Colors.purple,
                      badge: 'Next up',
                      onTap: () => _showCustomerList(),
                    ),
                    _toolCard(
                      title: 'Backup',
                      description: 'Backup local database (coming soon).',
                      icon: Icons.cloud_upload_outlined,
                      badge: 'Next up',
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
              color: Colors.black.withValues(alpha: .25),
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
                colors: [
                  bluePrimary.withValues(alpha: 0.25),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogPreviewPage extends StatelessWidget {
  final _CatalogDocResult result;
  const _CatalogPreviewPage({required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: const Text('Catalog Preview'),
        backgroundColor: Colors.white,
        foregroundColor: bluePrimary,
      ),
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
