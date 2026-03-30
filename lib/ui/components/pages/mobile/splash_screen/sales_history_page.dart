import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key});

  String _formatCurrency(dynamic amount) {
    final value = amount is num
        ? amount.toDouble()
        : double.tryParse(amount?.toString() ?? '') ?? 0.0;
    return 'K ${value.toStringAsFixed(2)}';
  }

  String _formatDate(String? rawDate) {
    final parsed = DateTime.tryParse(rawDate ?? '');
    if (parsed == null) return rawDate ?? 'Unknown date';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }

  int _extractItemCount(Map<String, dynamic> sale) {
    final directCount = sale['item_count'];
    if (directCount is num && directCount > 0) {
      return directCount.toInt();
    }

    final raw = sale['items_sold']?.toString() ?? '';
    if (raw.isEmpty) return 0;

    final matches = RegExp(r'quantity:\s*([0-9]+)').allMatches(raw);
    var total = 0;
    for (final match in matches) {
      total += int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return total;
  }

  int _extractLineItemCount(Map<String, dynamic> sale) {
    final directCount = sale['line_item_count'];
    if (directCount is num && directCount > 0) {
      return directCount.toInt();
    }

    final raw = sale['items_sold']?.toString() ?? '';
    if (raw.isEmpty) return 0;
    return RegExp(r'\d+:\s*\{').allMatches(raw).length;
  }

  String _extractPreview(Map<String, dynamic> sale) {
    final raw = sale['items_sold']?.toString() ?? '';
    if (raw.isEmpty) return 'No item details available';

    final names = RegExp(r'name:\s*([^,}]+)')
        .allMatches(raw)
        .map((match) => match.group(1)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) return 'No item details available';
    if (names.length == 1) return names.first;
    return '${names.first} + ${names.length - 1} more';
  }

  Color _paymentColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'mobile money':
        return bluePrimary;
      case 'nkongole':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _saleTitle(Map<String, dynamic> sale) {
    final paymentType = sale['transaction_type']?.toString() ?? 'Sale';
    final id = sale['id']?.toString() ?? '-';
    return '$paymentType Sale  #$id';
  }

  @override
  Widget build(BuildContext context) {
    final db = Get.find<Config>();

    return Scaffold(
      backgroundColor: appBackground,
      appBar: AppBar(
        title: const Text(
          'Sales History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        foregroundColor: bluePrimary,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: db.getSalesHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final salesHistory = snapshot.data ?? [];
          if (salesHistory.isEmpty) {
            return const Center(
              child: Text(
                'No sales history available.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: bluePrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: bluePrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent sales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${salesHistory.length} recorded transactions',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  itemCount: salesHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sale = salesHistory[index];
                    final paymentType =
                        sale['transaction_type']?.toString() ?? 'Unknown';
                    final paymentColor = _paymentColor(paymentType);
                    final itemCount = _extractItemCount(sale);
                    final lineItemCount = _extractLineItemCount(sale);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          Get.toNamed('/sales-history-detail', arguments: sale);
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: paymentColor.withValues(
                                            alpha: 0.12),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Icon(
                                        Icons.receipt,
                                        color: paymentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _saleTitle(sale),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _extractPreview(sale),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: paymentColor.withValues(
                                            alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        paymentType,
                                        style: TextStyle(
                                          color: paymentColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F9FC),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _InfoBlock(
                                          label: 'Total',
                                          value:
                                              _formatCurrency(sale['amount']),
                                          emphasized: true,
                                          valueColor: bluePrimary,
                                        ),
                                      ),
                                      Expanded(
                                        child: _InfoBlock(
                                          label: 'Items',
                                          value:
                                              '$itemCount item${itemCount == 1 ? '' : 's'}',
                                        ),
                                      ),
                                      Expanded(
                                        child: _InfoBlock(
                                          label: 'Lines',
                                          value:
                                              '$lineItemCount product${lineItemCount == 1 ? '' : 's'}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _formatDate(sale['date']?.toString()),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  const _InfoBlock({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 15 : 14,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
