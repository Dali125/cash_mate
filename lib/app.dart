import 'package:cash_app/db/config.dart';
import 'package:cash_app/ui/components/pages/add_inventory.dart';
import 'package:cash_app/ui/components/pages/edit_inventory.dart';
import 'package:cash_app/ui/components/pages/inventory_item_overview.dart';
import 'package:cash_app/ui/components/pages/inventory_page.dart';
import 'package:cash_app/ui/components/pages/payments/payment_page.dart';
import 'package:cash_app/ui/components/pages/root.dart';
import 'package:cash_app/ui/components/pages/sales_history/history.dart';
import 'package:cash_app/ui/components/pages/sales_page.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/transaction_complete_page.dart';
import 'package:cash_app/utils/color.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';


import 'ui/components/pages/onboarding/welcome_screens.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<Config>()) {
      Get.put(Config());
    }
    final db = Get.find<Config>();
    return FutureBuilder<int>(
      future: db.getNumberOfLogins(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final logins = snapshot.data ?? 0;
        final initial = logins > 0 ? '/' : '/welcome_screens';
        
        return GetMaterialApp(
          title: 'CashApp',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: bluePrimary),
          ),
          initialRoute: initial,
          routes: {
            '/': (context) => const RootPage(),
            '/welcome_screens': (context) => const WelcomeScreens(),
            '/inventory': (context) => const InventoryPage(),
            '/add-inventory': (context) => const AddInventoryPage(),
            '/sales': (context) => SalesPage(),
            '/edit-inventory': (context) => const EditInventoryPage(),
            '/inventory-item-overview': (context) => InventoryItemOverview(),
            '/inventory-tablet': (context) => const InventoryPageTablet(),
            '/add-inventory-tablet': (context) => const AddInventoryPage(),
            '/transaction_complete': (context) => TransactionCompletePage(),
            '/payment_page': (context) => PaymentPage(),
            '/sales-history-detail': (context) => SalesHistory(),
          },
        );
      },
    );
  }
}
