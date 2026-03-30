import 'dart:async';
import 'dart:io';

import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesPageTablet extends StatefulWidget {
  const SalesPageTablet({super.key});

  @override
  State<SalesPageTablet> createState() => _SalesPageTabletState();
}

class _SalesPageTabletState extends State<SalesPageTablet> {
  final CartController cartController = Get.find<CartController>();
  final db = Get.find<Config>();
  final TextEditingController _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>?>? _inventoryFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _inventoryFuture = db.getInventory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _inventoryFuture = db.getInventory(searchQuery: value.trim());
      });
    });
  }

  Widget _buildItemImage(String imagePath) {
    if (imagePath.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined,
          size: 42, color: Colors.grey);
    }

    final bool looksLikeUrl = imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('blob:') ||
        imagePath.startsWith('data:');

    if (kIsWeb) {
      if (looksLikeUrl) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 42, color: Colors.grey),
        );
      }
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 42, color: Colors.grey),
      );
    }

    if (looksLikeUrl) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image, size: 42, color: Colors.grey),
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, size: 42, color: Colors.grey),
    );
  }

  int _itemCrossAxisCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 1700) return 6;
    if (width > 1400) return 5;
    if (width > 1100) return 4;
    return 3;
  }

  Widget _buildCatalogPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F4),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: bluePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.storefront, color: bluePrimary),
              ),
              const SizedBox(width: 10),
              const Text(
                'Items',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search items...',
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>?>(
              future: _inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data;
                if (items == null || items.isEmpty) {
                  return const Center(
                      child: Text('No inventory data available'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.only(top: 2, right: 2),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _itemCrossAxisCount(context),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final String name = (item['name'] ?? 'Item').toString();
                    final int qty = (item['quantity'] as num?)?.toInt() ?? 0;
                    final double price =
                        (item['price'] as num?)?.toDouble() ?? 0;
                    final String imagePath =
                        (item['image_url'] ?? '').toString();
                    final bool outOfStock = qty < 1;

                    return Obx(() {
                      final selected = cartController.cart
                          .any((cartItem) => cartItem.name == name);

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: outOfStock
                            ? null
                            : () => cartController.addToCart(item, qty),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? bluePrimary.withValues(alpha: 0.45)
                                  : Colors.grey.shade200,
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.amber.withValues(alpha: 0.22),
                                      shape: BoxShape.circle,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _buildItemImage(imagePath),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'K ${price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: bluePrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (selected)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: bluePrimary,
                                    child: const Icon(Icons.check,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              if (outOfStock)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'OUT OF STOCK',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel() {
    return Obx(() {
      final cartItems = cartController.cart;
      final total = cartController.total.value;
      final bool disabled = total <= 0;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Checkout',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    flex: 4,
                    child: Text('Item Name',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Price',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 18),
              Expanded(
                child: cartItems.isEmpty
                    ? const Center(child: Text('Cart is empty'))
                    : ListView.separated(
                        itemCount: cartItems.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 12, thickness: 0.5),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.name ?? 'Item',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          cartController.decrementQuantity(
                                              index, item.quantity ?? 0),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child:
                                            const Icon(Icons.remove, size: 14),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        '${item.quantity ?? 0}',
                                        style: TextStyle(
                                            color: bluePrimary,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => cartController
                                          .incrementQuantity(index),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          border:
                                              Border.all(color: Colors.grey),
                                        ),
                                        child: const Icon(Icons.add, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  (item.price ?? 0).toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              const Divider(height: 18),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Coupon Code',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text(
                    total.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: disabled ? Colors.grey : bluePrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        disabled ? Colors.grey.shade400 : bluePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: disabled
                      ? null
                      : () {
                          final sale = SalesModel(
                            date: DateTime.now().toIso8601String(),
                            total: total,
                            itemsSold: cartController.cart,
                          );
                          Get.toNamed('/payment_page', arguments: sale);
                        },
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.snackbar(
                          'Hold Order',
                          'Order has been held locally.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                      child: const Text('Hold Order'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: cartItems.isEmpty
                          ? null
                          : () => cartController.clearCart(),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            children: [
              Container(
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text('POS',
                        style: TextStyle(
                            color: bluePrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24)),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 7, child: _buildCatalogPanel()),
                    const SizedBox(width: 12),
                    SizedBox(width: 380, child: _buildCheckoutPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
