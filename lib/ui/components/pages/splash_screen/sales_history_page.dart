import 'package:cash_app/db/config.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesHistoryPage extends StatelessWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Get.find<Config>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sales History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: bluePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FutureBuilder(
          future: db.getSalesHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No sales history available.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              );
            }

            final salesHistory = snapshot.data!;
            return ListView.builder(
              itemCount: salesHistory.length,
              itemBuilder: (context, index) {
                final sale = salesHistory[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: bluePrimary,
                      child:
                          const Icon(Icons.receipt_long, color: Colors.white),
                    ),
                    title: Text(
                      'Invoice ID: ${sale['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Date: ${sale['date']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      // Add navigation to a detailed sale page if necessary
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
