import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cash_app/utils/color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Parse items_sold which can be Map, JSON string, or Dart toString() format
Map<String, dynamic> _parseItemsSold(dynamic itemsSold) {
  if (itemsSold == null) return {};

  // Already a Map (from new code path)
  if (itemsSold is Map) {
    final result = <String, dynamic>{};
    itemsSold.forEach((key, value) {
      result[key.toString()] =
          value is Map ? Map<String, dynamic>.from(value) : value;
    });
    return result;
  }

  // Not a string - can't parse
  if (itemsSold is! String || itemsSold.isEmpty) return {};

  // Try standard JSON decode first
  try {
    final decoded = jsonDecode(itemsSold);
    if (decoded is Map) {
      final result = <String, dynamic>{};
      decoded.forEach((key, value) {
        result[key.toString()] =
            value is Map ? Map<String, dynamic>.from(value) : value;
      });
      return result;
    }
  } catch (_) {}

  // Try parsing Dart's Map.toString() format: {0: {id: null, name: Foo, ...}, 1: {...}}
  try {
    return _parseDartMapString(itemsSold);
  } catch (_) {}

  return {};
}

/// Parse Dart's Map.toString() format into proper Map
Map<String, dynamic> _parseDartMapString(String input) {
  final result = <String, dynamic>{};

  // Remove outer braces and split by top-level entries
  input = input.trim();
  if (input.startsWith('{')) input = input.substring(1);
  if (input.endsWith('}')) input = input.substring(0, input.length - 1);

  // Find each numbered entry like "0: {...}, 1: {...}"
  final regex = RegExp(r'(\d+):\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}');
  final matches = regex.allMatches(input);

  for (final match in matches) {
    final key = match.group(1)!;
    final innerContent = match.group(2)!;

    // Parse inner map: "id: null, name: Foo, price: 100.0"
    final innerMap = <String, dynamic>{};
    final pairs = RegExp(r'(\w+):\s*([^,}]+(?=,|\s*$))');

    for (final pair in pairs.allMatches(innerContent)) {
      final fieldKey = pair.group(1)!;
      var fieldValue = pair.group(2)!.trim();

      // Convert value to appropriate type
      if (fieldValue == 'null') {
        innerMap[fieldKey] = null;
      } else if (double.tryParse(fieldValue) != null) {
        innerMap[fieldKey] = double.parse(fieldValue);
      } else if (int.tryParse(fieldValue) != null) {
        innerMap[fieldKey] = int.parse(fieldValue);
      } else {
        innerMap[fieldKey] = fieldValue;
      }
    }

    result[key] = innerMap;
  }

  return result;
}

class SalesHistory extends StatelessWidget {
  const SalesHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final data = _parseItemsSold(args["items_sold"]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color.fromARGB(90, 0, 0, 0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sale Information",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 25),
                              ),
                              Text(
                                "Details about the Sale",
                                style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                    color: Colors.grey),
                              )
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Sale ID",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          Text(args["id"].toString())
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Date",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          Text(convertToDate(args["date"].toString()))
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Payment Method",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          Text(args["transaction_type"].toString())
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Status",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      const Color.fromARGB(255, 237, 255, 246)),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8, top: 4, bottom: 4),
                                child: Center(
                                    child: Text(
                                  "Completed",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                )),
                              ))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Text(
                "Items Sold",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              ),
              SizedBox(
                height: 30,
              ),
              Expanded(
                child: DataTable2(
                    border: TableBorder(
                        right: BorderSide(width: 1, color: Colors.black),
                        top: BorderSide(width: 1, color: Colors.black),
                        left: BorderSide(width: 1, color: Colors.black),
                        bottom: BorderSide(width: 1, color: Colors.black),
                        borderRadius: BorderRadius.circular(12),
                        horizontalInside: BorderSide(
                          width: 1,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        )),
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 600,
                    columns: [
                      DataColumn2(
                        label: Text('Item Name'),
                        size: ColumnSize.L,
                      ),
                      DataColumn(
                        label: Text('Price'),
                      ),
                      DataColumn(
                        label: Text('Quantity'),
                      ),
                      DataColumn(
                        label: Text('Total'),
                      ),
                    ],
                    rows: List<DataRow>.generate(
                        data.length,
                        (index) => DataRow(cells: [
                              DataCell(Text(data["$index"]["name"])),
                              DataCell(
                                  Text(data["$index"]["price"].toString())),
                              DataCell(
                                  Text(data["$index"]["quantity"].toString())),
                              DataCell(Text((data["$index"]["price"] *
                                      data["$index"]["quantity"].toDouble())
                                  .toString())),
                            ]))),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
          left: 16,
          right: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bluePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Generate Receipt",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              onPressed: () async {
                try {
                  await generateReceipt(args);
                } catch (e) {
                  Get.showSnackbar(GetSnackBar(
                    message: e.toString(),
                  ));
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

String convertToDate(String date) {
  final dateTime = DateTime.tryParse(date);
  if (dateTime == null) return date;
  return "${dateTime.day}-${dateTime.month}-${dateTime.year}";
}

Future<void> generateReceipt(dynamic args) async {
  final doc = pw.Document();

  final font =
      await rootBundle.load("assets/fonts/OpenSans-VariableFont_wdth,wght.ttf");
  final ttf = pw.Font.ttf(font);

  final data = _parseItemsSold(args["items_sold"]);
  final items = data.values
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  double parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String formatCurrency(double value) => 'K ${value.toStringAsFixed(2)}';

  String formatDateTime(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }

  final total = parseAmount(args["amount"]) > 0
      ? parseAmount(args["amount"])
      : items.fold<double>(
          0,
          (sum, item) =>
              sum +
              (parseAmount(item["price"]) * parseAmount(item["quantity"])),
        );
  final saleId = args["id"]?.toString() ?? 'N/A';
  final paymentMethod = args["transaction_type"]?.toString() ?? 'N/A';
  final dateLabel = formatDateTime(args["date"]?.toString() ?? '');
  final receiptNumber = saleId == 'N/A' ? 'CashMate Receipt' : 'CM-$saleId';
  final accent = pdf.PdfColor.fromInt(bluePrimary.toARGB32());
  final accentSoft =
      pdf.PdfColor.fromInt(bluePrimary.withValues(alpha: 0.10).toARGB32());
  final lineColor = pdf.PdfColor.fromInt(const Color(0xFFD7DDE7).toARGB32());

  doc.addPage( 
    pw.Page(
      pageFormat: pdf.PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            color: pdf.PdfColors.white,
            borderRadius: pw.BorderRadius.circular(18),
            border: pw.Border.all(color: lineColor, width: 0.7),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'CASHMATE',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Sales Receipt',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accentSoft,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    children: [
                      _pdfMetaRow(ttf, 'Receipt No.', receiptNumber),
                      _pdfMetaRow(ttf, 'Sales ID', saleId),
                      _pdfMetaRow(ttf, 'Payment', paymentMethod),
                      _pdfMetaRow(ttf, 'Date', dateLabel),
                      _pdfMetaRow(ttf, 'Status', 'Completed', isLast: true),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'Items Sold',
                  style: pw.TextStyle(
                    font: ttf,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  border: pw.TableBorder(
                    horizontalInside:
                        pw.BorderSide(color: lineColor, width: 0.5),
                    top: pw.BorderSide(color: lineColor, width: 0.7),
                    bottom: pw.BorderSide(color: lineColor, width: 0.7),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: accentSoft),
                      children: [
                        _pdfTableCell(ttf, 'ITEM', isHeader: true),
                        _pdfTableCell(ttf, 'QTY', isHeader: true),
                        _pdfTableCell(ttf, 'PRICE', isHeader: true),
                        _pdfTableCell(ttf, 'TOTAL', isHeader: true),
                      ],
                    ),
                    ...items.map(
                      (item) {
                        final quantity = parseAmount(item["quantity"]);
                        final unitPrice = parseAmount(item["price"]);
                        final lineTotal = quantity * unitPrice;
                        return pw.TableRow(
                          children: [
                            _pdfTableCell(
                              ttf,
                              item["name"]?.toString() ?? 'Unknown Item',
                            ),
                            _pdfTableCell(
                              ttf,
                              quantity.toStringAsFixed(
                                  quantity.truncateToDouble() == quantity
                                      ? 0
                                      : 2),
                              alignRight: true,
                            ),
                            _pdfTableCell(
                              ttf,
                              formatCurrency(unitPrice),
                              alignRight: true,
                            ),
                            _pdfTableCell(
                              ttf,
                              formatCurrency(lineTotal),
                              alignRight: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.SizedBox(height: 18),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: accentSoft,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Column(
                      children: [
                        _pdfTotalRow(ttf, 'Subtotal', formatCurrency(total)),
                        _pdfTotalRow(ttf, 'TOTAL', formatCurrency(total),
                            emphasized: true),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for your purchase',
                        style: pw.TextStyle(
                          font: ttf,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Powered by CashMate',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: pdf.PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  final bytes = await doc.save();
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/cashmate_receipt_$saleId.pdf');
  await file.writeAsBytes(bytes, flush: true);

  await Printing.layoutPdf(
    onLayout: (_) async => bytes,
    name: 'cashmate_receipt_$saleId.pdf',
  );
}

pw.Widget _pdfMetaRow(
  pw.Font font,
  String label,
  String value, {
  bool isLast = false,
}) {
  return pw.Container(
    margin: isLast ? pw.EdgeInsets.zero : const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 10.5,
            color: pdf.PdfColors.grey700,
          ),
        ),
        pw.Spacer(),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _pdfTableCell(
  pw.Font font,
  String text, {
  bool isHeader = false,
  bool alignRight = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        font: font,
        fontSize: isHeader ? 10 : 10.5,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

pw.Widget _pdfTotalRow(
  pw.Font font,
  String label,
  String value, {
  bool emphasized = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: emphasized ? 12 : 10.5,
            fontWeight: emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Spacer(),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontSize: emphasized ? 12 : 10.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
