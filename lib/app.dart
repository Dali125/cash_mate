import 'package:cash_app/db/config.dart';
import 'package:cash_app/ui/components/pages/mobile/add_inventory.dart';
import 'package:cash_app/ui/components/pages/mobile/edit_inventory.dart';
import 'package:cash_app/ui/components/pages/mobile/inventory_item_overview.dart';
import 'package:cash_app/ui/components/pages/mobile/inventory_page.dart';
import 'package:cash_app/ui/components/pages/mobile/payments/payment_page.dart';
import 'package:cash_app/ui/components/pages/mobile/root.dart';
import 'package:cash_app/ui/components/pages/mobile/sales_history/history.dart';
import 'package:cash_app/ui/components/pages/mobile/sales_page.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/mobile/transaction_complete_page.dart';
import 'package:cash_app/utils/color.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:cash_app/ui/components/pages/mobile/onboarding/welcome_screens.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cash App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: bluePrimary),
      ),
      home: const _StartupGate(),
      routes: {
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
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final db = Get.find<Config>();

    return FutureBuilder<int>(
      future: db.getNumberOfLogins(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final logins = snapshot.data ?? 0;
        return logins > 0 ? const RootPage() : const WelcomeScreens();
      },
    );
  }
}
