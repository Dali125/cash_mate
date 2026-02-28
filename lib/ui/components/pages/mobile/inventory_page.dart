import 'dart:io';
import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final inventoryController = Get.find<InventoryController>();
  final pc = Get.find<PageControllers>();
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  Future<void> _refresh() async {
    await inventoryController.fetchInventory(
        query: _searchController.text.trim());
  }

  void _onSearchChanged(String val) {
    inventoryController.fetchInventory(query: val.trim());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text('Inventory',
            style: TextStyle(
                fontSize: 26, color: bluePrimary, fontWeight: FontWeight.bold)),
      ),
      // ExpandableFab moved to RootPage

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _SearchField(
                    controller: _searchController, onChanged: _onSearchChanged),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 8)),
            Obx(
              () {
                if (inventoryController.isLoading.value &&
                    inventoryController.mainInventoryList.isEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _SkeletonCard(index: index),
                      childCount: 6,
                    ),
                  );
                }

                final data = inventoryController.mainInventoryList;
                if (data.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _CenteredMessage(
                      icon: Icons.inventory_2_outlined,
                      text: 'No inventory items found',
                      color: Colors.grey.shade500,
                    ),
                  );
                }
                _anim.forward(from: 0);
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final itemData = data[index];
                      return _InventoryCard(
                        itemData: itemData,
                        animation: CurvedAnimation(
                          parent: _anim,
                          curve: Interval(index / data.length, 1,
                              curve: Curves.easeOutBack),
                        ),
                      );
                    },
                    childCount: data.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search inventory',
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
      onChanged: onChanged,
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final Animation<double> animation;
  const _InventoryCard({required this.itemData, required this.animation});

  @override
  Widget build(BuildContext context) {
    final imagePath = itemData['image_url'] ?? '';
    final dynamic rawPrice = itemData['price'];
    final num? parsedPrice =
        rawPrice is num ? rawPrice : num.tryParse(rawPrice?.toString() ?? '');
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero)
            .animate(animation),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () =>
                  Get.toNamed('/inventory-item-overview', arguments: itemData),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Hero(
                      tag: 'inv-img-${itemData['id']}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 90,
                          width: 90,
                          color: Colors.blueGrey.withOpacity(.05),
                          child: imagePath.toString().isNotEmpty
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.redAccent),
                                )
                              : Icon(Icons.image_outlined,
                                  size: 40, color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemData['name'] ?? 'Unnamed',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              _Chip(
                                  label:
                                      'Price: K ${parsedPrice?.toStringAsFixed(2) ?? '--'}'),
                              _Chip(label: 'Qty: ${itemData['quantity']}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: Icon(Icons.edit_outlined, color: blueSecondary),
                          onPressed: () => Get.toNamed('/edit-inventory',
                              arguments: itemData),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) =>
                                  _DeleteDialog(itemData: itemData),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _CenteredMessage({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120.0),
      child: Column(
        children: [
          Icon(icon, size: 54, color: color ?? Colors.grey),
          const SizedBox(height: 18),
          Text(text,
              style: TextStyle(
                  fontSize: 16, color: color ?? Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final Map<String, dynamic> itemData;
  const _DeleteDialog({required this.itemData});

  @override
  Widget build(BuildContext context) {
    final inventoryDB = Get.find<Config>();
    return AlertDialog(
      title: const Text('Delete Item'),
      content: Text('Are you sure you want to delete "${itemData['name']}"?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            final inventoryController = Get.find<InventoryController>();
            await inventoryDB.deleteInventory(itemData['id'] as int);
            await inventoryController.fetchInventory();
            Navigator.pop(context);
            // Trigger refresh via Get.back result or stateful parent refresh
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Item deleted')));
            }
          },
          child:
              const Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final int index;
  const _SkeletonCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: ShimmerWidget(
          height: 110,
          width: double.infinity,
          delay: Duration(milliseconds: index * 90)),
    );
  }
}

class ShimmerWidget extends StatefulWidget {
  final double height;
  final double width;
  final Duration delay;
  const ShimmerWidget(
      {super.key,
      required this.height,
      required this.width,
      required this.delay});

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade200,
                Colors.grey.shade300
              ],
              stops: [
                (_c.value - .3).clamp(0, 1),
                _c.value,
                (_c.value + .3).clamp(0, 1)
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
        );
      },
    );
  }
}
