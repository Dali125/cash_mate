import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/controllers/payment_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionCompletePage extends StatelessWidget {
  const TransactionCompletePage({super.key});

  String _formatCurrency(double value) => 'K ${value.toStringAsFixed(2)}';

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final PaymentController pc = Get.find<PaymentController>();
    final Config db = Get.find<Config>();
    final CartController cartController = Get.find<CartController>();
    final InventoryController inventoryController =
        Get.find<InventoryController>();

    final args = Get.arguments as Map;
    final SalesModel sale = args['sales'] as SalesModel;

    final SalesModel items = SalesModel(
      date: sale.date,
      total: sale.total,
      itemsSold: sale.itemsSold,
      transactionType: args['transaction_type'],
    );

    final List<CartItem> itemsSold = items.itemsSold ?? <CartItem>[];
    final double total = (items.total ?? 0).toDouble();
    final double amountPaid =
        double.tryParse(args['amount paid']?.toString() ?? '') ?? 0.0;
    final double change = args['change'] != null
        ? (double.tryParse(args['change'].toString()) ??
            pc.calculateChange(total, amountPaid))
        : pc.calculateChange(total, amountPaid);
    final DateTime saleDate = DateTime.tryParse(items.date ?? '') ??
        DateTime.now();
    final String receiptNumber =
        '#CM${saleDate.millisecondsSinceEpoch.toString().substring(6)}';

    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        centerTitle: true,
        backgroundColor: bluePrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: bluePrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: bluePrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receipt ready',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review the customer receipt before saving the sale.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCE6F5),
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF6),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                            child: Column(
                              children: [
                                Text(
                                  'CASHMATE',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                    color: bluePrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Sales Receipt',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _metaRow('Receipt No.', receiptNumber),
                                _metaRow(
                                  'Payment',
                                  (items.transactionType ?? 'N/A').toString(),
                                ),
                                _metaRow('Date', _formatDate(saleDate)),
                              ],
                            ),
                          ),
                          _dashedDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                            child: Row(
                              children: [
                                Text(
                                  'ITEM',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .8,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'QTY',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .8,
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Text(
                                  'AMOUNT',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
                              itemCount: itemsSold.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final item = itemsSold[index];
                                final qty = item.quantity ?? 0;
                                final price = (item.price ?? 0).toDouble();
                                final lineTotal = price * qty;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name?.toString() ??
                                                'Unknown Item',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '@ ${_formatCurrency(price)} each',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '$qty',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 90,
                                      child: Text(
                                        _formatCurrency(lineTotal),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          _dashedDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                            child: Column(
                              children: [
                                _summaryRow('Subtotal', _formatCurrency(total)),
                                _summaryRow(
                                    'Amount Paid', _formatCurrency(amountPaid)),
                                _summaryRow('Change', _formatCurrency(change),
                                    valueColor: Colors.green.shade700),
                                const SizedBox(height: 6),
                                _summaryRow(
                                  'TOTAL',
                                  _formatCurrency(total),
                                  emphasized: true,
                                ),
                              ],
                            ),
                          ),
                          _dashedDivider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                            child: Column(
                              children: [
                                const Text(
                                  'Thank you for your purchase',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
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
                                    letterSpacing: .3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Button(
                width: double.infinity,
                height: 52,
                color: bluePrimary,
                text: 'Record Purchase',
                onPressed: () async {
                  await db.addSale(items);
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
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

  Widget _summaryRow(
    String label,
    String value, {
    bool emphasized = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
              color: emphasized ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 18 : 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (emphasized ? bluePrimary : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
