import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/ui/components/pages/mobile/splash_screen/sales_history_page.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/more_tools_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/settings_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/tablet_home.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabletRoot extends StatefulWidget {
  const TabletRoot({super.key});

  @override
  State<TabletRoot> createState() => _TabletRootState();
}

class _TabletRootState extends State<TabletRoot> {
  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PageControllers>();
    final width = MediaQuery.sizeOf(context).width;
    final extended = width >= 1200;
    const pages = <Widget>[
      HomePageTablet(),
      InventoryPageTablet(),
      SalesHistoryPage(),
      MoreToolsTablet(),
      SettingsTablet(),
    ];

    return Obx(() {
      final currentIndex = pc.currentPage.value.clamp(0, pages.length - 1);

      return Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          child: Row(
            children: [
              Container(
                width: extended ? 260 : 92,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: bluePrimary.withOpacity(0.12),
                      child: Icon(Icons.point_of_sale, color: bluePrimary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    if (extended)
                      Text(
                        'CashMate',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: bluePrimary,
                        ),
                      ),
                    if (extended)
                      const SizedBox(height: 6),
                    if (extended)
                      Text(
                        'Tablet and desktop workspace',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Get.toNamed('/sales'),
                        icon: const Icon(Icons.calculate_outlined),
                        label: Text(extended ? 'New Sale' : ''),
                        style: FilledButton.styleFrom(
                          backgroundColor: bluePrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: extended ? 16 : 0,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed('/add-inventory'),
                        icon: const Icon(Icons.add_box_outlined),
                        label: Text(extended ? 'Add Inventory' : ''),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: bluePrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: extended ? 16 : 0,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: NavigationRail(
                        extended: extended,
                        backgroundColor: Colors.transparent,
                        selectedIndex: currentIndex,
                        onDestinationSelected: pc.changePage,
                        indicatorColor: bluePrimary.withOpacity(0.14),
                        selectedIconTheme: IconThemeData(color: bluePrimary),
                        selectedLabelTextStyle: TextStyle(color: bluePrimary),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: Text('Home'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.inventory_2_outlined),
                            selectedIcon: Icon(Icons.inventory_2),
                            label: Text('Inventory'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.receipt_long_outlined),
                            selectedIcon: Icon(Icons.receipt_long),
                            label: Text('History'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.analytics_outlined),
                            selectedIcon: Icon(Icons.analytics),
                            label: Text('Tools'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings),
                            label: Text('Settings'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF4F6FA),
                  child: IndexedStack(index: currentIndex, children: pages),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
