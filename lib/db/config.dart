import 'dart:developer';
import 'dart:io';

import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Config extends GetxController {
  Database? _database;
  DatabaseFactory? db;
  Box? dbHive;

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
      String path = join(await getDatabasesPath(), 'cash_app.db');
      _database = await openDatabase(
        path,
        version: 4,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, quantity INTEGER, image_url TEXT)',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, items_sold TEXT, transaction_type TEXT, date TEXT, amount REAL)',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, company_name TEXT, number_of_logins INTEGER, isDarkMode INTEGER)',
          );
        },
      );
    } catch (e) {}
  }

  /// Fetch all inventory items
  Future<List<Map<String, dynamic>>?> getInventory(
      {String? searchQuery}) async {
    try {
      if (_database == null) {
        await initDatabase(); // Ensure database is initialized
      }

      if (searchQuery != null) {
        return await _database?.rawQuery(
          'SELECT * FROM inventory WHERE name LIKE ?',
          ['%$searchQuery%'],
        );
      }
      return await _database?.rawQuery('SELECT * FROM inventory');
    } catch (e) {
      return null;
    }
  }

  Future<int> getNumberOfLogins() async {
    
    try{
      if(_database == null){
        
        await initDatabase();
        if(_database == null){
          return 0;
        }
      }
      final numberOfLogins = await _database!.rawQuery('SELECT number_of_logins FROM users');

      return numberOfLogins[0]['number_of_logins'] as int;

    }
    catch(e){

return 0;
    }
  }

    Future updateNumberOfLogins() async {
    
    try{
      if(_database == null){
        
        await initDatabase();
        if(_database == null){
          return 0;
        }
      }
     await _database!.rawQuery('UPDATE users SET number_of_logins = number_of_logins + 1');

    }
    catch(e){

      Get.showSnackbar(GetSnackBar(
        title: 'Error',
        message: 'Failed to update number of logins: Reason: ${e.toString()}',
      ));


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
            'sales_today': 0,
            'alltime_sales': 0,
            'today_revenue': 0,
            'alltime_revenue': 0,
            'recent_sales': []
          };
        }
      }
      final currentDate = DateTime.now().toString();

      final allDates =
          await _database!.rawQuery('SELECT date FROM sales_history');
      final today = DateTime.now();
      final todayDates = allDates.where((row) {
        final date = DateTime.parse(row['date'] as String);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      }).toList();
      final allTimeRevenue = await _database!
          .rawQuery('SELECT SUM(amount) as alltime_sales FROM sales_history');
      final allTimeSales = await _database!
          .rawQuery('SELECT count(amount) as alltime_sales FROM sales_history');
      final totalSales = await _database!
          .rawQuery('SELECT SUM(amount) as total_sales FROM sales_history');
      final totalItemsSold = await _database!
          .rawQuery('SELECT COUNT(*) as total_items_sold FROM sales_history');
      final recentSales = await _database!
          .rawQuery('SELECT * FROM sales_history ORDER BY date DESC LIMIT 10');
         


      final sales_today =
          await _database!.rawQuery('SELECT *  FROM sales_history');

      double totalToday = 0;
      final todayD = DateTime.now();
      final todayDateOnly = todayD.year.toString() +
          '-' +
          todayD.month.toString() +
          '-' +
          todayD.day.toString();
      sales_today.forEach((element) {
        DateTime date = DateTime.parse(element['date'] as String);
        final dateOnly = date.year.toString() +
            '-' +
            date.month.toString() +
            '-' +
            date.day.toString();

        if (dateOnly == todayDateOnly) {
          final amount = element['amount'] as double;

          totalToday = totalToday + amount;
        }
      });

    

      return {
        'total_sales': totalSales[0]['total_sales'] ?? 0.0,
        'sales_today': todayDates.length,
        'today_revenue': totalToday,
        'alltime_revenue': allTimeRevenue[0]['alltime_revenue'],
        'alltime_sales': allTimeSales[0]["alltime_sales"],
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
          'transaction_type': item.transactionType,
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
      if (Platform.isAndroid && _database == null) {
        await initDatabase();
        if (_database == null) {
          Get.snackbar('Error', 'Database initialization failed');
          return;
        }
      } else if (Platform.isWindows) {
        await dbHive?.put("inventory", item.toJson());
      } else {
        await _database!.insert(
          'inventory',
          item.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        Get.snackbar('Success', 'Item added successfully');
      }
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
