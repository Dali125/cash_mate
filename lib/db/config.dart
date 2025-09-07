import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
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
        version: 5,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, quantity INTEGER, image_url TEXT)');
          await db.execute('CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, items_sold TEXT, transaction_type TEXT, date TEXT, amount REAL)');
          await db.execute('CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, company_name TEXT, number_of_logins INTEGER, isDarkMode INTEGER, has_seen_tutorial INTEGER DEFAULT 0)');
          await db.insert('users', {'name': 'User','company_name': 'Company','number_of_logins': 0,'isDarkMode': 0,'has_seen_tutorial':0});
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 5) {
            final cols = await db.rawQuery('PRAGMA table_info(users)');
            final hasCol = cols.any((c) => c['name'] == 'has_seen_tutorial');
            if (!hasCol) {
              await db.execute('ALTER TABLE users ADD COLUMN has_seen_tutorial INTEGER DEFAULT 0');
            }
          }
        },
      );
      // Ensure at least one user row exists
      final count = Sqflite.firstIntValue(
          await _database!.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
      if (count == 0) {
        await _database!.insert('users', {'name': 'User','company_name': 'Company','number_of_logins': 0,'isDarkMode': 0,'has_seen_tutorial':0});
      }
    } catch (e) {}
  }

  // Ensure database ready helper
  Future<Database?> _ensureDb() async {
    if (_database == null) {
      await initDatabase();
    }
    return _database;
  }

  /// Fetch all inventory items
  Future<List<Map<String, dynamic>>?> getInventory({String? searchQuery}) async {
    try {
      final db = await _ensureDb();
      if (db == null) return null;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return await db.rawQuery('SELECT * FROM inventory WHERE name LIKE ?', ['%$searchQuery%']);
      }
      return await db.rawQuery('SELECT * FROM inventory');
    } catch (e) {
      return null;
    }
  }

  Future<int> getNumberOfLogins() async {
    try {
      final db = await _ensureDb();
      if (db == null) return 0;
      final rows = await db.query('users', columns: ['number_of_logins'], limit: 1);
      if (rows.isEmpty) {
        await db.insert('users', {'name': 'User','company_name': 'Company','number_of_logins': 0,'isDarkMode': 0});
        return 0;
      }
      final val = rows.first['number_of_logins'];
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '0') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> updateNumberOfLogins() async {
    try {
      final db = await _ensureDb();
      if (db == null) return;
      final updated = await db.rawUpdate('UPDATE users SET number_of_logins = number_of_logins + 1 WHERE id = (SELECT id FROM users LIMIT 1)');
      if (updated == 0) {
        await db.insert('users', {'name': 'User','company_name': 'Company','number_of_logins': 1,'isDarkMode': 0});
      }
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: 'Error',
        message: 'Failed to update number of logins: Reason: ${e.toString()}',
      ));
    }
  }

  Future<Map<String, dynamic>> getSalesSummary() async {
    try {
      final db = await _ensureDb();
      if (db == null) {
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
      final allDates = await db.rawQuery('SELECT date FROM sales_history');
      final today = DateTime.now();
      final todayDates = allDates.where((row) {
        final dateStr = row['date'];
        if (dateStr is! String) return false;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        return date.year == today.year && date.month == today.month && date.day == today.day;
      }).toList();
      final allTimeRevenue = await db.rawQuery('SELECT SUM(amount) as alltime_revenue FROM sales_history');
      final allTimeSales = await db.rawQuery('SELECT COUNT(amount) as alltime_sales FROM sales_history');
      final totalSales = await db.rawQuery('SELECT SUM(amount) as total_sales FROM sales_history');
      final totalItemsSold = await db.rawQuery('SELECT COUNT(*) as total_items_sold FROM sales_history');
      final recentSales = await db.rawQuery('SELECT * FROM sales_history ORDER BY date DESC LIMIT 10');
      final salesToday = await db.rawQuery('SELECT date, amount FROM sales_history');

      double totalToday = 0;
      final todayDateOnly = '${today.year}-${today.month}-${today.day}';
      for (final element in salesToday) {
        final dateStr = element['date'];
        if (dateStr is! String) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        final dateOnly = '${date.year}-${date.month}-${date.day}';
        if (dateOnly == todayDateOnly) {
          final amount = element['amount'];
          if (amount is num) totalToday += amount.toDouble();
        }
      }

      return {
        'total_sales': totalSales.first['total_sales'] ?? 0.0,
        'sales_today': todayDates.length,
        'today_revenue': totalToday,
        'alltime_revenue': allTimeRevenue.first['alltime_revenue'],
        'alltime_sales': allTimeSales.first['alltime_sales'],
        'total_items_sold': totalItemsSold.first['total_items_sold'],
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
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      await db.insert(
        'sales_history',
        {
          'items_sold': itemMap,
          'date': item.date,
          'amount': item.total,
          'transaction_type': item.transactionType,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (var cartItem in item.itemsSold!) {
        await db.rawUpdate(
          'UPDATE inventory SET quantity = quantity - ? WHERE name = ?',
          [cartItem.quantity, cartItem.name],
        );
      }
      Get.snackbar('Success', 'Sale recorded successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add sale: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>?> getSalesHistory() async {
    try {
      final db = await _ensureDb();
      if (db == null) return null;
      List<Map<String, dynamic>> query = await db.rawQuery('SELECT * FROM sales_history');
      return query;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch sales history: ${e.toString()}');
      return null;
    }
  }

  Future<void> addInventory(Item item) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      await db.insert(
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
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      await db.update(
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
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
      Get.snackbar('Success', 'Item deleted successfully',
          backgroundColor: bluePrimary, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete inventory item: ${e.toString()}');
    }
  }

  Future<bool> getHasSeenTutorial() async {
    try {
      final db = await _ensureDb();
      if (db == null) return false;
      final rows = await db.query('users', columns: ['has_seen_tutorial'], limit: 1);
      if (rows.isEmpty) return false;
      final v = rows.first['has_seen_tutorial'];
      if (v is int) return v == 1;
      if (v is num) return v.toInt() == 1;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setHasSeenTutorial() async {
    try {
      final db = await _ensureDb();
      if (db == null) return;
      await db.rawUpdate('UPDATE users SET has_seen_tutorial = 1 WHERE id = (SELECT id FROM users LIMIT 1)');
    } catch (_) {}
  }
}
