import 'dart:io';

import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesPageTablet extends StatefulWidget {
  const SalesPageTablet({super.key});

  @override
  State<SalesPageTablet> createState() => _SalesPageTabletState();
}

class _SalesPageTabletState extends State<SalesPageTablet> {
  final CartController cartController = Get.put(CartController());
  final db = Get.find<Config>();
  final deviceProperties = DeviceProperties();
  final _searchController = TextEditingController();
  List<int> stockQuantities = [];

  @override
  Widget build(BuildContext context) {
    final bool isTablet = deviceProperties.isTablet(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current Sale',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        
        backgroundColor: bluePrimary,
        leading: IconButton(onPressed: (){
          Get.back();
        }, icon: Icon(Icons.arrow_back)),
      ),
      body: Container(
        height: DeviceProperties().getHeight(context),
        width: DeviceProperties().getWidth(context),
        color: Colors.white,
        child: Center(
          child: Text("Still not optimised For larger Devices"),
        )
      )
      
      
    
    );
  }
}
