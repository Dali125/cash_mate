import 'dart:developer';
import 'dart:io';

import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Config extends GetxController {
  Database? _database;
  DatabaseFactory? db;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(Duration.zero, () {
      initDatabase();
    });
  }

  /// Initialize SQLite database
  Future<void> initDatabase() async {
    try {
      if (Platform.isWindows || Platform.isLinux) {
        // Initialize FFI
        var databaseFactory = databaseFactoryFfi;
        String path = join(await getDatabasesPath(), 'cash_app.db');
        _database = await databaseFactory.openDatabase(path);
        await _database!.execute(
          'CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, quantity INTEGER, image_url TEXT)',
        );
        await _database!.execute(
          'CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, items_sold TEXT, date TEXT, amount REAL)',
        );
      } else if (Platform.isAndroid) {
        String path = join(await getDatabasesPath(), 'cash_app.db');
        _database = await openDatabase(
          path,
          version: 2,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, quantity INTEGER, image_url TEXT)',
            );
            await db.execute(
              'CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, items_sold TEXT, date TEXT, amount REAL)',
            );
          },
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize database: ${e.toString()}');
    }
  }

  /// Fetch all inventory items
  Future<List<Map<String, dynamic>>?> getInventory(
      {String? searchQuery}) async {
    try {
      if (_database == null)
        await initDatabase(); // Ensure database is initialized
      if (searchQuery != null) {
        return await _database?.rawQuery(
          'SELECT * FROM inventory WHERE name LIKE ?',
          ['%$searchQuery%'],
        );
      }
      return await _database?.rawQuery('SELECT * FROM inventory');
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch inventory: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>> getSalesSummary() async {
    try {
      if (_database == null) {
        await initDatabase();
        if (_database == null) {
          return {
            'total_sales': 0.0,
            'total_items_sold': 0,
            'recent_sales': []
          };
        }
      }
      final totalSales = await _database!
          .rawQuery('SELECT SUM(amount) as total_sales FROM sales_history');
      final totalItemsSold = await _database!
          .rawQuery('SELECT COUNT(*) as total_items_sold FROM sales_history');
      final recentSales = await _database!
          .rawQuery('SELECT * FROM sales_history ORDER BY date DESC LIMIT 10');
      return {
        'total_sales': totalSales[0]['total_sales'],
        'total_items_sold': totalItemsSold[0]['total_items_sold'],
        'recent_sales': recentSales
      };
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch sales summary: ${e.toString()}');
      return {'total_sales': 0.0, 'total_items_sold': 0, 'recent_sales': []};
    }
  }

  Future<void> addSale(SalesModel item) async {
    List<CartItem> itemsSold = item.itemsSold!;
    Map<int, dynamic> itemMap = {};
    for (int i = 0; i < itemsSold.length; i++) {
      itemMap[i] = itemsSold[i].toJson();
    }

    print(itemMap);
    try {
      if (_database == null) {
        await initDatabase();
        if (_database == null) {
          Get.snackbar('Error', 'Database initialization failed');
          return;
        }
      }
      await _database!.insert(
        'sales_history',
        {
          'items_sold': itemMap,
          'date': item.date,
          'amount': item.total,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Decrement quantity
      for (var item in item.itemsSold!) {
        await _database!.rawUpdate(
          'UPDATE inventory SET quantity = quantity - ? WHERE name = ?',
          [item.quantity, item.name],
        );
      }
      Get.snackbar('Success', 'Sale recorded successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add sale: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>?> getSalesHistory() async {
    try {
      if (_database?.isOpen == true) {
        log(_database?.path as String);
      }
      List<Map<String, dynamic>> query =
          await _database!.rawQuery('SELECT * FROM sales_history');

      return query;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch sales history: ${e.toString()}');
      return null;
    }
  }

  Future<void> addInventory(Item item) async {
    try {
      if (_database == null) {
        await initDatabase();
        if (_database == null) {
          Get.snackbar('Error', 'Database initialization failed');
          return;
        }
      }
      await _database!.insert(
        'inventory',
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      Get.snackbar('Success', 'Item added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add inventory item: ${e.toString()}');
    }
  }

  Future<void> updateInventory(int id, Item item) async {
    try {
      if (_database == null) {
        await initDatabase();
        if (_database == null) {
          Get.snackbar('Error', 'Database initialization failed');
          return;
        }
      }
      await _database!.update(
        'inventory',
        item.toJson(),
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update inventory item: ${e.toString()}');
    }
  }

  Future<void> deleteInventory(int id) async {
    try {
      if (_database == null) {
        await initDatabase();
        if (_database == null) {
          Get.snackbar('Error', 'Database initialization failed');
          return;
        }
      }
      await _database!.delete('inventory', where: 'id = ?', whereArgs: [id]);
      Get.snackbar('Success', 'Item deleted successfully',
          backgroundColor: bluePrimary, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete inventory item: ${e.toString()}');
    }
  }
}
