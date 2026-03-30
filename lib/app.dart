import 'package:cash_app/db/config.dart';
import 'package:cash_app/ui/components/pages/mobile/add_inventory.dart';
import 'package:cash_app/ui/components/pages/mobile/edit_inventory.dart';
import 'package:cash_app/ui/components/pages/mobile/inventory_item_overview.dart';
import 'package:cash_app/ui/components/pages/mobile/inventory_page.dart';
import 'package:cash_app/ui/components/pages/mobile/payments/payment_page.dart';
import 'package:cash_app/ui/components/pages/mobile/root.dart';
import 'package:cash_app/ui/components/pages/mobile/sales_history/history.dart';
import 'package:cash_app/ui/components/pages/mobile/sales_page.dart';
import 'package:cash_app/ui/components/pages/tablet/add_inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/edit_inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_item_overview_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/payment_page_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/sales_history_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/sales_page_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/tablet_root.dart';
import 'package:cash_app/ui/components/pages/tablet/transaction_complete_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/welcome_screens_tablet.dart';
import 'package:cash_app/ui/components/pages/mobile/transaction_complete_page.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/utils/color.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:cash_app/ui/components/pages/mobile/onboarding/welcome_screens.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final device = DeviceProperties();

    return GetMaterialApp(
      title: 'Cash App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: bluePrimary),
      ),
      home: const _StartupGate(),
      routes: {
      '/welcome_screens': (context) => device.isTablet(context)
        ? const WelcomeScreensTablet()
        : const WelcomeScreens(),
      '/inventory': (context) => device.isTablet(context)
        ? const InventoryPageTablet()
        : const InventoryPage(),
      '/add-inventory': (context) => device.isTablet(context)
        ? const AddInventoryPageTablet()
        : const AddInventoryPage(),
      '/sales': (context) => device.isTablet(context)
            ? const SalesPageTablet()
            : SalesPage(),
      '/edit-inventory': (context) => device.isTablet(context)
        ? const EditInventoryPageTablet()
        : const EditInventoryPage(),
      '/edit-inventory-tablet': (context) => const EditInventoryPageTablet(),
      '/inventory-item-overview': (context) => device.isTablet(context)
        ? const InventoryItemOverviewTablet()
        : InventoryItemOverview(),
        '/inventory-tablet': (context) => const InventoryPageTablet(),
      '/add-inventory-tablet': (context) => const AddInventoryPageTablet(),
      '/transaction_complete': (context) => device.isTablet(context)
        ? const TransactionCompletePageTablet()
        : TransactionCompletePage(),
      '/payment_page': (context) => device.isTablet(context)
        ? const PaymentPageTablet()
        : PaymentPage(),
      '/sales-history-detail': (context) => device.isTablet(context)
        ? const SalesHistoryTablet()
        : SalesHistory(),
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
        if (logins > 0) {
          return DeviceProperties().isTablet(context)
              ? const TabletRoot()
              : const RootPage();
        }

        return DeviceProperties().isTablet(context)
            ? const WelcomeScreensTablet()
            : const WelcomeScreens();
      },
    );
  }
}
