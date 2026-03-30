import 'dart:io';
import 'dart:async';

import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/ui/components/pages/sales/barcode_mode/page.dart';
import 'package:cash_app/utils/misc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../controllers/cart_controller.dart';
import '../../../../services/device_properties.dart';
import '../../../../utils/color.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  static final GlobalKey _searchBar = GlobalKey();
  static final GlobalKey _totalAmount = GlobalKey();
  static final GlobalKey _confirmTransactionButton = GlobalKey();
  static final GlobalKey _salesCart = GlobalKey();
  final CartController cartController = Get.find<CartController>();
  final db = Get.find<Config>();
  final deviceProperties = DeviceProperties();
  final _searchController = TextEditingController();
  bool isAndroid = !kIsWeb && Platform.isAndroid;

  // New: cache inventory future & debounce
  Future<List<Map<String, dynamic>>?>? _inventoryFuture;
  Timer? _debounce;
  List<int> stockQuantities = [];

  @override
  void initState() {
    super.initState();
    _inventoryFuture = db.getInventory();
    db.getNumberOfLogins().then((value) {
      if (value < 1) {
        GetShowcaseConfig([
          _searchBar,
          _salesCart,
          _totalAmount,
          _confirmTransactionButton,
        ]);
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _inventoryFuture = db.getInventory(searchQuery: value.trim());
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    ShowcaseView.get().dismiss();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == true) {
          cartController.clearCart();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('Current Sale',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: bluePrimary,
          elevation: 0,
          actions: [
            IconButton(
                onPressed: () {
                  Get.to(() => BarcodeModeScannerPage());
                },
                icon: Icon(Icons.switch_camera))
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Showcase(
                      key: _searchBar,
                      title:
                          'Search inventory by typing the name in the search bar',
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search inventory',
                          filled: true,
                          fillColor: onBluePrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
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
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>?>(
                      future: _inventoryFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No inventory data available.'));
                        }
                        final inventoryItems = snapshot.data!;
                        // Build stock quantities _once_ per build
                        stockQuantities = inventoryItems
                            .map((e) => (e['quantity'] as num?)?.toInt() ?? 0)
                            .toList();
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                deviceProperties.isTablet(context) ? 4 : 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .74,
                          ),
                          itemCount: inventoryItems.length,
                          itemBuilder: (context, index) {
                            final itemData = inventoryItems[index];
                            final int qty = stockQuantities[index];
                            final String name =
                                (itemData['name'] ?? 'Item').toString();
                            final double? price =
                                (itemData['price'] as num?)?.toDouble();
                            double discount =
                                (itemData['discount'] as num?)?.toDouble() ??
                                    0.0;
                            final String imagePath =
                                itemData['image_url'] ?? '';
                            final bool outOfStock = qty < 1;

                            return GestureDetector(
                              onTap: outOfStock
                                  ? null
                                  : () => cartController.addToCart(
                                        itemData,
                                        stockQuantities[index],
                                      ),
                              child: AnimatedOpacity(
                                opacity: outOfStock ? 0.55 : 1,
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 8, 10, 4),
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      10, 0, 10, 0),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'K ${price?.toStringAsFixed(2) ?? '--'}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: bluePrimary,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: outOfStock
                                                              ? Colors
                                                                  .red.shade50
                                                              : Colors.green
                                                                  .shade50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          outOfStock
                                                              ? 'Out'
                                                              : 'Qty: $qty',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: outOfStock
                                                                ? Colors.red
                                                                : Colors.green
                                                                    .shade700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 6),
                                                  if (discount > 0)
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        const SizedBox(),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .orange.shade50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            'Discount: ${discount.toStringAsFixed(0)}%',
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Divider(),
                                            Expanded(
                                              child: Hero(
                                                tag:
                                                    'sale-item-${itemData['id']}',
                                                child: isAndroid
                                                    ? Image.file(
                                                        File(imagePath),
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                const Center(
                                                          child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 48,
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                      )
                                                    : Image.asset(
                                                        imagePath,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                const Center(
                                                          child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 48,
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (outOfStock)
                                          Positioned.fill(
                                            child: Container(
                                              color:
                                                  Colors.white.withOpacity(.65),
                                              child: const Center(
                                                child: RotatedBox(
                                                  quarterTurns: 0,
                                                  child: Text(
                                                    'OUT OF STOCK',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 120), // space for bottom bar
                ],
              ),
            ),
            // Improved Cart Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 100, // leave room for summary bar
              child: SizedBox(
                height: MediaQuery.of(context).size.height *
                    .82, // max height available to sheet
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: .4,
                  minChildSize: .14,
                  maxChildSize: 1.0,
                  snapSizes: [
                    .14,
                    .4,
                    1.0,
                  ],
                  snap: true,
                  builder: (context, scrollController) {
                    return Material(
                      elevation: 16,
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Obx(() {
                        final cartItems = cartController.cart;
                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                width: 60,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Showcase(
                                    description:
                                        "Items You click on will appear in the sales cart",
                                    key: _salesCart,
                                    child: Text('Sales Cart',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: bluePrimary)),
                                  ),
                                  Text('${cartItems.length} items',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (cartItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 40.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.shopping_cart_outlined,
                                        size: 60, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text('Cart is empty',
                                        style: TextStyle(
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              )
                            else
                              ...List.generate(cartItems.length, (index) {
                                final item = cartItems[index];
                                return Dismissible(
                                  key: ValueKey('${item.name}-$index'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) =>
                                      cartController.removeFromCart(index),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 4),
                                    child: Material(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      child: ListTile(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16)),
                                        title: Text(item.name.toString(),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        subtitle: Text('K ${item.price}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.remove_circle_outline),
                                              onPressed: () => cartController
                                                  .decrementQuantity(index,
                                                      item.quantity ?? 0),
                                            ),
                                            Text(item.quantity.toString(),
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              onPressed: () => cartController
                                                  .incrementQuantity(index),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
            // Bottom summary + confirm
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Obx(() {
                    final total = cartController.total.value;
                    final disabled = total == 0.0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600)),
                            Showcase(
                              title:
                                  "The Total amount of goods will be updated here",
                              key: _totalAmount,
                              child: Text('K ${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: disabled
                                          ? Colors.grey
                                          : bluePrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: Showcase(
                            description: "Click here to proceed to payment",
                            key: _confirmTransactionButton,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.check_circle_outline,
                                color: disabled
                                    ? Colors.grey.shade400
                                    : Colors.white,
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: disabled ? 0 : 4,
                                backgroundColor: disabled
                                    ? Colors.grey.shade400
                                    : bluePrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: disabled
                                  ? null
                                  : () async {
                                      final item = SalesModel(
                                        date: DateTime.now().toIso8601String(),
                                        total: total,
                                        itemsSold: cartController.cart,
                                      );
                                      Get.toNamed('/payment_page',
                                          arguments: item);
                                    },
                              label: const Text('Confirm Transaction',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
