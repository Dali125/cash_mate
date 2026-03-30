import 'dart:convert';

import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/ui/components/pages/analytics/sales_analytics_page.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePageTablet extends StatefulWidget {
  const HomePageTablet({super.key});

  @override
  State<HomePageTablet> createState() => _HomePageTabletState();
}

class _HomePageTabletState extends State<HomePageTablet> {
  final pc = Get.find<PageControllers>();
  final Config db = Get.find<Config>();

  Future<Map<String, dynamic>> salesSummary =
      Future.value(<String, dynamic>{});

  Future<Map<String, dynamic>> getSalesSummary() async {
    await db.updateNumberOfLogins();
    return db.getSalesSummary();
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final inventory = await db.getInventory();
    if (inventory == null) return [];

    return inventory
        .where((item) {
          final quantity = (item['quantity'] as num?) ?? 0;
          return quantity < 10;
        })
        .take(5)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> refreshSummary() async {
    final data = getSalesSummary();
    setState(() {
      salesSummary = data;
    });
    await data;
  }

  Future<List<SalesModel>> _fetchSalesForAnalytics() async {
    try {
      final raw = await db.getSalesHistory();
      if (raw == null) return [];

      return raw
          .map(
            (item) => SalesModel(
              date: item['date'] as String?,
              total: (item['amount'] as num?)?.toDouble(),
              itemsSold: const [],
              transactionType: item['transaction_type'] as String?,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    salesSummary = getSalesSummary();
  }

  @override
  Widget build(BuildContext context) {
    print(MediaQuery.sizeOf(context).width);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: refreshSummary,
        child: FutureBuilder<Map<String, dynamic>>(
          future: salesSummary,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                  Center(child: Text('Error: ${snapshot.error}')),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
                  const Center(child: Text('No sales data available')),
                ],
              );
            }

            final data = snapshot.data!;
            final recentSales =
                (data['recent_sales'] as List<dynamic>? ?? const []).cast<dynamic>();
            final stats = <_TabletStatItem>[
              _TabletStatItem(
                label: 'Sales Today',
                value: data['sales_today'].toString(),
                icon: Icons.trending_up,
                gradient: [bluePrimary, blueSecondary],
              ),
              _TabletStatItem(
                label: "Today's Revenue",
                value: 'K ${((data['today_revenue'] as num?) ?? 0).toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                gradient: [const Color(0xFF7B61FF), bluePrimary],
              ),
              _TabletStatItem(
                label: 'All-time Sales',
                value: data['alltime_sales'].toString(),
                icon: Icons.shopping_bag_outlined,
                gradient: [Colors.orangeAccent, Colors.deepOrange],
              ),
              _TabletStatItem(
                label: 'All-time Revenue',
                value: 'K ${((data['total_sales'] as num?) ?? 0).toStringAsFixed(2)}',
                icon: Icons.attach_money,
                gradient: [Colors.green, Colors.teal],
              ),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final isVeryWide = constraints.maxWidth >= 1320;
                final statColumns = constraints.maxWidth >= 1500 ? 4 : 2;
                final heroHeight = isVeryWide ? 240.0 : 220.0;

                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _TabletHeroSection(
                      greeting: _getGreeting(),
                      totalSales: (data['alltime_sales'] as num?)?.toInt() ?? 0,
                      totalRevenue:
                          ((data['total_sales'] as num?) ?? 0).toDouble(),
                      onNewSale: () => Get.toNamed('/sales'),
                      onAddItem: () => Get.toNamed('/add-inventory'),
                      onAnalytics: () async {
                        final sales = await _fetchSalesForAnalytics();
                        Get.to(() => SalesAnalyticsPage(sales: sales));
                      },
                      height: heroHeight,
                    ),
                    const SizedBox(height: 24),
                    if (isVeryWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  title: 'Performance Overview',
                                  subtitle:
                                      'Daily and lifetime business performance at a glance.',
                                ),
                                const SizedBox(height: 14),
                                _TabletStatsGrid(
                                  items: stats,
                                  crossAxisCount: statColumns,
                                ),
                                const SizedBox(height: 24),
                                _SectionTitle(
                                  title: 'Recent Transactions',
                                  subtitle:
                                      'Latest completed sales from your register.',
                                  actionLabel: 'View All',
                                  onAction: () => pc.changePage(2),
                                ),
                                const SizedBox(height: 14),
                                _TabletRecentTransactions(
                                  recentSales: recentSales,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  title: 'Quick Actions',
                                  subtitle:
                                      'Jump into the most common tasks from the dashboard.',
                                ),
                                const SizedBox(height: 14),
                                _TabletQuickActions(
                                  onNewSale: () => Get.toNamed('/sales'),
                                  onAddItem: () => Get.toNamed('/add-inventory'),
                                  onAnalytics: () async {
                                    final sales = await _fetchSalesForAnalytics();
                                    Get.to(() => SalesAnalyticsPage(sales: sales));
                                  },
                                ),
                                const SizedBox(height: 24),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: getLowStockItems(),
                                  builder: (context, lowStockSnapshot) {
                                    return _TabletLowStockCard(
                                      items: lowStockSnapshot.data ?? const [],
                                      onManageInventory: () => pc.changePage(1),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                _TabletInsightCard(
                                  totalItemsSold:
                                      (data['total_items_sold'] as num?)?.toInt() ?? 0,
                                  salesToday:
                                      (data['sales_today'] as num?)?.toInt() ?? 0,
                                  todayRevenue:
                                      ((data['today_revenue'] as num?) ?? 0).toDouble(),
                                  recentSalesCount: recentSales.length,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            title: 'Quick Actions',
                            subtitle:
                                'Start a sale, add stock, or open analytics quickly.',
                          ),
                          const SizedBox(height: 14),
                          _TabletQuickActions(
                            onNewSale: () => Get.toNamed('/sales'),
                            onAddItem: () => Get.toNamed('/add-inventory'),
                            onAnalytics: () async {
                              final sales = await _fetchSalesForAnalytics();
                              Get.to(() => SalesAnalyticsPage(sales: sales));
                            },
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            title: 'Performance Overview',
                            subtitle:
                                'Daily and lifetime business performance at a glance.',
                          ),
                          const SizedBox(height: 14),
                          _TabletStatsGrid(
                            items: stats,
                            crossAxisCount: statColumns,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: FutureBuilder<List<Map<String, dynamic>>>(
                                  future: getLowStockItems(),
                                  builder: (context, lowStockSnapshot) {
                                    return _TabletLowStockCard(
                                      items: lowStockSnapshot.data ?? const [],
                                      onManageInventory: () => pc.changePage(1),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: _TabletInsightCard(
                                  totalItemsSold:
                                      (data['total_items_sold'] as num?)?.toInt() ?? 0,
                                  salesToday:
                                      (data['sales_today'] as num?)?.toInt() ?? 0,
                                  todayRevenue:
                                      ((data['today_revenue'] as num?) ?? 0).toDouble(),
                                  recentSalesCount: recentSales.length,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            title: 'Recent Transactions',
                            subtitle: 'Latest completed sales from your register.',
                            actionLabel: 'View All',
                            onAction: () => pc.changePage(2),
                          ),
                          const SizedBox(height: 14),
                          _TabletRecentTransactions(recentSales: recentSales),
                        ],
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TabletHeroSection extends StatelessWidget {
  final String greeting;
  final int totalSales;
  final double totalRevenue;
  final VoidCallback onNewSale;
  final VoidCallback onAddItem;
  final VoidCallback onAnalytics;
  final double height;

  const _TabletHeroSection({
    required this.greeting,
    required this.totalSales,
    required this.totalRevenue,
    required this.onNewSale,
    required this.onAddItem,
    required this.onAnalytics,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bluePrimary, blueSecondary, const Color(0xFF4DA8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: bluePrimary.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ready to make some sales?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Track performance, launch sales faster, and keep inventory moving from one dashboard.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
             
              
              ]
              
              ,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroMetric(
                    label: 'Total Sales Recorded',
                    value: totalSales.toString(),
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 8),
                  _HeroMetric(
                    label: 'Revenue to Date',
                    value: 'K ${totalRevenue.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.84),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: bluePrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _TabletQuickActions extends StatelessWidget {
  final VoidCallback onNewSale;
  final VoidCallback onAddItem;
  final VoidCallback onAnalytics;

  const _TabletQuickActions({
    required this.onNewSale,
    required this.onAddItem,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            title: 'New Sale',
            subtitle: 'Open the register and add items quickly.',
            icon: Icons.point_of_sale,
            color: Colors.green,
            onTap: onNewSale,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickActionTile(
            title: 'Add Item',
            subtitle: 'Create new inventory without leaving the dashboard.',
            icon: Icons.add_box_outlined,
            color: Colors.blue,
            onTap: onAddItem,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _QuickActionTile(
            title: 'Analytics',
            subtitle: 'Review trends, top products, and payment mix.',
            icon: Icons.analytics_outlined,
            color: Colors.purple,
            onTap: onAnalytics,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletStatsGrid extends StatelessWidget {
  final List<_TabletStatItem> items;
  final int crossAxisCount;

  const _TabletStatsGrid({
    required this.items,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) => _TabletStatCard(item: items[index]),
    );
  }
}

class _TabletStatCard extends StatelessWidget {
  final _TabletStatItem item;

  const _TabletStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: item.gradient.last.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.24),
            child: Icon(item.icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletLowStockCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onManageInventory;

  const _TabletLowStockCard({
    required this.items,
    required this.onManageInventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: items.isEmpty ? Colors.white : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: items.isEmpty ? Colors.grey.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                items.isEmpty ? Icons.inventory_2_outlined : Icons.warning_amber,
                color: items.isEmpty ? bluePrimary : Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                items.isEmpty ? 'Stock Status' : 'Low Stock Alert',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: items.isEmpty ? bluePrimary : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              'No products are below the low-stock threshold right now.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name']?.toString() ?? 'Unknown Item',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${item['quantity']} left',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onManageInventory,
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Manage Inventory'),
          ),
        ],
      ),
    );
  }
}

class _TabletInsightCard extends StatelessWidget {
  final int totalItemsSold;
  final int salesToday;
  final double todayRevenue;
  final int recentSalesCount;

  const _TabletInsightCard({
    required this.totalItemsSold,
    required this.salesToday,
    required this.todayRevenue,
    required this.recentSalesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Snapshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: bluePrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A quick operational summary for today and recent activity.',
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),
          _InsightRow(
            label: 'Items sold overall',
            value: totalItemsSold.toString(),
            icon: Icons.inventory_2_outlined,
          ),
          _InsightRow(
            label: 'Sales recorded today',
            value: salesToday.toString(),
            icon: Icons.today_outlined,
          ),
          _InsightRow(
            label: 'Revenue today',
            value: 'K ${todayRevenue.toStringAsFixed(2)}',
            icon: Icons.payments_outlined,
          ),
          _InsightRow(
            label: 'Recent transactions shown',
            value: recentSalesCount.toString(),
            icon: Icons.receipt_long_outlined,
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bluePrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: bluePrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TabletRecentTransactions extends StatelessWidget {
  final List<dynamic> recentSales;

  const _TabletRecentTransactions({required this.recentSales});

  @override
  Widget build(BuildContext context) {
    if (recentSales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: Text('No recent sales available')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Invoice',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Payment',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          for (int index = 0; index < recentSales.length; index++) ...[
            _TabletTransactionRow(record: recentSales[index]),
            if (index != recentSales.length - 1)
              Divider(height: 1, color: Colors.grey.shade100),
          ],
        ],
      ),
    );
  }
}

class _TabletTransactionRow extends StatelessWidget {
  final dynamic record;

  const _TabletTransactionRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final row = record is Map ? record : jsonDecode(jsonEncode(record)) as Map;
    final amount = ((row['amount'] as num?) ?? 0).toDouble();
    final payment = row['transaction_type']?.toString() ?? 'Paid';

    return InkWell(
      onTap: () => Get.toNamed('/sales-history-detail', arguments: row),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '#${row['id']}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                row['date']?.toString() ?? '-',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    payment,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'K ${amount.toStringAsFixed(2)}',
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletStatItem {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  _TabletStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}
