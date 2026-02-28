import 'dart:convert';
import 'dart:core';

import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePageTablet extends StatefulWidget {
  const HomePageTablet({super.key});

  @override
  State<HomePageTablet> createState() => _HomePageTabletState();
}

class _HomePageTabletState extends State<HomePageTablet> {
  final pc = Get.find<PageControllers>();
  Future<Map<String, dynamic>> salesSummary = Future.value(<String, dynamic>{});
  Config db = Get.find<Config>();

  Future<Map<String, dynamic>> getSalesSummary() async {
    return await db.getSalesSummary();
  }

  @override
  void initState() {
    super.initState();
    salesSummary = getSalesSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(216, 216, 251, 0.10196078431372549),
      appBar: AppBar(
        title: Text(
          "CashMate",
          style: TextStyle(
            color: bluePrimary,
            fontWeight: FontWeight.bold,
            fontSize: 36, // Larger font for tablet
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: FutureBuilder(
          future: getSalesSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.data == null) {
              return Center(child: Text('No sales data available'));
            } else {
              final salesSummary = snapshot.data!;
              String salesSummaryString = jsonEncode(salesSummary);

              return Padding(
                padding:
                    const EdgeInsets.all(16.0), // Increased padding for tablet
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards in a Row for tablet
                      Row(
                        children: [
                          Expanded(
                            child: buildSalesCard(context,
                                title: 'Total Items Sold',
                                data:
                                    salesSummary['total_items_sold'].toString(),
                                fontSize: 32, // Larger font
                                height: 150, // Taller cards
                                trailing: Icon(Icons.shopping_cart,
                                    size: 40)), // Larger icon
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: buildSalesCard(context,
                                backgroundColor:
                                    ColorScheme.fromSeed(seedColor: bluePrimary)
                                        .onSecondary,
                                title: 'Total Revenue',
                                data:
                                    "K ${salesSummary['total_sales'].toString()}",
                                fontSize: 32,
                                height: 150,
                                trailing:
                                    Icon(Icons.monetization_on, size: 40)),
                          ),
                        ],
                      ),

                      SizedBox(height: 24),

                      // Recent Transactions Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent Transactions",
                            style: TextStyle(
                                fontSize: 24, // Larger font
                                fontWeight: FontWeight.w700,
                                color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              pc.changePage(2);
                            },
                            child: Text(
                              'View More',
                              style: TextStyle(
                                color: bluePrimary,
                                fontSize: 20, // Larger font
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Table with larger dimensions
                      buildSalesTable(salesSummaryString),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget buildSalesTable(String salesSummaryString) {
    List<dynamic>? salesSummary =
        jsonDecode(salesSummaryString)['recent_sales'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
              columnWidths: {
                0: FixedColumnWidth(200), // Fixed widths for tablet
                1: FixedColumnWidth(250),
                2: FixedColumnWidth(200),
                3: FixedColumnWidth(150),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Table Header
                TableRow(
                  decoration: BoxDecoration(
                    color: ColorScheme.fromSeed(seedColor: Colors.blue)
                        .primaryContainer,
                  ),
                  children: [
                    tableHeader("Invoice ID", 20),
                    tableHeader("Date", 20),
                    tableHeader("Amount", 20),
                    tableHeader("Actions", 20),
                  ],
                ),
                // Data Rows
                if (salesSummary != null)
                  for (var record in salesSummary)
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      children: [
                        tableCell(record["id"].toString(), 18),
                        tableCell(record["date"], 18),
                        tableCell("\$${record["amount"]}", 18),
                        TableCell(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: IconButton(
                              icon: Icon(Icons.remove_red_eye,
                                  color: Colors.blue, size: 28), // Larger icon
                              onPressed: () {
                                // Action when view button is pressed
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget tableHeader(String text, double fontSize) {
    return Padding(
      padding: EdgeInsets.all(16.0), // More padding
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget tableCell(String text, double fontSize) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize),
        textAlign: TextAlign.center,
      ),
    );
  }
}

Widget buildSalesCard(BuildContext context,
    {required String title,
    required String data,
    required double fontSize,
    Color? backgroundColor,
    Widget? trailing,
    double height = 120}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: backgroundColor ?? Colors.white,
    child: Container(
      height: height, // Added height parameter for tablet version
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize * 0.6, // Slightly smaller than data
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                data,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    ),
  );
}
