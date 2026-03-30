import 'dart:io';

import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryPageTablet extends StatefulWidget {
  const InventoryPageTablet({super.key});

  @override
  State<InventoryPageTablet> createState() => _InventoryPageTabletState();
}

class _InventoryPageTabletState extends State<InventoryPageTablet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final inventoryController = Get.find<InventoryController>();
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    inventoryController.fetchInventory();
  }

  Future<void> _refresh() async {
    await inventoryController.fetchInventory(
      query: _searchController.text.trim(),
    );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    inventoryController.fetchInventory(query: value.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _anim.dispose();
    super.dispose();
  }

  int _crossAxisCount(double width) {
    if (width >= 1700) return 4;
    if (width >= 1250) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory',
                            style: TextStyle(
                              fontSize: 34,
                              color: bluePrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Search, review, edit, and manage stock across your catalog.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/add-inventory'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bluePrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Add Item'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _TabletSearchField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onClear: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Obx(() {
                        final items = inventoryController.mainInventoryList;
                        final lowStock = items.where((item) {
                          final quantity = (item['quantity'] as num?) ?? 0;
                          return quantity < 10;
                        }).length;

                        return Row(
                          children: [
                            Expanded(
                              child: _InfoPill(
                                icon: Icons.inventory_2_outlined,
                                label: 'Items',
                                value: items.length.toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _InfoPill(
                                icon: Icons.warning_amber_outlined,
                                label: 'Low Stock',
                                value: lowStock.toString(),
                                accent: lowStock > 0
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (inventoryController.isLoading.value &&
                  inventoryController.mainInventoryList.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          _crossAxisCount(MediaQuery.sizeOf(context).width),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.08,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TabletSkeletonCard(index: index),
                      childCount: 6,
                    ),
                  ),
                );
              }

              final data = inventoryController.mainInventoryList;
              if (data.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 140),
                    child: _TabletCenteredMessage(
                      icon: Icons.inventory_2_outlined,
                      text: 'No inventory items found',
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }

              _anim.forward(from: 0);

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final count = _crossAxisCount(constraints.crossAxisExtent);

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: count >= 4
                            ? 1.16
                            : count == 3
                                ? 1.08
                                : 1.02,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final itemData = data[index];
                          return _TabletInventoryCard(
                            itemData: itemData,
                            animation: CurvedAnimation(
                              parent: _anim,
                              curve: Interval(
                                index / data.length,
                                1,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                          );
                        },
                        childCount: data.length,
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TabletSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _TabletSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search inventory by item name',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? bluePrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _TabletInventoryCard extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final Animation<double> animation;

  const _TabletInventoryCard({
    required this.itemData,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = (itemData['image_url'] ?? '').toString();
    final rawPrice = itemData['price'];
    final num? parsedPrice =
        rawPrice is num ? rawPrice : num.tryParse(rawPrice?.toString() ?? '');
    final quantity = (itemData['quantity'] as num?)?.toInt() ?? 0;
    final discount = (itemData['discount'] as num?)?.toDouble() ?? 0.0;
    final stockColor = quantity < 10 ? Colors.orange : Colors.green;
    final stockLabel = quantity < 1
        ? 'Out of Stock'
        : quantity < 10
            ? 'Low Stock'
            : 'In Stock';

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(animation),
        child: Material(
          elevation: 2,
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () =>
                Get.toNamed('/inventory-item-overview', arguments: itemData),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'inv-img-${itemData['id']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 92,
                            height: 92,
                            color: Colors.blueGrey.withOpacity(0.05),
                            child: imagePath.isNotEmpty
                                ? Image.file(
                                    File(imagePath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.red.shade400,
                                    ),
                                  )
                                : Icon(
                                    Icons.image_outlined,
                                    size: 42,
                                    color: Colors.grey.shade400,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemData['name']?.toString() ?? 'Unnamed',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: stockColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                stockLabel,
                                style: TextStyle(
                                  color: stockColor.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TabletChip(
                        label:
                            'Price: K ${parsedPrice?.toStringAsFixed(2) ?? '--'}',
                      ),
                      _TabletChip(label: 'Qty: $quantity'),
                      if (discount > 0)
                        _TabletChip(label: 'Discount: ${discount.toStringAsFixed(0)}%'),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Get.toNamed(
                            '/edit-inventory',
                            arguments: itemData,
                          ),
                          icon: Icon(Icons.edit_outlined, color: blueSecondary),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: blueSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showDeleteDialog(context),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final inventoryDB = Get.find<Config>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text(
          'Are you sure you want to delete "${itemData['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final inventoryController = Get.find<InventoryController>();
              await inventoryDB.deleteInventory(itemData['id'] as int);
              await inventoryController.fetchInventory();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item deleted')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletChip extends StatelessWidget {
  final String label;

  const _TabletChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _TabletCenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _TabletCenteredMessage({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 60, color: color ?? Colors.grey),
        const SizedBox(height: 18),
        Text(
          text,
          style: TextStyle(fontSize: 17, color: color ?? Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _TabletSkeletonCard extends StatelessWidget {
  final int index;

  const _TabletSkeletonCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return _TabletShimmer(
      height: double.infinity,
      width: double.infinity,
      delay: Duration(milliseconds: index * 90),
    );
  }
}

class _TabletShimmer extends StatefulWidget {
  final double height;
  final double width;
  final Duration delay;

  const _TabletShimmer({
    required this.height,
    required this.width,
    required this.delay,
  });

  @override
  State<_TabletShimmer> createState() => _TabletShimmerState();
}

class _TabletShimmerState extends State<_TabletShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
                Colors.grey.shade300,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0, 1),
                _controller.value,
                (_controller.value + 0.3).clamp(0, 1),
              ],
            ),
          ),
        );
      },
    );
  }
}
