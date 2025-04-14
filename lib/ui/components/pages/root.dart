import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/pages/add_inventory.dart';
import 'package:cash_app/ui/components/pages/inventory_page.dart';
import 'package:cash_app/ui/components/pages/nkongole_page.dart';
import 'package:cash_app/ui/components/pages/sales_page.dart';
import 'package:cash_app/ui/components/pages/splash_screen/sales_history_page.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/sales_page_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/tablet_home.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  @override
  void initState() {
    super.initState();
    Get.put(PageControllers());
  }

  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    Get.put(Config());
    Get.put(MediaController());
    final pc = Get.find<PageControllers>();
    return Scaffold(
      body: DeviceProperties().isTablet(context)
          ? SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    leading: Material(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/splash-android.png',
                        height: 80,
                        width: 80,
                      ),
                    ),
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.inventory),
                        label: Text('Inventory'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.school),
                        label: Text('School'),
                      ),
                    ],
                    selectedIndex: pc.currentPage.value,
                    onDestinationSelected: (index) {
                      pc.changePage(index);
                      setState(() {});
                    },
                  ),
                  Expanded(
                    child: switch (pc.currentPage.value) {
                      0 => HomePageTablet(),
                      1 => InventoryPageTablet(),
                      2 => SalesHistoryPage(),
                      _ => HomePageTablet(),
                    },
                  ),
                ],
              ),
            )
          : switch (pc.currentPage.value) {
              0 => HomePage(),
              1 => InventoryPage(),
              2 => SalesHistoryPage(),
              3 => NkongolePage(),
              _ => HomePage(),
            },
      floatingActionButton: pc.currentPage.value == 0
          ? FloatingActionButton(
              onPressed: () {
                if (DeviceProperties().isTablet(context)) {
                  Get.to(() => SalesPageTablet());
                } else {
                  Get.to(() => SalesPage());
                }
              },
              child: const Icon(
                Icons.calculate,
              ))
          : FloatingActionButton(
              onPressed: () {
                Get.to(() => const AddInventoryPage());
              },
              child: const Icon(
                Icons.add,
              )),
      bottomNavigationBar: DeviceProperties().isTablet(context)
          ? SizedBox.shrink()
          : BottomNavigationBar(
              onTap: (index) {
                pc.changePage(index);
                setState(() {});
              },
              currentIndex: pc.currentPage.value,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory),
                  label: 'Inventory',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Sales History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.monetization_on),
                  label: 'Nkongole',
                ),
              ],
              selectedItemColor: bluePrimary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.shifting,
              showUnselectedLabels: true,
            ),
    );
  }
}
