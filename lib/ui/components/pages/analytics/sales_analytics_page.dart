import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'week';

  final Config _db = Get.find<Config>();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _topItems = [];
  List<Map<String, dynamic>> _trendData = [];
  List<Map<String, dynamic>> _recentSales = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await _db.getAnalyticsSummary();
      final topItems = await _db.getTopSellingItems(limit: 5);
      final trendData =
          await _db.getDailySalesData(days: _daysForPeriod(_selectedPeriod));
      final recentSales = await _db.getRecentSalesWithItems(limit: 50);

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _topItems = topItems;
        _trendData = trendData;
        _recentSales = recentSales;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load analytics data';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTrends(String period) async {
    setState(() => _selectedPeriod = period);
    final trendData = await _db.getDailySalesData(days: _daysForPeriod(period));
    if (!mounted) return;
    setState(() => _trendData = trendData);
  }

  int _daysForPeriod(String period) {
    switch (period) {
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'year':
        return 365;
      default:
        return 7;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0.0;
  }

  String _money(double value) => 'K ${value.toStringAsFixed(2)}';

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDateTime(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return value?.toString() ?? '-';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Map<String, double> _paymentMethodTotals() {
    final totals = <String, double>{};
    for (final sale in _recentSales) {
      final typeRaw = sale['transaction_type']?.toString().trim();
      final type = (typeRaw == null || typeRaw.isEmpty) ? 'Unspecified' : typeRaw;
      totals[type] = (totals[type] ?? 0) + _asDouble(sale['total']);
    }
    return totals;
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _metricGridCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTrendDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    if (_selectedPeriod == 'year') {
      return DateFormat('MMM d, yyyy').format(parsed);
    }
    return DateFormat('MMM d').format(parsed);
  }

  Widget _buildOverviewTab() {
    final totalRevenue = _asDouble(_summary['total_revenue']);
    final revenueToday = _asDouble(_summary['revenue_today']);
    final revenueThisWeek = _asDouble(_summary['revenue_this_week']);
    final revenueThisMonth = _asDouble(_summary['revenue_this_month']);
    final avgTicketSize = _asDouble(_summary['avg_transaction_value']);
    final totalSales = _asInt(_summary['total_transactions']);
    final salesToday = _asInt(_summary['transactions_today']);
    final totalItemsSold = _asInt(_summary['total_items_sold']);
    final topItemName = _summary['top_selling_item']?.toString() ?? 'N/A';
    final topItemQty = _asInt(_summary['top_item_quantity']);
    final paymentTotals = _paymentMethodTotals();
    final paymentEntries = paymentTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        _sectionTitle(
          'Performance Snapshot',
          subtitle: 'At-a-glance business performance metrics',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.0,
          children: [
            _metricGridCard(
              'Total Revenue',
              _money(totalRevenue),
              Icons.monetization_on_outlined,
              Colors.green,
            ),
            _metricGridCard(
              'Revenue Today',
              _money(revenueToday),
              Icons.today_outlined,
              Colors.teal,
            ),
            _metricGridCard(
              'Revenue This Week',
              _money(revenueThisWeek),
              Icons.calendar_view_week_outlined,
              Colors.blue,
            ),
            _metricGridCard(
              'Revenue This Month',
              _money(revenueThisMonth),
              Icons.calendar_month_outlined,
              Colors.indigo,
            ),
            _metricGridCard(
              'Total Transactions',
              totalSales.toString(),
              Icons.shopping_cart_outlined,
              Colors.deepPurple,
            ),
            _metricGridCard(
              'Transactions Today',
              salesToday.toString(),
              Icons.point_of_sale_outlined,
              Colors.purple,
            ),
            _metricGridCard(
              'Average Sale',
              _money(avgTicketSize),
              Icons.receipt_long_outlined,
              Colors.orange,
            ),
            _metricGridCard(
              'Items Sold',
              totalItemsSold.toString(),
              Icons.inventory_2_outlined,
              Colors.brown,
            ),
          ],
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.emoji_events_outlined,
                    color: Colors.amber.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Product',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topItemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$topItemQty units sold',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _sectionTitle('Top Selling Items',
            subtitle: 'Best performers by quantity and revenue'),
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
          child: _topItems.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey.shade400),
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
                  itemCount: _topItems.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (context, index) {
                    final item = _topItems[index];
                    final maxQty = _topItems
                        .map((e) => _asInt(e['total_quantity']))
                        .fold<int>(0, (max, current) => current > max ? current : max);
                    final isFirst = index == 0;
                    final name = item['item_name']?.toString() ?? 'Unknown';
                    final qty = _asInt(item['total_quantity']);
                    final revenue = _asDouble(item['total_revenue']);
                    final ratio = maxQty > 0 ? qty / maxQty : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? Colors.amber.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isFirst
                                          ? Colors.amber.shade800
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  '$qty sold',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(100),
                            backgroundColor: Colors.grey.shade200,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Revenue: ${_money(revenue)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 24),
        _sectionTitle('Payment Method Breakdown',
            subtitle: 'Based on recent transactions'),
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
          child: paymentTotals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No transaction type data available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paymentEntries.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (context, index) {
                    final entry = paymentEntries[index];
                    final share = totalRevenue > 0
                        ? (entry.value / totalRevenue) * 100
                        : 0.0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      title: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${share.toStringAsFixed(1)}% of total sales'),
                      trailing: Text(
                        _money(entry.value),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendsSummary() {
    final totalRevenue = _trendData.fold<double>(
      0,
      (sum, row) => sum + _asDouble(row['revenue']),
    );
    final totalTransactions = _trendData.fold<int>(
      0,
      (sum, row) => sum + _asInt(row['transactions']),
    );
    final totalItems = _trendData.fold<int>(
      0,
      (sum, row) => sum + _asInt(row['items_sold']),
    );
    final avgRevenuePerPeriod =
        _trendData.isEmpty ? 0.0 : totalRevenue / _trendData.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _miniInfo('Revenue', _money(totalRevenue)),
              _miniInfo('Transactions', totalTransactions.toString()),
              _miniInfo('Items Sold', totalItems.toString()),
              _miniInfo('Avg Revenue/Day', _money(avgRevenuePerPeriod)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 3),
          Text(value,
              style:
                  const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final maxRevenue = _trendData.isEmpty
        ? 0.0
        : _trendData
            .map((e) => _asDouble(e['revenue']))
            .reduce((a, b) => a > b ? a : b);

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
              _refreshTrends(selection.first);
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
        if (_trendData.isNotEmpty) _buildTrendsSummary(),
        Expanded(
          child: _trendData.isEmpty
              ? Center(
                  child: Text(
                    'No trend data available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _trendData.length,
                  itemBuilder: (context, index) {
                    final period = _trendData[index];
                    final dateLabel =
                        _formatTrendDate(period['sale_date']?.toString() ?? '');
                    final revenue = _asDouble(period['revenue']);
                    final itemsSold = _asInt(period['items_sold']);
                    final transactions = _asInt(period['transactions']);
                    final revenueRatio = maxRevenue > 0 ? revenue / maxRevenue : 0.0;

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
                        border:
                            Border.all(color: Colors.grey.shade100, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dateLabel,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _money(revenue),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: revenueRatio,
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(100),
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.green),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _trendMetric('Revenue', _money(revenue),
                                      Icons.monetization_on_outlined, Colors.green),
                                ),
                                Expanded(
                                  child: _trendMetric('Sales',
                                      transactions.toString(),
                                      Icons.shopping_cart_outlined, Colors.blue),
                                ),
                                Expanded(
                                  child: _trendMetric('Items', itemsSold.toString(),
                                      Icons.inventory_2_outlined, Colors.orange),
                                ),
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
    return _recentSales.isEmpty
        ? Center(
            child: Text(
              'No sales data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _recentSales.length,
            itemBuilder: (context, index) {
              final sale = _recentSales[index];
              final total = _asDouble(sale['total']);
              final dateLabel = _formatDateTime(sale['date']);
              final items = sale['items']?.toString();
              final txTypeRaw = sale['transaction_type']?.toString().trim();
              final txType =
                  (txTypeRaw == null || txTypeRaw.isEmpty) ? 'Unspecified' : txTypeRaw;
              final saleId = sale['sale_id']?.toString() ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              _money(total),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              txType,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Sale #$saleId',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.schedule_outlined,
                              color: Colors.grey.shade600, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.grey.shade200, height: 1),
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
                      Text(
                        (items == null || items.isEmpty)
                            ? 'No items recorded'
                            : items,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Text(
        _error ?? 'Something went wrong',
        style: TextStyle(color: Colors.grey.shade600),
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
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : TabBarView(
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



// class SalesAnalyticsPage extends StatefulWidget {
//   final List<SalesModel> sales;
  
//   const SalesAnalyticsPage({
//     required this.sales,
//     Key? key,
//   }) : super(key: key);

//   @override
//   State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
// }

// class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String _selectedPeriod = 'week';
//   final dateFormat = DateFormat('yyyy-MM-dd');
  
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   List<MapEntry<String, List<SalesModel>>> _groupSalesByPeriod() {
//     final Map<String, List<SalesModel>> grouped = {};
    
//     for (var sale in widget.sales) {
//       if (sale.date == null) continue;
      
//       String key;
//       final date = DateTime.tryParse(sale.date!);
//       if (date == null) continue;

//       switch (_selectedPeriod) {
//         case 'week':
//           // Get the week start date
//           final weekStart = date.subtract(Duration(days: date.weekday - 1));
//           key = dateFormat.format(weekStart);
//           break;
//         case 'month':
//           key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
//           break;
//         case 'year':
//           key = date.year.toString();
//           break;
//         default:
//           key = dateFormat.format(date);
//       }

//       grouped[key] = [...(grouped[key] ?? []), sale];
//     }

//     return grouped.entries.toList()
//       ..sort((a, b) => b.key.compareTo(a.key));
//   }

//   Widget _buildOverviewTab() {
//     final totalRevenue = widget.sales.fold<double>(0, (sum, sale) => sum + (sale.total ?? 0));
//     final avgTicketSize = widget.sales.isEmpty ? 0.0 : totalRevenue / widget.sales.length;
    
//     // Calculate items sold
//     int totalItemsSold = 0;
//     final itemFrequency = <String, int>{};
    
//     for (var sale in widget.sales) {
//       for (var item in sale.itemsSold ?? []) {
//         final quantity = (item.quantity as num? ?? 0).toInt();
//         totalItemsSold += quantity;
//         final itemName = item.name ?? 'Unknown';
//         itemFrequency[itemName] = (itemFrequency[itemName] ?? 0) + quantity;
//       }
//     }

//     // Get top selling items
//     final topItems = itemFrequency.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));

//     return ListView(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _metricCard(
//                 'Total Revenue',
//                 'K ${totalRevenue.toStringAsFixed(2)}',
//                 Icons.monetization_on_outlined,
//                 Colors.green,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: _metricCard(
//                 'Average Sale',
//                 'K ${avgTicketSize.toStringAsFixed(2)}',
//                 Icons.receipt_long_outlined,
//                 Colors.blue,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: _metricCard(
//                 'Total Sales',
//                 widget.sales.length.toString(),
//                 Icons.shopping_cart_outlined,
//                 Colors.purple,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: _metricCard(
//                 'Items Sold',
//                 totalItemsSold.toString(),
//                 Icons.inventory_2_outlined,
//                 Colors.orange,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 24),
//         Text(
//           'Top Selling Items',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.grey.shade800,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//             border: Border.all(color: Colors.grey.shade100, width: 1),
//           ),
//           child: topItems.isEmpty
//               ? Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Center(
//                     child: Column(
//                       children: [
//                         Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
//                         const SizedBox(height: 12),
//                         Text(
//                           'No sales data available',
//                           style: TextStyle(color: Colors.grey.shade600),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               : ListView.separated(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemCount: topItems.take(5).length,
//                   separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
//                   itemBuilder: (context, index) {
//                     final item = topItems[index];
//                     final isFirst = index == 0;
//                     return ListTile(
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                       leading: Container(
//                         width: 40,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           color: isFirst ? Colors.amber.withOpacity(0.1) : Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Center(
//                           child: Text(
//                             '#${index + 1}',
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: isFirst ? Colors.amber.shade700 : Colors.grey.shade600,
//                             ),
//                           ),
//                         ),
//                       ),
//                       title: Text(
//                         item.key,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       trailing: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: Colors.green.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.green.shade200),
//                         ),
//                         child: Text(
//                           '${item.value} sold',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green.shade700,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTrendsTab() {
//     final groupedSales = _groupSalesByPeriod();
    
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: SegmentedButton<String>(
//             segments: const [
//               ButtonSegment(value: 'week', label: Text('Weekly')),
//               ButtonSegment(value: 'month', label: Text('Monthly')),
//               ButtonSegment(value: 'year', label: Text('Yearly')),
//             ],
//             selected: {_selectedPeriod},
//             onSelectionChanged: (Set<String> selection) {
//               setState(() => _selectedPeriod = selection.first);
//             },
//             style: ButtonStyle(
//               backgroundColor: MaterialStateProperty.resolveWith<Color>(
//                 (states) => states.contains(MaterialState.selected) 
//                   ? bluePrimary 
//                   : Colors.transparent,
//               ),
//             ),
//           ),
//         ),
//         Expanded(
//           child: ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: groupedSales.length,
//             itemBuilder: (context, index) {
//               final period = groupedSales[index];
//               final totalRevenue = period.value.fold<double>(
//                 0, (sum, sale) => sum + (sale.total ?? 0),
//               );
//               final itemCount = period.value.fold<int>(
//                 0, 
//                 (sum, sale) => sum + (sale.itemsSold?.fold<int>(
//                   0, (sum, item) => sum + (item.quantity ?? 0)
//                 ) ?? 0),
//               );

//               return Container(
//                 margin: const EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.06),
//                       blurRadius: 12,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                   border: Border.all(color: Colors.grey.shade100, width: 1),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _formatPeriodHeader(period.key),
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: [
//                           Expanded(child: _trendMetric('Revenue', 'K ${totalRevenue.toStringAsFixed(2)}', Icons.monetization_on_outlined, Colors.green)),
//                           Expanded(child: _trendMetric('Sales', period.value.length.toString(), Icons.shopping_cart_outlined, Colors.blue)),
//                           Expanded(child: _trendMetric('Items', itemCount.toString(), Icons.inventory_2_outlined, Colors.orange)),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDetailsTab() {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: widget.sales.length,
//       itemBuilder: (context, index) {
//         final sale = widget.sales[index];
//         return Container(
//           margin: const EdgeInsets.only(bottom: 16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.06),
//                 blurRadius: 12,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//             border: Border.all(color: Colors.grey.shade100, width: 1),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.green.shade200),
//                       ),
//                       child: Text(
//                         'K ${(sale.total ?? 0).toStringAsFixed(2)}',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green.shade700,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     Text(
//                       sale.date ?? 'Unknown date',
//                       style: TextStyle(
//                         color: Colors.grey.shade600,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//                 if (sale.itemsSold?.isNotEmpty ?? false) ...[
//                   const SizedBox(height: 16),
//                   Divider(color: Colors.grey.shade200),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Items Sold',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       color: Colors.grey.shade800,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   ...sale.itemsSold!.map((item) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 6,
//                           height: 6,
//                           decoration: BoxDecoration(
//                             color: bluePrimary,
//                             borderRadius: BorderRadius.circular(3),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             item.name ?? 'Unknown item',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Text(
//                             '${item.quantity ?? 0}x',
//                             style: TextStyle(
//                               color: Colors.grey.shade700,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )),
//                 ],
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   String _formatPeriodHeader(String key) {
//     switch (_selectedPeriod) {
//       case 'week':
//         final date = dateFormat.parse(key);
//         final weekEnd = date.add(const Duration(days: 6));
//         return 'Week of ${DateFormat('MMM d').format(date)} - ${DateFormat('MMM d').format(weekEnd)}';
//       case 'month':
//         final parts = key.split('-');
//         return DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])));
//       case 'year':
//         return key;
//       default:
//         return key;
//     }
//   }

//   Widget _metricCard(String title, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: Border.all(color: Colors.grey.shade100, width: 1),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             padding: const EdgeInsets.all(12),
//             child: Icon(icon, color: color, size: 24),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.grey.shade700,
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               height: 1.1,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _trendMetric(String label, String value, IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, color: color, size: 20),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sales Analytics'),
//         backgroundColor: bluePrimary,
//         elevation: 0,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           indicatorWeight: 3,
//           tabs: const [
//             Tab(text: 'Overview'),
//             Tab(text: 'Trends'),
//             Tab(text: 'Details'),
//           ],
//         ),
//       ),
//       backgroundColor: const Color(0xFFF5F6FA),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildOverviewTab(),
//           _buildTrendsTab(),
//           _buildDetailsTab(),
//         ],
//       ),
//     );
//   }
// }
