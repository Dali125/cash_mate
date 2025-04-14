import 'dart:convert';
import 'dart:core';

import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';

import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../saleCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pc = Get.find<PageControllers>();
  Future<Map<String, dynamic>> salesSummary =
      Future.value(Map<String, dynamic>());
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
              fontSize: 30,
            ),
          ),
        ),
        body: FutureBuilder(
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
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Material(
                          shadowColor: Colors.black12,
                          elevation: 200,
                          child: Container(
                            width: DeviceProperties().getWidth(context),
                            height: 200,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(
                          height: 20
                        ),


                        Container(
                          width: DeviceProperties().getWidth(context),
                          height: DeviceProperties().getHeight(context) /4,

                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [

                              buildSalesCard(context,
                                  title: 'Total Items Sold',
                                  data: salesSummary['total_items_sold'].toString(),
                                  fontSize: 30,
                                  trailing: Icon(Icons.money)),

                              buildSalesCard(context,
                                  backgroundColor:
                                  ColorScheme.fromSeed(seedColor: bluePrimary)
                                      .onSecondary,
                                  title: 'Total Revenue',
                                  data: salesSummary['total_sales'].toString() ==
                                      'null'
                                      ? '0.0'
                                      : 'K ${salesSummary['total_sales'].toString()}',
                                  fontSize: 30,
                                  trailing: Icon(Icons.money)),

                            ],
                          ),
                            

                        ),





                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Recent Transactions",
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        buildSalesTable(salesSummaryString),
                      ],
                    ),
                  ),
                );
              }
            }));
  }

  Widget buildSalesTable(String salesSummaryString) {
    // Decode JSON string
    List<dynamic>? salesSummary =
        jsonDecode(salesSummaryString)['recent_sales'];

    if (salesSummary == null) {
      return const Center(
        child: Text('No recent sales available'),
      );
    } else {
      return Table(
        border: TableBorder.all(color: Colors.black),
        columnWidths: {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          // Table Header
          TableRow(
            decoration: BoxDecoration(
              color:
                  ColorScheme.fromSeed(seedColor: Colors.blue).primaryContainer,
            ),
            children: [
              tableHeader("Invoice ID"),
              tableHeader("Date"),
              tableHeader("Amount"),
              tableHeader("Actions"),
            ],
          ),
          // Data Rows
          for (var record in salesSummary)
            TableRow(children: [
              tableCell(record["id"].toString()),
              tableCell(record["date"]),
              tableCell("K${record["amount"]}"),
              TableCell(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: IconButton(
                    icon: Icon(Icons.remove_red_eye, color: Colors.blue),
                    onPressed: () {
                      // Action when view button is pressed
                    },
                  ),
                ),
              ),
            ]),
        ],
      );
    }
  }

  // Helper function for table header
  Widget tableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper function for table cell
  Widget tableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}
