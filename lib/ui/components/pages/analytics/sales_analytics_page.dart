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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: topItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No sales data available',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topItems.take(5).length,
                  separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    final isFirst = index == 0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isFirst ? Colors.amber.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFirst ? Colors.amber.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '${item.value} sold',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPeriodHeader(period.key),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _trendMetric('Revenue', 'K ${totalRevenue.toStringAsFixed(2)}', Icons.monetization_on_outlined, Colors.green)),
                          Expanded(child: _trendMetric('Sales', period.value.length.toString(), Icons.shopping_cart_outlined, Colors.blue)),
                          Expanded(child: _trendMetric('Items', itemCount.toString(), Icons.inventory_2_outlined, Colors.orange)),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'K ${(sale.total ?? 0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      sale.date ?? 'Unknown date',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (sale.itemsSold?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  Text(
                    'Items Sold',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sale.itemsSold!.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: bluePrimary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name ?? 'Unknown item',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity ?? 0}x',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: bluePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Trends'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
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
