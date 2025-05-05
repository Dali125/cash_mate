import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';

import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



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
    await db.updateNumberOfLogins();
    return await db.getSalesSummary();
  }
  List colors = [Colors.lightBlueAccent, Colors.red];

  @override
  void initState() {
    super.initState();
    salesSummary = getSalesSummary();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth / 2) - 24; // 2 cards per row with padding
   

    return Scaffold(
      backgroundColor: const Color.fromRGBO(238, 238, 230, 0.4),
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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null) {
            return const Center(child: Text('No sales data available'));
          } else {
            final salesSummary = snapshot.data!;
            String salesSummaryString = jsonEncode(salesSummary);

            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        summaryCard(cardWidth, salesSummary["sales_today"].toString(), "Sales Made Today", Icon(Icons.money)),
                        summaryCard(cardWidth, "K ${salesSummary["today_revenue"]}" , "Todays Revenue", Icon(Icons.money)),
                        
                        summaryCard(cardWidth, salesSummary["alltime_sales"].toString(), "Alltime Sales", Icon(Icons.money)),
                        summaryCard(cardWidth, "K ${salesSummary["total_sales"]}", "Alltime Revenue", Icon(Icons.money)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    Material(
                      elevation: 2,
                      child: Container(
                        width: DeviceProperties().getWidth(context),
                        height: DeviceProperties().getHeight(context)/ 3,
                    
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Recent Transactions",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: bluePrimary,
                                    ),
                    
                                  ),
                                  TextButton(onPressed: (){}, child: Text("More"))
                                ],
                              )
                            ),
                            Expanded(child: buildSalesTable(salesSummaryString)),
                    
                    
                          ],
                        ),
                      ),
                    ),



                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget summaryCard(double width, String value, String label, Icon? icon) {
    List<int> numbers = [0,1,2];
    List color = [Colors.red, Colors.greenAccent, Colors.purpleAccent];
    Random random = Random();

    int randomNumber = numbers[random.nextInt(numbers.length)];
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(11.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 40,
                width: 40,
                child: Center(
                  child: icon,
                ),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: color[randomNumber]
                ),
              ),
              const SizedBox(height: 14),
              Text(label, style: TextStyle(fontWeight: FontWeight.w200, fontSize: 14)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              Text(label, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
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
                  Colors.blueGrey,
            ),
            children: [
              tableHeader("Invoice ID"),
              tableHeader("Date"),
              tableHeader("Amount"),

            ],
          ),
          // Data Rows
          for (var record in salesSummary)
            TableRow(children: [
              tableCell(record["id"].toString()),
              tableCell(record["date"]),
              tableCell("K${record["amount"]}"),

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
