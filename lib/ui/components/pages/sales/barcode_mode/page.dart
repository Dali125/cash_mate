import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/ui/components/pages/inventory/barcode/summary/page.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:showcaseview/showcaseview.dart';

/// Implementation of Mobile Scanner example with simple configuration
class BarcodeModeScannerPage extends StatefulWidget {
  /// Constructor for simple Mobile Scanner example
  const BarcodeModeScannerPage({super.key});

  @override
  State<BarcodeModeScannerPage> createState() => _BarcodeModeScannerPageState();
}

class _BarcodeModeScannerPageState extends State<BarcodeModeScannerPage> {
  String? _barcode;
  List<String> scannedValues = [];
  final Config db = Get.find<Config>();
  final CartController cartController = Get.find<CartController>();
  AudioPlayer audioPlayer = AudioPlayer();
  static final GlobalKey _totalAmount = GlobalKey();
  static final GlobalKey _confirmTransactionButton = GlobalKey();

  @override
  void initState() {
    super.initState();
    audioPlayer.setVolume(1.0); // Explicitly set volume to maximum
    try {
      audioPlayer.setAsset(
          'assets/audio/scan_audio.mp3'); // Ensure audio is loaded before use
    } catch (error) {
      if (kDebugMode) {
        print('Error loading audio asset: $error');
      }
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    _barcode = barcodes.barcodes.first.rawValue;

    // Check if the barcode is already scanned
    if (_barcode != null && !scannedValues.contains(_barcode)) {
      addValueToList(_barcode);
      final item = await db.fetchItemByBarcode(_barcode as String);
      if (item != null) {
        if (kDebugMode) {
          print('Item found for barcode: $_barcode');
        }
        final String name = item.name;
        final double price = item.price;
        final int quantity = item.quantity;
        Map<String, dynamic> itemData = {
          "name": name,
          "price": price,
          "quantity": quantity,
        };
        // Check if barcode is part of similar item, then increment that items count

        List<CartItem> cartItems = cartController.cart.toList();
        for (CartItem cartItem in cartItems) {
          if (cartItem.id != null && item.id == cartItem.id) {
            cartController.incrementQuantity(cartItems.indexOf(cartItem));
            return;
          }
        }

        cartController.addToCart(itemData, quantity);
        if (kDebugMode) {
          print('No item found for barcode: $_barcode');
        }
      }

      // Ensure the audio player    \8is not already playing
      if (audioPlayer.playing) {
        await audioPlayer.stop();
      }

      // Reset the audio player to the beginning and play
      await audioPlayer.seek(Duration.zero);
      await audioPlayer.play();
    } else {
      if (kDebugMode) {
        print("Duplicate barcode scanned: $_barcode");
      }
    }
  }

  void addValueToList(String? scannedCode) {
    // Check
    if (scannedCode == null) return;

    if (scannedValues.isEmpty) {
      //Add initial value
      scannedValues.add(scannedCode);
      audioPlayer.play();
    } else {
      //Check for duplicates
      if (!scannedValues.contains(scannedCode)) {
        audioPlayer.play();
        scannedValues.add(scannedCode);
      } else {
        if (kDebugMode) {
          print("Duplicate barcode scanned: $scannedCode");
        }
      }
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Mode')),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              onDetect: _handleBarcode,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                alignment: Alignment.bottomCenter,
                height: 100,
                color: const Color.fromRGBO(0, 0, 0, 0.4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      child: Text("Complete Scan"),
                      onPressed: () {
                        Get.back();
                        Get.to(() =>
                            BarcodeSummaryPage(scannedValues: scannedValues));
                      },
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 100,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: .4,
                  minChildSize: .14,
                  maxChildSize: 1.0,
                  snapSizes: [
                    .14,
                    .4,
                    .7,
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
                                    key: GlobalKey(),
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
