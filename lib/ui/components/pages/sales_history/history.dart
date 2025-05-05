import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesHistory extends StatelessWidget {
  const SalesHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;

    String input = args["items_sold"];

     // Step 1: Replace '=' with ':'
  input = input.replaceAll('=', ':');

  // Step 2: Add quotes around keys
  input = input.replaceAllMapped(RegExp(r'(?<=[{,])\s*(\w+)\s*:'), (match) {
    return '"${match.group(1)}":';
  });

  // Step 3: Add quotes around string values (words that are not numbers)
  input = input.replaceAllMapped(RegExp(r':\s*([^,\d{][^,}]*)'), (match) {
    return ': "${match.group(1)!.trim()}"';
  });

  // Now it looks like real JSON, so decode it
  Map<String, dynamic> data = jsonDecode(input);
  

  

  print(data);
    

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(238, 238, 230, 0.4),
        title: const Text('Sales History'),
      ),
      body: Padding(
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
                            Text("Sale Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),
                            Text("Details about the Sale", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: Colors.grey),)
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
                      children: [Text("Sale ID", 
                      style: TextStyle(fontWeight: FontWeight.bold,)
                      ), Text(args["id"].toString())],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Date",style: TextStyle(fontWeight: FontWeight.bold,)),
                        Text(convertToDate(args["date"].toString()))
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Payment Method",style: TextStyle(fontWeight: FontWeight.bold,)),
                        Text(args["transaction_type"].toString())
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Status",style: TextStyle(fontWeight: FontWeight.bold,)),
                        Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color.fromARGB(255, 237, 255, 246)),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0, right: 8, top: 4, bottom: 4),
                              child: Center(
                                  child: Text(
                                "Completed",
                                style: TextStyle(
                                    color: Colors.green, fontWeight: FontWeight.bold),
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

          Text("Items Sold", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),),

          SizedBox(
            height: 30,
          ),
          Expanded(
            child:  DataTable2(
              border: TableBorder(
                right: BorderSide(width: 1, color: Colors.black),
                top: BorderSide(width: 1, color: Colors.black),
                left:BorderSide(width: 1, color: Colors.black),
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
                  DataCell(Text(data["${index}"]["name"])),
                  DataCell(Text(data["${index}"]["price"].toString())),
                  DataCell(Text(data["${index}"]["quantity"].toString())),
                  
                  DataCell(Text((data["${index}"]["price"] * data["${index}"]["quantity"].toDouble()).toString())),
                ]))),
          
      
          ),
      
         
          
          ],
        ),
      ),
      bottomSheet: Container(
        width: DeviceProperties().getWidth(context),
        height: DeviceProperties().getHeight(context)/10,
        color: Colors.amber,
        child: Button(width: DeviceProperties().getWidth(context), height: DeviceProperties().getHeight(context)/10, color: bluePrimary, text: "Share Receipt", onPressed: () async{


try{
          await GenerateReceipt(args);
}catch(e){
  Get.showSnackbar(GetSnackBar(message: e.toString(),));
}
        })
        
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

  final font = await rootBundle.load("assets/fonts/OpenSans-VariableFont_wdth,wght.ttf");
  final ttf = pw.Font.ttf(font);

  String input = args["items_sold"];

  // Convert pseudo-JSON string to valid JSON
  input = input.replaceAll('=', ':');
  input = input.replaceAllMapped(RegExp(r'(?<=[{,])\s*(\w+)\s*:'), (m) => '"${m.group(1)}":');
  input = input.replaceAllMapped(RegExp(r':\s*([^,\d{][^,}]*)'), (m) => ': "${m.group(1)!.trim()}"');

  Map<String, dynamic> data;
  try {
    data = jsonDecode(input);
  } catch (e) {
    print("Error decoding items_sold: $e");
    return;
  }

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
              child: pw.Text("RECEIPT", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 28)),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Sales ID: ${args["id"]}", style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.Text("Date: ${convertToDate(args["date"])}", style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.Text("Payment Method: ${args["transaction_type"]}", style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.Text("Status: Complete", style: pw.TextStyle(font: ttf, fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text("Items Sold", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 20)),
            pw.Divider(),
            pw.Table.fromTextArray(
              cellStyle: pw.TextStyle(font: ttf),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
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
              child: pw.Text("Total: K$total", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 18)),
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
