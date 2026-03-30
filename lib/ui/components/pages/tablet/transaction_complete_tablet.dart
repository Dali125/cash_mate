import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionCompletePageTablet extends StatelessWidget {
  const TransactionCompletePageTablet({super.key});

  SalesModel _buildSale(Map<String, dynamic> args) {
    final SalesModel source = args['sales'] as SalesModel;

    return SalesModel(
      date: source.date,
      total: source.total,
      itemsSold: source.itemsSold,
      transactionType: args['transaction_type']?.toString(),
    );
  }

  String _formatCurrency(double value) => 'K ${value.toStringAsFixed(2)}';

  String _formatDate(String? rawDate) {
    final parsed = DateTime.tryParse(rawDate ?? '');
    if (parsed == null) return 'N/A';
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }

  Future<void> _recordPurchase(SalesModel sale) async {
    final db = Get.find<Config>();
    final cartController = Get.find<CartController>();
    final inventoryController = Get.find<InventoryController>();

    await db.addSale(sale);
    await inventoryController.fetchInventory();
    cartController.clearCart();

    Get.snackbar(
      'Success',
      'Purchase recorded successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
    );
    Get.offAllNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(Get.arguments ?? {});
    final sale = _buildSale(args);
    final itemsSold = sale.itemsSold ?? <CartItem>[];
    final total = sale.total ?? 0.0;
    final amountPaid =
        double.tryParse(args['amount paid']?.toString() ?? '') ?? 0.0;
    final change = double.tryParse(args['change']?.toString() ?? '') ??
        ((amountPaid - total) > 0 ? (amountPaid - total) : 0.0);
    final parsedDate = DateTime.tryParse(sale.date ?? '') ?? DateTime.now();
    final receiptNumber =
        '#CM${parsedDate.millisecondsSinceEpoch.toString().substring(6)}';

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        backgroundColor: bluePrimary,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;

          final receiptPreview = Stack(
            children: [
              Positioned.fill(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE6F5),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF6),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
                      child: Column(
                        children: [
                          Text(
                            'CASHMATE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              color: bluePrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sales Receipt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _MetaRow(label: 'Receipt No.', value: receiptNumber),
                          _MetaRow(
                            label: 'Payment',
                            value: sale.transactionType ?? 'N/A',
                          ),
                          _MetaRow(
                            label: 'Date',
                            value: _formatDate(sale.date),
                          ),
                        ],
                      ),
                    ),
                    const _DashedDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 10),
                      child: Row(
                        children: [
                          Text(
                            'ITEM',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'QTY',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 40),
                          Text(
                            'AMOUNT',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                        itemCount: itemsSold.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = itemsSold[index];
                          final quantity = item.quantity ?? 0;
                          final price = (item.price ?? 0).toDouble();
                          final lineTotal = price * quantity;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name ?? 'Unknown Item',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '@ ${_formatCurrency(price)} each',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  '$quantity',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  _formatCurrency(lineTotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const _DashedDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 18, 28, 10),
                      child: Column(
                        children: [
                          _SummaryTile(
                            label: 'Subtotal',
                            value: _formatCurrency(total),
                          ),
                          _SummaryTile(
                            label: 'Amount Paid',
                            value: _formatCurrency(amountPaid),
                          ),
                          _SummaryTile(
                            label: 'Change',
                            value: _formatCurrency(change),
                            valueColor: Colors.green.shade700,
                          ),
                          const SizedBox(height: 8),
                          _SummaryTile(
                            label: 'TOTAL',
                            value: _formatCurrency(total),
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                    const _DashedDivider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 24),
                      child: Column(
                        children: [
                          const Text(
                            'Thank you for your purchase',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Powered by CashMate',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final summaryCard = Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bluePrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: bluePrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Receipt ready',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Review the receipt preview, then save the sale to inventory and history.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                _SummaryTile(
                  label: 'Payment Method',
                  value: sale.transactionType ?? 'N/A',
                ),
                _SummaryTile(
                  label: 'Items',
                  value: itemsSold.length.toString(),
                ),
                _SummaryTile(
                  label: 'Date',
                  value: _formatDate(sale.date),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bluePrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _recordPurchase(sale),
                    child: const Text(
                      'Record Purchase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(24),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: receiptPreview),
                      const SizedBox(width: 24),
                      SizedBox(width: 360, child: summaryCard),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(child: receiptPreview),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 330,
                        width: double.infinity,
                        child: summaryCard,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: emphasized ? Colors.black87 : Colors.grey.shade700,
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: emphasized ? 18 : 15,
              color: valueColor ?? (emphasized ? bluePrimary : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashCount = (constraints.maxWidth / 10).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              dashCount,
              (_) => Container(
                width: 6,
                height: 1.2,
                color: Colors.grey.shade400,
              ),
            ),
          );
        },
      ),
    );
  }
}
