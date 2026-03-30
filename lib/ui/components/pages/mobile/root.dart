import 'package:cash_app/controllers/page_controller.dart';

import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/pages/inventory/barcode/page.dart';
import 'package:cash_app/ui/components/pages/inventory/excel/page.dart';
import 'package:cash_app/ui/components/pages/mobile/inventory_page.dart';

import 'package:cash_app/ui/components/pages/mobile/more_tools.dart';

import 'package:cash_app/ui/components/pages/mobile/splash_screen/sales_history_page.dart';
import 'package:cash_app/ui/components/pages/tablet/tablet_root.dart';

import 'package:cash_app/utils/color.dart';
import 'package:cash_app/utils/misc.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

import 'home_page.dart';
import '../settings/settings_page.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // Use late final instead of static to avoid duplicate key issues on hot reload
  late final GlobalKey<ExpandableFabState> _expandableFabKey =
      GlobalKey<ExpandableFabState>();
  late final GlobalKey _navHomeKey = GlobalKey();
  late final GlobalKey _navInventoryKey = GlobalKey();
  late final GlobalKey _navSalesHistKey = GlobalKey();
  late final GlobalKey _navMoreKey = GlobalKey();
  late final GlobalKey _navSettingsKey = GlobalKey();
  final database = Get.find<Config>();

  @override
  void initState() {
    super.initState();
    database.getNumberOfLogins().then((value) {
      if (value < 1) {
        GetShowcaseConfig([
          _navHomeKey,
          _navInventoryKey,
          _navSalesHistKey,
          _navMoreKey,
          _navSettingsKey,
        ]);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    if (DeviceProperties().isTablet(context)) {
      return const TabletRoot();
    }

    final pc = Get.find<PageControllers>();
    return ShowCaseWidget(
      builder: (context) => Scaffold(
        backgroundColor: appBackground,
        body: SafeArea(
          child: switch (pc.currentPage.value) {
            0 => HomePage(),
            1 => InventoryPage(),
            2 => SalesHistoryPage(),
            3 => MoreToolsPage(),
            4 => SettingsPage(),
            _ => HomePage(),
          },
        ),
        floatingActionButtonLocation:
            pc.currentPage.value == 1 ? ExpandableFab.location : null,
        floatingActionButton: pc.currentPage.value == 0
            ? Showcase(
                key:
                    GlobalKey(), // Showcase needs a unique key, using old _fabKey style logic or just a new key
                description: 'Tap here to create a new sale quickly.',
                child: FloatingActionButton(
                  onPressed: () {
                    Get.toNamed('/sales');
                  },
                  child: const Icon(Icons.calculate),
                ),
              )
            : pc.currentPage.value == 1
                ? ExpandableFab(
                    onOpen: () => pc.toggleFab(),
                    onClose: () => pc.toggleFab(),
                    overlayStyle: const ExpandableFabOverlayStyle(
                      color: Color.fromARGB(135, 31, 31, 31),
                    ),
                    key: _expandableFabKey,
                    type: ExpandableFabType.up,
                    distance: 70,
                    openButtonBuilder: RotateFloatingActionButtonBuilder(
                      child: const Icon(Icons.add),
                      fabSize: ExpandableFabSize.regular,
                      foregroundColor: Colors.white,
                      backgroundColor: bluePrimary,
                      shape: const CircleBorder(),
                    ),
                    closeButtonBuilder: DefaultFloatingActionButtonBuilder(
                      child: const Icon(Icons.close),
                      fabSize: ExpandableFabSize.small,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                      shape: const CircleBorder(),
                    ),
                    children: [
                      Row(
                        children: [
                          Text(
                            "Add Inventory Manually",
                            style: TextStyle(
                                color: pc.isFabExpanded.value
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          SizedBox(width: 10),
                          FloatingActionButton.small(
                            heroTag: "manual",
                            onPressed: () => Get.toNamed('/add-inventory'),
                            child: const Icon(Icons.edit_note),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Add Inventory from Excel",
                            style: TextStyle(
                                color: pc.isFabExpanded.value
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          SizedBox(width: 10),
                          FloatingActionButton.small(
                            heroTag: "csv",
                            onPressed: () {
                              Get.to(() => InventoryExcelPage());
                            },
                            child: const Icon(Icons.file_upload),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "Add Inventory from Barcode",
                            style: TextStyle(
                                color: pc.isFabExpanded.value
                                    ? Colors.black
                                    : Colors.white),
                          ),
                          SizedBox(width: 10),
                          FloatingActionButton.small(
                            heroTag: "scan",
                            onPressed: () => Get.to(() => BarcodeScannerPage()),
                            child: const Icon(Icons.qr_code_scanner),
                          ),
                        ],
                      ),
                    ],
                  )
                : null,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          onTap: (index) {
            pc.changePage(index);
            setState(() {});
          },
          currentIndex: pc.currentPage.value,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Showcase(
                key: _navHomeKey,
                description: 'Home dashboard overview.',
                child: const Icon(Icons.home),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Showcase(
                key: _navInventoryKey,
                description: 'Manage your products here.',
                child: const Icon(Icons.inventory),
              ),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: Showcase(
                key: _navSalesHistKey,
                description: 'View your recent sales history.',
                child: const Icon(Icons.history),
              ),
              label: 'Sales History',
            ),
            BottomNavigationBarItem(
              icon: Showcase(
                key: _navMoreKey,
                description: 'More tools & reports.',
                child: const Icon(Icons.more_horiz),
              ),
              label: 'More',
            ),
            BottomNavigationBarItem(
              icon: Showcase(
                key: _navSettingsKey,
                description: 'Configure application settings.',
                child: const Icon(Icons.settings),
              ),
              label: 'Settings',
            ),
          ],
          selectedItemColor: bluePrimary,
          unselectedItemColor: appMutedText,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}
