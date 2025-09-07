import 'dart:convert';
import 'dart:core';

import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/ui/components/pages/sales_page.dart';
import 'package:cash_app/ui/components/pages/analytics/sales_analytics_page.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final pc = Get.find<PageControllers>();
  Future<Map<String, dynamic>> salesSummary = Future.value(<String, dynamic>{});
  Config db = Get.find<Config>();

  Future<Map<String, dynamic>> getSalesSummary() async {
    await db.updateNumberOfLogins();
    return await db.getSalesSummary();
  }

  Future<List<Map<String, dynamic>>> getLowStockItems() async {
    final inventory = await db.getInventory();
    if (inventory == null) return [];
    return inventory
        .where((item) {
          final quantity = (item['quantity'] as num?) ?? 0;
          return quantity < 10;
        })
        .take(3)
        .toList()
        .cast<Map<String, dynamic>>();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> refreshSummary() async {
    final data = getSalesSummary();
    setState(() {
      salesSummary = data; // assign new future so FutureBuilder rebuilds once
    });
    await data; // await for pull-to-refresh spinner
  }

  @override
  void initState() {
    super.initState();
    salesSummary = getSalesSummary();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 680 ? 4 : width > 520 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          "CashMate",
          style: TextStyle(
            color: bluePrimary,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshSummary,
        child: FutureBuilder<Map<String, dynamic>>(
          future: salesSummary,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return ListView( // to enable pull-to-refresh
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * .3),
                    Center(child: Text('Error: ${snapshot.error}')),
                  ],
                );
              } else if (!snapshot.hasData || snapshot.data == null) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * .3),
                    const Center(child: Text('No sales data available')),
                  ],
                );
              }

              final data = snapshot.data!;
              final salesSummaryString = jsonEncode(data);

              final stats = <_StatItem>[
                _StatItem(
                  label: "Sales Today",
                  value: data["sales_today"].toString(),
                  icon: Icons.trending_up,
                  gradient: [bluePrimary, blueSecondary],
                ),
                _StatItem(
                  label: "Today's Revenue",
                  value: "K ${data["today_revenue"]}",
                  icon: Icons.payments,
                  gradient: [Colors.purpleAccent, bluePrimary],
                ),
                _StatItem(
                  label: "All-time Sales",
                  value: data["alltime_sales"].toString(),
                  icon: Icons.shopping_bag,
                  gradient: [Colors.orangeAccent, Colors.deepOrange],
                ),
                _StatItem(
                  label: "All-time Revenue",
                  value: "K ${data["total_sales"]}",
                  icon: Icons.attach_money,
                  gradient: [Colors.green, Colors.teal],
                ),
              ];

              return CustomScrollView(
                slivers: [
                  // Welcome Section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [bluePrimary, blueSecondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: bluePrimary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ready to make some sales?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.waving_hand,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Quick Actions
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Quick Actions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  title: 'New Sale',
                                  subtitle: 'Start selling',
                                  icon: Icons.point_of_sale,
                                  color: Colors.green,
                                  onTap: () => Get.to(() => SalesPage()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionCard(
                                  title: 'Add Item',
                                  subtitle: 'Manage inventory',
                                  icon: Icons.add_box,
                                  color: Colors.blue,
                                  onTap: () => Get.toNamed('/add-inventory'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionCard(
                                  title: 'Analytics',
                                  subtitle: 'View insights',
                                  icon: Icons.analytics,
                                  color: Colors.purple,
                                  onTap: () async {
                                    final sales = await _fetchSalesForAnalytics();
                                    Get.to(() => SalesAnalyticsPage(sales: sales));
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Low Stock Alert
                  SliverToBoxAdapter(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: getLowStockItems(),
                      builder: (context, lowStockSnapshot) {
                        if (lowStockSnapshot.hasData && lowStockSnapshot.data!.isNotEmpty) {
                          return Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Low Stock Alert',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...lowStockSnapshot.data!.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name']?.toString() ?? 'Unknown',
                                          style: TextStyle(color: Colors.grey.shade700),
                                        ),
                                      ),
                                      Text(
                                        '${item['quantity']} left',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => pc.changePage(1), // Go to inventory
                                  child: const Text('Manage Inventory'),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                      child: Text(
                        "Performance Overview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = stats[index];
                          return _SummaryCard(item: item);
                        },
                        childCount: stats.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent Transactions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: bluePrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => pc.changePage(2),
                            child: const Text("View All"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _RecentTransactionsCard(
                        salesSummaryString: salesSummaryString,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            }),
      ),
    );
  }

  Future<List<SalesModel>> _fetchSalesForAnalytics() async {
    try {
      final raw = await db.getSalesHistory();
      if (raw == null) return [];
      return raw.map((m) => SalesModel(
        date: m['date'] as String?,
        total: (m['amount'] as num?)?.toDouble(),
        itemsSold: [], // not reconstructing detailed items from text blob
        transactionType: m['transaction_type'] as String?,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  // Legacy functions kept only if referenced elsewhere
  Widget buildSalesTable(String salesSummaryString) { // retained for compatibility (unused in new layout)
    List<dynamic>? salesSummary = jsonDecode(salesSummaryString)['recent_sales'];
    if (salesSummary == null) {
      return const Center(child: Text('No recent sales available'));
    }
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.blueGrey),
          children: [
            tableHeader("Invoice ID"),
            tableHeader("Date"),
            tableHeader("Amount"),
          ],
        ),
        for (var record in salesSummary)
          TableRow(children: [
            tableCell(record["id"].toString()),
            tableCell(record["date"]),
            tableCell("K${record["amount"]}"),
          ]),
      ],
    );
  }

  Widget tableHeader(String text) { // unchanged helper
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget tableCell(String text) { // unchanged helper
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

// ----------------- New UI Components -----------------
class _SummaryCard extends StatelessWidget {
  final _StatItem item;
  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: item.gradient.last.withOpacity(.35),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(.25),
            child: Icon(item.icon, color: Colors.white, size: 26),
          ),
          const Spacer(),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(.85),
              letterSpacing: .3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  _StatItem({required this.label, required this.value, required this.icon, required this.gradient});
}

class _RecentTransactionsCard extends StatelessWidget {
  final String salesSummaryString;
  const _RecentTransactionsCard({required this.salesSummaryString});

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? salesSummary = jsonDecode(salesSummaryString)['recent_sales'];
    if (salesSummary == null || salesSummary.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(context),
        child: const Center(child: Text('No recent sales available')),
      );
    }

    return Container(
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          for (int i = 0; i < salesSummary.length; i++) ...[
            _TransactionTile(record: salesSummary[i]),
            if (i != salesSummary.length - 1)
              Divider(height: 0, thickness: .7, color: Colors.grey.shade200),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(.05),
        blurRadius: 12,
        offset: const Offset(0, 6),
      )
    ],
  );
}

class _TransactionTile extends StatelessWidget {
  final Map record;
  const _TransactionTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: Colors.blueGrey.shade50,
        child: Icon(Icons.receipt_long, color: bluePrimary),
      ),
      title: Text(
        "Invoice #${record["id"]}",
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        record["date"],
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            "K${record["amount"]}",
            style: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Paid",
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      onTap: () {},
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
