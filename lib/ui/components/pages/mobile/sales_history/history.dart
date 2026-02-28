import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
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

    print(data);

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
              color: Colors.black.withOpacity(0.1),
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
                  await GenerateReceipt(args);
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
  DateTime dateTime = DateTime.parse(date);
  return "${dateTime.day}-${dateTime.month}-${dateTime.year}";
}

Future<void> GenerateReceipt(dynamic args) async {
  final doc = pw.Document();

  final font =
      await rootBundle.load("assets/fonts/OpenSans-VariableFont_wdth,wght.ttf");
  final ttf = pw.Font.ttf(font);

  final data = _parseItemsSold(args["items_sold"]);

  double total = 0;
  final items = data.values.toList();

  for (final item in items) {
    total += (item["price"] * item["quantity"]);
  }

  doc.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text("RECEIPT",
                  style: pw.TextStyle(
                      font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 28)),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Sales ID: ${args["id"]}",
                style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.Text("Date: ${convertToDate(args["date"])}",
                style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.Text("Payment Method: ${args["transaction_type"]}",
                style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.Text("Status: Complete",
                style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text("Items Sold",
                style: pw.TextStyle(
                    font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Divider(),
            pw.Table.fromTextArray(
              cellStyle: pw.TextStyle(font: ttf),
              headerStyle:
                  pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
              headers: ["Item", "Qty", "Unit Price", "Subtotal"],
              data: items.map((item) {
                return [
                  item["name"],
                  "${item["quantity"]}",
                  "${item["price"]}",
                  "${item["quantity"] * item["price"]}"
                ];
              }).toList(),
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("Total: K$total",
                  style: pw.TextStyle(
                      font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 18)),
            ),
          ],
        );
      },
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File('${output.path}/receipt.pdf');
  await file.writeAsBytes(await doc.save());

  await Printing.sharePdf(bytes: await doc.save(), filename: 'my-document.pdf');
}
