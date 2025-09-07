import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/pages/add_inventory.dart';
import 'package:cash_app/ui/components/pages/inventory_page.dart';
import 'package:cash_app/ui/components/pages/more_tools.dart';
import 'package:cash_app/ui/components/pages/nkongole_page.dart';
import 'package:cash_app/ui/components/pages/sales_page.dart';
import 'package:cash_app/ui/components/pages/splash_screen/sales_history_page.dart';
import 'package:cash_app/ui/components/pages/tablet/inventory_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/sales_page_tablet.dart';
import 'package:cash_app/ui/components/pages/tablet/tablet_home.dart';
import 'package:cash_app/ui/components/pages/tablet/tablet_root.dart';
import 'package:cash_app/utils/color.dart';


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';


import 'home_page.dart';
import 'settings/settings_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final _fabKey = GlobalKey();
  final _navHomeKey = GlobalKey();
  final _navInventoryKey = GlobalKey();
  final _navSalesHistKey = GlobalKey();
  final _navMoreKey = GlobalKey();
  final _navSettingsKey = GlobalKey();
  bool _tutorialStarted = false;
  bool _isTutorialPending = true;

  @override
  void initState() {
    super.initState();
    Get.put(PageControllers());
    // _maybeStartTutorial();
      WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isTutorialPending) {
        _maybeStartTutorial(context);
      }
    });
  }

  Future<void> _maybeStartTutorial(BuildContext context) async {
    if (_tutorialStarted || !mounted) return;
    
    final config = Get.find<Config>();
    final seen = await config.getHasSeenTutorial();
    if (seen) return;
    
    _tutorialStarted = true;
    _isTutorialPending = false;
    
    try {
      ShowCaseWidget.of(context).startShowCase([
        _fabKey,
        _navHomeKey,
        _navInventoryKey,
        _navSalesHistKey,
        _navMoreKey,
        _navSettingsKey,
      ]);
      await config.setHasSeenTutorial();
    } catch (e) {
      print('Tutorial error: $e');
    }
  }

  int currentPage = 0;
  @override
  Widget build(BuildContext context) {

    Get.put(MediaController());
    final pc = Get.find<PageControllers>();
    return Scaffold(
        body: DeviceProperties().isDesktop(context)
            ? InventoryPageTablet()
            : switch (pc.currentPage.value) {
                0 => HomePage(),
                1 => InventoryPage(),
                2 => SalesHistoryPage(),
                3 => MoreToolsPage(),
                4 => SettingsPage(),
                _ => HomePage(),
              },
        floatingActionButton: pc.currentPage.value == 0
            ? Showcase(
                key: _fabKey,
                description: 'Tap here to create a new sale quickly.',
                child: FloatingActionButton(
                  onPressed: () {
                    if (DeviceProperties().isTablet(context)) {
                      Get.to(() => SalesPageTablet());
                    } else {
                      Get.to(() => SalesPage());
                    }
                  },
                  child: const Icon(Icons.calculate),
                ),
              )
            : null,
        bottomNavigationBar: DeviceProperties().isTablet(context)
            ? const SizedBox.shrink()
            : BottomNavigationBar(
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
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
              ),
      );
  }
}
