import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesAnalyticsPage extends StatefulWidget {
  final List<SalesModel> sales;
  
  const SalesAnalyticsPage({
    required this.sales,
    Key? key,
  }) : super(key: key);

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';
  final dateFormat = DateFormat('yyyy-MM-dd');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<SalesModel>>> _groupSalesByPeriod() {
    final Map<String, List<SalesModel>> grouped = {};
    
    for (var sale in widget.sales) {
      if (sale.date == null) continue;
      
      String key;
      final date = DateTime.tryParse(sale.date!);
      if (date == null) continue;

      switch (_selectedPeriod) {
        case 'week':
          // Get the week start date
          final weekStart = date.subtract(Duration(days: date.weekday - 1));
          key = dateFormat.format(weekStart);
          break;
        case 'month':
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          break;
        case 'year':
          key = date.year.toString();
          break;
        default:
          key = dateFormat.format(date);
      }

      grouped[key] = [...(grouped[key] ?? []), sale];
    }

    return grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  Widget _buildOverviewTab() {
    final totalRevenue = widget.sales.fold<double>(0, (sum, sale) => sum + (sale.total ?? 0));
    final avgTicketSize = widget.sales.isEmpty ? 0.0 : totalRevenue / widget.sales.length;
    
    // Calculate items sold
    int totalItemsSold = 0;
    final itemFrequency = <String, int>{};
    
    for (var sale in widget.sales) {
      for (var item in sale.itemsSold ?? []) {
        final quantity = (item.quantity as num? ?? 0).toInt();
        totalItemsSold += quantity;
        final itemName = item.name ?? 'Unknown';
        itemFrequency[itemName] = (itemFrequency[itemName] ?? 0) + quantity;
      }
    }

    // Get top selling items
    final topItems = itemFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Total Revenue',
                'K ${totalRevenue.toStringAsFixed(2)}',
                Icons.monetization_on_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _metricCard(
                'Average Sale',
                'K ${avgTicketSize.toStringAsFixed(2)}',
                Icons.receipt_long_outlined,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Total Sales',
                widget.sales.length.toString(),
                Icons.shopping_cart_outlined,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _metricCard(
                'Items Sold',
                totalItemsSold.toString(),
                Icons.inventory_2_outlined,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Top Selling Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topItems.take(5).length,
            itemBuilder: (context, index) {
              final item = topItems[index];
              return ListTile(
                title: Text(item.key),
                trailing: Text(
                  '${item.value} sold',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsTab() {
    final groupedSales = _groupSalesByPeriod();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'week', label: Text('Weekly')),
              ButtonSegment(value: 'month', label: Text('Monthly')),
              ButtonSegment(value: 'year', label: Text('Yearly')),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _selectedPeriod = selection.first);
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (states) => states.contains(MaterialState.selected) 
                  ? bluePrimary 
                  : Colors.transparent,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedSales.length,
            itemBuilder: (context, index) {
              final period = groupedSales[index];
              final totalRevenue = period.value.fold<double>(
                0, (sum, sale) => sum + (sale.total ?? 0),
              );
              final itemCount = period.value.fold<int>(
                0, 
                (sum, sale) => sum + (sale.itemsSold?.fold<int>(
                  0, (sum, item) => sum + (item.quantity ?? 0)
                ) ?? 0),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPeriodHeader(period.key),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _trendMetric('Revenue', 'K ${totalRevenue.toStringAsFixed(2)}'),
                          _trendMetric('Sales', period.value.length.toString()),
                          _trendMetric('Items', itemCount.toString()),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.sales.length,
      itemBuilder: (context, index) {
        final sale = widget.sales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  'K ${(sale.total ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  sale.date ?? 'Unknown date',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (sale.itemsSold?.isNotEmpty ?? false) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  ...sale.itemsSold!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name ?? 'Unknown item',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${item.quantity ?? 0}x',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatPeriodHeader(String key) {
    switch (_selectedPeriod) {
      case 'week':
        final date = dateFormat.parse(key);
        final weekEnd = date.add(const Duration(days: 6));
        return 'Week of ${DateFormat('MMM d').format(date)} - ${DateFormat('MMM d').format(weekEnd)}';
      case 'month':
        final parts = key.split('-');
        return DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
      case 'year':
        return key;
      default:
        return key;
    }
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: bluePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
          _buildDetailsTab(),
        ],
      ),
    );
  }
}
