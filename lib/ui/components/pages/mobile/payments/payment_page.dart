import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _cashController = TextEditingController();
  late final SalesModel sale;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    sale = args is SalesModel ? args : (args['sales'] as SalesModel);
    sale.total ??= 0.0; // ensure not null
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _proceedPayment({required String method, required double amountPaid}) {
    final total = sale.total ?? 0.0;
    final changeRaw = method == 'Cash' ? (amountPaid - total) : 0.0;
    final change = changeRaw < 0 ? 0.0 : changeRaw;
    final map = {
      'sales': sale,
      'transaction_type': method,
      'amount paid': amountPaid.toStringAsFixed(2),
      'change': change.toStringAsFixed(2),
    };
    Get.toNamed('/transaction_complete', arguments: map);
  }

  Future<void> _showCashSheet() async {
    _cashController.clear();

    final total = sale.total ?? 0.0;
    var cashValue = 0.0;
    var cashValid = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void recalcCash() {
              final txt = _cashController.text.trim();
              final val = double.tryParse(txt) ?? 0.0;
              setModalState(() {
                cashValue = val;
                cashValid = val >= total && val > 0;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    Text(
                      'Cash Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: bluePrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Due: K ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _cashController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^[0-9]*[.]?[0-9]{0,2}'),
                        ),
                      ],
                      onChanged: (_) => recalcCash(),
                      decoration: InputDecoration(
                        labelText: 'Amount Received',
                        prefixIcon: const Icon(Icons.payments_outlined),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: bluePrimary.withOpacity(.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: bluePrimary, width: 1.4),
                        ),
                        helperText: cashValue > 0 && !cashValid
                            ? 'Amount is less than total'
                            : null,
                        errorText: cashValue > 0 && !cashValid
                            ? 'Insufficient amount'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (cashValid)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Change:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'K ${(cashValue - total).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              cashValid ? bluePrimary : Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: cashValid ? 4 : 0,
                        ),
                        onPressed: cashValid
                            ? () {
                                Navigator.pop(sheetContext);
                                _proceedPayment(
                                  method: 'Cash',
                                  amountPaid: cashValue,
                                );
                              }
                            : null,
                        label: const Text(
                          'Confirm Cash Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDialog(
      {required String title,
      required String content,
      required VoidCallback onYes}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onYes();
              },
              child: const Text('Yes')),
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final total = sale.total ?? 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: bluePrimary.withOpacity(.1),
              child: Icon(Icons.point_of_sale, color: bluePrimary, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount Due',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey)),
                  Text('K ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: bluePrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption(
      {required String title,
      required String asset,
      required VoidCallback onTap,
      Color? color,
      IconData? icon,
      String? subtitle}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: asset.isNotEmpty
                    ? Image.asset(asset, fit: BoxFit.contain)
                    : CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            (color ?? bluePrimary).withOpacity(.12),
                        child:
                            Icon(icon, color: color ?? bluePrimary, size: 34)),
              ),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log(sale.toJson().toString(), time: DateTime.now());
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 640;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: bluePrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(context),
            const SizedBox(height: 18),
            Text('Select Payment Method',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bluePrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: isWide ? 3 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: .95,
                children: [
                  _paymentOption(
                    title: 'Cash',
                    asset: 'assets/money.png',
                    subtitle: 'Accept & give change',
                    onTap: _showCashSheet,
                  ),
                  _paymentOption(
                    title: 'Mobile Money',
                    asset: 'assets/mobile_money.png',
                    subtitle: 'Exact amount only',
                    onTap: () => _confirmDialog(
                      title: 'Mobile Money',
                      content:
                          'Confirm full payment via mobile money? No change allowed.',
                      onYes: () => _proceedPayment(
                          method: 'Mobile Money',
                          amountPaid: (sale.total ?? 0.0)),
                    ),
                  ),
                  _paymentOption(
                    title: 'Nkongole',
                    asset: 'assets/debt.png',
                    subtitle: 'Record as debt',
                    onTap: () => _confirmDialog(
                      title: 'Record Debt',
                      content: 'Record this sale as debt (Nkongole)?',
                      onYes: () =>
                          _proceedPayment(method: 'Nkongole', amountPaid: 0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
