import 'package:cash_app/ui/components/pages/inventory/barcode/summary/page.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Implementation of Mobile Scanner with continuous scanning
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  List<String> scannedValues = [];
  AudioPlayer audioPlayer = AudioPlayer();
  MobileScannerController? _controller;
  String? _lastScannedBarcode;
  late AnimationController _pulseController;

  // Debounce/cooldown to prevent rapid scanning
  bool _isProcessing = false;
  DateTime? _lastScanTime;
  static const _scanCooldown = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed
          .noDuplicates, // Changed to prevent duplicate detections
      facing: CameraFacing.back,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await audioPlayer.setVolume(1.0);
      await audioPlayer.setAsset('assets/audio/scan_audio.mp3');
    } catch (error) {
      debugPrint('Error loading audio asset: $error');
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    // Prevent processing if already handling a scan
    if (_isProcessing) return;

    // Cooldown check
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!) < _scanCooldown) {
      return;
    }

    final barcode = barcodes.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    // Skip if already scanned
    if (scannedValues.contains(barcode)) {
      return;
    }

    _isProcessing = true;
    _lastScanTime = now;

    setState(() {
      _lastScannedBarcode = barcode;
      scannedValues.add(barcode);
    });

    // Play sound feedback without blocking
    _playFeedbackSound();

    // Reset processing flag after cooldown
    Future.delayed(_scanCooldown, () {
      _isProcessing = false;
    });
  }

  Future<void> _playFeedbackSound() async {
    try {
      await audioPlayer.seek(Duration.zero);
      audioPlayer.play(); // Don't await - let it play in background
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _removeBarcode(int index) {
    setState(() {
      scannedValues.removeAt(index);
      if (scannedValues.isEmpty) {
        _lastScannedBarcode = null;
      }
    });
  }

  void _completeScan() {
    if (scannedValues.isEmpty) {
      Get.snackbar(
        'No Barcodes',
        'Please scan at least one barcode before completing',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    Get.back();
    Get.to(() => BarcodeSummaryPage(scannedValues: scannedValues));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcodes'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (scannedValues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bluePrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${scannedValues.length} scanned',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Scanner area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleBarcode,
                  ),
                  // Scanning frame overlay
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 280,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: bluePrimary.withOpacity(
                                  0.5 + (_pulseController.value * 0.5)),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        );
                      },
                    ),
                  ),
                  // Instructions
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Position barcode within frame',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  // Last scanned feedback
                  if (_lastScannedBarcode != null)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: _LastScannedBadge(barcode: _lastScannedBarcode!),
                    ),
                ],
              ),
            ),

            // Bottom panel with scanned list
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.qr_code_2, color: bluePrimary),
                              const SizedBox(width: 8),
                              const Text(
                                'Scanned Barcodes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (scannedValues.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  scannedValues.clear();
                                  _lastScannedBarcode = null;
                                });
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Scanned list
                    Expanded(
                      child: scannedValues.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No barcodes scanned yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: scannedValues.length,
                              itemBuilder: (context, index) {
                                final barcode = scannedValues[index];
                                return _ScannedBarcodeItem(
                                  barcode: barcode,
                                  index: index + 1,
                                  onRemove: () => _removeBarcode(index),
                                );
                              },
                            ),
                    ),

                    // Complete button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _completeScan,
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          label: Text(
                            scannedValues.isEmpty
                                ? 'Complete Scan'
                                : 'Complete Scan (${scannedValues.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bluePrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastScannedBadge extends StatelessWidget {
  final String barcode;
  const _LastScannedBadge({required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scanned!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  barcode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedBarcodeItem extends StatelessWidget {
  final String barcode;
  final int index;
  final VoidCallback onRemove;

  const _ScannedBarcodeItem({
    required this.barcode,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bluePrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: bluePrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
