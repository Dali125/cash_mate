import 'package:cash_app/ui/components/pages/add_inventory.dart';
import 'package:cash_app/ui/components/pages/edit_inventory.dart';
import 'package:cash_app/ui/components/pages/inventory_item_overview.dart';
import 'package:cash_app/ui/components/pages/inventory_page.dart';
import 'package:cash_app/ui/components/pages/root.dart';
import 'package:cash_app/ui/components/pages/sales_page.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/transaction_complete_page.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CashAp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: bluePrimary),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const RootPage(),
        '/inventory': (context) => const InventoryPage(),
        '/add_inventory': (context) => const AddInventoryPage(),
        '/sales': (context) => SalesPage(),
        '/edit-inventory': (context) => const EditInventoryPage(),
        '/inventory-item-overview': (context) => InventoryItemOverview(),
        '/inventory-tablet': (context) => const InventoryPageTablet(),
        '/add-inventory-tablet': (context) => const AddInventoryPage(),
        '/transaction_complete': (context) => TransactionCompletePage(),
      },
    );
  }
}
