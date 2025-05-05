import 'dart:developer';

import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cashcontroller = TextEditingController();
    final args = Get.arguments;
    log(args.toString(), time: DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text("Paymnents"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Container(
              width: DeviceProperties().getWidth(context),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(4)),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      "Total Amount Expected",
                      style: TextStyle(fontSize: 24),
                    ),
                    Text(
                      "K ${args.total}",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Please Choose the customers payment Method",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
                child: GridView(
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
              children: [
                GridTile(
                    child: Material(
                  child: InkWell(
                    onTap: () async {
                      try {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 1,
                                maxChildSize: 1,
                                builder: (context, controller) {
                                  return Padding(
                                    padding: const EdgeInsets.all(14.0),
                                    child: Container(
                                      height:
                                          DeviceProperties().getHeight(context),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Cash Payment",
                                              style: TextStyle(
                                                  fontSize: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.fontSize,
                                                  fontWeight: FontWeight.bold)),
                                          Text("Enter Amount",
                                              style: TextStyle(
                                                  fontSize: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.fontSize,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          TextField(
                                            keyboardType: TextInputType.number,
                                            controller: cashcontroller,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              hintText: "Enter Amount Received",
                                            ),
                                          ),
                                          Expanded(child: Container()),
                                          Button(
                                            width: DeviceProperties()
                                                .getWidth(context),
                                            height: 60,
                                            color: bluePrimary,
                                            text: 'Proceed',
                                            onPressed: () {
                                              Map<String, dynamic> values = {
                                                "sales": args,
                                                "transaction_type": "Cash",
                                                "amount paid":
                                                    cashcontroller.text.trim()
                                              };

                                              Get.toNamed(
                                                  "/transaction_complete",
                                                  arguments: values);
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }));
                      } catch (e) {
                        Get.showSnackbar(GetSnackBar(
                          message: e.toString(),
                        ));
                      }
                    },
                    child: Card(
                      child: Container(
                        child: Column(
                          children: [
                            Expanded(
                                child: Image.asset(
                              "assets/money.png",
                              height: 50,
                            )),
                            Text(
                              "Cash",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
                GridTile(
                    child: Material(
                  child: InkWell(
                    onTap: () async {
                      await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Continue Transaction?"),
                              content: Text(
                                  "Change is not allowed for mobile money"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Map<String, dynamic> values  = {
                                        "transaction_type": "Mobile Money",
                                        "sales": args,
                                        "amount paid": args.total.toString()
                                      };

                                      Get.toNamed("/transaction_complete",
                                          arguments: values);
                                    },
                                    child: Text("Yes")),
                                TextButton(
                                    onPressed: () {
                                      Get.back();
                                    },
                                    child: Text("No"))
                              ],
                            );
                          });
                    },
                    child: Card(
                      child: Column(
                        children: [
                          Expanded(
                              child: Image.asset(
                            "assets/mobile_money.png",
                            height: 50,
                          )),
                          Text(
                            "Mobile Money",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                )),
                GridTile(
                    child: Card(
                  child: Container(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            "assets/debt.png",
                            height: 50,
                          ),
                        ),
                        Text("Nkongole",
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                )),
              ],
            ))
          ],
        ),
      ),
    );
  }
}
