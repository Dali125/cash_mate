import 'package:cash_app/models/cart_item.dart';
import 'package:cash_app/models/inventort.dart';
import 'package:cash_app/models/inventory_model.dart';
import 'package:cash_app/models/sales_model.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

class Config extends GetxController {
  Database? _database;
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
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      }
      final String path = kIsWeb
          ? 'cash_app.db'
          : join(await getDatabasesPath(), 'cash_app.db');
      _database =
          await openDatabase(path, version: 8, onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE IF NOT EXISTS inventory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price REAL, discount REAL, quantity INTEGER, image_url TEXT)');

        await db.execute(
            'CREATE TABLE IF NOT EXISTS item_barcodes (id INTEGER PRIMARY KEY AUTOINCREMENT, item_id INTEGER, barcode TEXT, FOREIGN KEY(item_id) REFERENCES inventory(id))');
        await db.execute(
            'CREATE TABLE IF NOT EXISTS sales_history (id INTEGER PRIMARY KEY AUTOINCREMENT, items_sold TEXT, transaction_type TEXT, date TEXT, amount REAL)');
        await db.execute(
            'CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, company_name TEXT, number_of_logins INTEGER, isDarkMode INTEGER, has_seen_tutorial INTEGER DEFAULT 0)');

        // New table for tracking individual items sold per sale
        await db.execute('''
            CREATE TABLE IF NOT EXISTS sale_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sale_id INTEGER,
              item_name TEXT,
              item_price REAL,
              quantity INTEGER,
              subtotal REAL,
              date TEXT,
              FOREIGN KEY(sale_id) REFERENCES sales_history(id)
            )
          ''');

        await db.insert('users', {
          'name': 'User',
          'company_name': 'Company',
          'number_of_logins': 0,
          'isDarkMode': 0,
          'has_seen_tutorial': 0
        });
      }, onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          final cols = await db.rawQuery('PRAGMA table_info(users)');
          final hasCol = cols.any((c) => c['name'] == 'has_seen_tutorial');
          if (!hasCol) {
            await db.execute(
                'ALTER TABLE users ADD COLUMN has_seen_tutorial INTEGER DEFAULT 0');
          }
        }
        if (oldVersion < 6) {
          await db.execute(
              'CREATE TABLE IF NOT EXISTS item_barcodes (id INTEGER PRIMARY KEY AUTOINCREMENT, item_id INTEGER, barcode TEXT, FOREIGN KEY(item_id) REFERENCES inventory(id))');
        }
        if (oldVersion < 7) {
          // Add sale_items table for tracking individual items sold
          await db.execute('''
              CREATE TABLE IF NOT EXISTS sale_items (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sale_id INTEGER,
                item_name TEXT,
                item_price REAL,
                quantity INTEGER,
                subtotal REAL,
                date TEXT,
                FOREIGN KEY(sale_id) REFERENCES sales_history(id)
              )
            ''');
        }
        if (oldVersion < 8) {
          final cols = await db.rawQuery('PRAGMA table_info(inventory)');
          final hasCol = cols.any((c) => c['name'] == 'discount');
          if (!hasCol) {
            await db.execute(
                'ALTER TABLE inventory ADD COLUMN discount REAL DEFAULT 0');
          }
        }
      });
      // Ensure at least one user row exists
      final count = Sqflite.firstIntValue(
              await _database!.rawQuery('SELECT COUNT(*) FROM users')) ??
          0;
      if (count == 0) {
        await _database!.insert('users', {
          'name': 'User',
          'company_name': 'Company',
          'number_of_logins': 0,
          'isDarkMode': 0,
          'has_seen_tutorial': 0
        });
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
  Future<List<Map<String, dynamic>>?> getInventory(
      {String? searchQuery}) async {
    try {
      final db = await _ensureDb();
      if (db == null) return null;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        return await db.rawQuery(
            'SELECT * FROM inventory WHERE name LIKE ?', ['%$searchQuery%']);
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
      final rows =
          await db.query('users', columns: ['number_of_logins'], limit: 1);
      if (rows.isEmpty) {
        await db.insert('users', {
          'name': 'User',
          'company_name': 'Company',
          'number_of_logins': 0,
          'isDarkMode': 0
        });
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
      final updated = await db.rawUpdate(
          'UPDATE users SET number_of_logins = number_of_logins + 1 WHERE id = (SELECT id FROM users LIMIT 1)');
      if (updated == 0) {
        await db.insert('users', {
          'name': 'User',
          'company_name': 'Company',
          'number_of_logins': 1,
          'isDarkMode': 0
        });
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
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      }).toList();
      final allTimeRevenue = await db
          .rawQuery('SELECT SUM(amount) as alltime_revenue FROM sales_history');
      final allTimeSales = await db
          .rawQuery('SELECT COUNT(amount) as alltime_sales FROM sales_history');
      final totalSales = await db
          .rawQuery('SELECT SUM(amount) as total_sales FROM sales_history');
      final totalItemsSold = await db
          .rawQuery('SELECT COUNT(*) as total_items_sold FROM sales_history');
      final recentSales = await db
          .rawQuery('SELECT * FROM sales_history ORDER BY date DESC LIMIT 10');
      final salesToday =
          await db.rawQuery('SELECT date, amount FROM sales_history');

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

  Future<Map<String, dynamic>> getBusinessProfile() async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        return {
          'name': 'User',
          'company_name': 'CashMate Business',
        };
      }

      final rows = await db.query(
        'users',
        columns: ['name', 'company_name'],
        limit: 1,
      );

      if (rows.isEmpty) {
        return {
          'name': 'User',
          'company_name': 'CashMate Business',
        };
      }

      final row = rows.first;
      return {
        'name': row['name']?.toString().trim().isNotEmpty == true
            ? row['name']
            : 'User',
        'company_name':
            row['company_name']?.toString().trim().isNotEmpty == true
                ? row['company_name']
                : 'CashMate Business',
      };
    } catch (_) {
      return {
        'name': 'User',
        'company_name': 'CashMate Business',
      };
    }
  }

  Future<void> addSale(SalesModel item) async {
    List<CartItem> itemsSold = item.itemsSold!;
    Map<int, dynamic> itemMap = {};
    for (int i = 0; i < itemsSold.length; i++) {
      itemMap[i] = itemsSold[i].toJson();
    }

    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }

      // Insert into sales_history and get the sale ID
      int saleId = await db.insert(
        'sales_history',
        {
          'items_sold': itemMap.toString(),
          'date': item.date,
          'amount': item.total,
          'transaction_type': item.transactionType,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert each item into sale_items for analytics tracking
      for (var cartItem in itemsSold) {
        final quantity = cartItem.quantity ?? 0;
        final price = cartItem.price ?? 0.0;
        final subtotal = price * quantity;

        await db.insert(
          'sale_items',
          {
            'sale_id': saleId,
            'item_name': cartItem.name,
            'item_price': price,
            'quantity': quantity,
            'subtotal': subtotal,
            'date': item.date,
          },
        );

        // Update inventory quantity
        await db.rawUpdate(
          'UPDATE inventory SET quantity = quantity - ? WHERE name = ?',
          [quantity, cartItem.name],
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
      List<Map<String, dynamic>> query = await db.rawQuery('''
        SELECT
          s.*,
          COALESCE(
            (SELECT COUNT(*) FROM sale_items si WHERE si.sale_id = s.id),
            0
          ) AS line_item_count,
          COALESCE(
            (SELECT SUM(si.quantity) FROM sale_items si WHERE si.sale_id = s.id),
            0
          ) AS item_count
        FROM sales_history s
        ORDER BY datetime(s.date) DESC, s.id DESC
      ''');
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

  Future<void> bulkInserInventory(List<InventoryModel> inventoryList) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      for (InventoryModel inventory in inventoryList) {
        db.insert(
          'inventory',
          inventory.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      Get.snackbar('Success', 'Items added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add inventory items: ${e.toString()}');
    }
  }

  Future<void> updateInventory(int id, Item item) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      final Map<String, dynamic> cleanedDate = {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'discount': item.discount,
        'image_url': item.imageUrl,
      };
      await db.update(
        'inventory',
        cleanedDate,
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
      final rows =
          await db.query('users', columns: ['has_seen_tutorial'], limit: 1);
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
      await db.rawUpdate(
          'UPDATE users SET has_seen_tutorial = 1 WHERE id = (SELECT id FROM users LIMIT 1)');
    } catch (_) {}
  }

  Future<void> addItemsWithBarCodes(Item item, List<String> barcodes) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return;
      }
      // Insert the inventory item and get its ID
      int itemId = await db.insert(
        'inventory',
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert each barcode associated with the item
      for (String barcode in barcodes) {
        await db.insert(
          'item_barcodes',
          {
            'item_id': itemId,
            'barcode': barcode,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      Get.snackbar('Success', 'Item and barcodes added successfully');
    } catch (e) {
      Get.snackbar(
          'Error', 'Failed to add item with barcodes: ${e.toString()}');
    }
  }

  Future<Item?> fetchItemByBarcode(String barcode) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return null;
      }

      // Query to find the item associated with the given barcode
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT i.*
        FROM inventory i
        JOIN item_barcodes b ON i.id = b.item_id
        WHERE b.barcode = ?
      ''', [barcode]);

      if (results.isNotEmpty) {
        return Item.fromJson(results.first);
      } else {
        return null; // No item found for the given barcode
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch item by barcode: ${e.toString()}');
      return null;
    }
  }

  /// Fetch all barcodes for a specific inventory item
  Future<List<String>> getBarcodesForItem(int itemId) async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT barcode FROM item_barcodes WHERE item_id = ?',
        [itemId],
      );

      return results.map((row) => row['barcode'] as String).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch barcodes: ${e.toString()}');
      return [];
    }
  }

  /// Add a single barcode to an existing inventory item
  Future<bool> addBarcodeToItem(int itemId, String barcode) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return false;
      }

      // Check if barcode already exists for this item
      final existing = await db.rawQuery(
        'SELECT id FROM item_barcodes WHERE item_id = ? AND barcode = ?',
        [itemId, barcode],
      );

      if (existing.isNotEmpty) {
        Get.snackbar('Info', 'This barcode is already linked to this item');
        return false;
      }

      await db.insert(
        'item_barcodes',
        {
          'item_id': itemId,
          'barcode': barcode,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      Get.snackbar('Success', 'Barcode added successfully');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to add barcode: ${e.toString()}');
      return false;
    }
  }

  /// Delete a barcode from an inventory item
  Future<bool> deleteBarcodeFromItem(int itemId, String barcode) async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        Get.snackbar('Error', 'Database initialization failed');
        return false;
      }

      await db.delete(
        'item_barcodes',
        where: 'item_id = ? AND barcode = ?',
        whereArgs: [itemId, barcode],
      );

      Get.snackbar('Success', 'Barcode removed successfully');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove barcode: ${e.toString()}');
      return false;
    }
  }

  // ==================== ANALYTICS FUNCTIONS ====================

  /// Get top selling items with quantity sold
  Future<List<Map<String, dynamic>>> getTopSellingItems(
      {int limit = 10}) async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final results = await db.rawQuery('''
        SELECT 
          item_name,
          SUM(quantity) as total_quantity,
          SUM(subtotal) as total_revenue,
          COUNT(*) as times_sold
        FROM sale_items
        GROUP BY item_name
        ORDER BY total_quantity DESC
        LIMIT ?
      ''', [limit]);

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get items sold within a date range
  Future<List<Map<String, dynamic>>> getItemsSoldInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final results = await db.rawQuery('''
        SELECT 
          item_name,
          item_price,
          SUM(quantity) as total_quantity,
          SUM(subtotal) as total_revenue,
          date
        FROM sale_items
        WHERE date >= ? AND date <= ?
        GROUP BY item_name
        ORDER BY total_quantity DESC
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get all items sold (detailed list)
  Future<List<Map<String, dynamic>>> getAllItemsSold() async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final results = await db.rawQuery('''
        SELECT * FROM sale_items ORDER BY date DESC
      ''');

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get sales analytics summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final db = await _ensureDb();
      if (db == null) {
        return _emptyAnalytics();
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Total items sold all time
      final totalItemsSold = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity), 0) as total FROM sale_items
      ''');

      // Items sold today
      final itemsSoldToday = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity), 0) as total FROM sale_items
        WHERE date >= ?
      ''', [todayStart.toIso8601String()]);

      // Items sold this week
      final itemsSoldThisWeek = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity), 0) as total FROM sale_items
        WHERE date >= ?
      ''', [weekStart.toIso8601String()]);

      // Items sold this month
      final itemsSoldThisMonth = await db.rawQuery('''
        SELECT COALESCE(SUM(quantity), 0) as total FROM sale_items
        WHERE date >= ?
      ''', [monthStart.toIso8601String()]);

      // Revenue today
      final revenueToday = await db.rawQuery('''
        SELECT COALESCE(SUM(subtotal), 0) as total FROM sale_items
        WHERE date >= ?
      ''', [todayStart.toIso8601String()]);

      // Revenue this week
      final revenueThisWeek = await db.rawQuery('''
        SELECT COALESCE(SUM(subtotal), 0) as total FROM sale_items
        WHERE date >= ?
      ''', [weekStart.toIso8601String()]);

      // Revenue this month
      final revenueThisMonth = await db.rawQuery('''
        SELECT COALESCE(SUM(subtotal), 0) as total FROM sale_items
        WHERE date >= ?
      ''', [monthStart.toIso8601String()]);

      // Total revenue all time
      final totalRevenue = await db.rawQuery('''
        SELECT COALESCE(SUM(subtotal), 0) as total FROM sale_items
      ''');

      // Number of transactions today
      final transactionsToday = await db.rawQuery('''
        SELECT COUNT(DISTINCT sale_id) as count FROM sale_items
        WHERE date >= ?
      ''', [todayStart.toIso8601String()]);

      // Total transactions all time
      final totalTransactions = await db.rawQuery('''
        SELECT COUNT(*) as count FROM sales_history
      ''');

      // Average transaction value
      final avgTransaction = await db.rawQuery('''
        SELECT AVG(amount) as avg FROM sales_history
      ''');

      // Top selling item
      final topItem = await getTopSellingItems(limit: 1);

      return {
        'total_items_sold': totalItemsSold.first['total'] ?? 0,
        'items_sold_today': itemsSoldToday.first['total'] ?? 0,
        'items_sold_this_week': itemsSoldThisWeek.first['total'] ?? 0,
        'items_sold_this_month': itemsSoldThisMonth.first['total'] ?? 0,
        'revenue_today': revenueToday.first['total'] ?? 0.0,
        'revenue_this_week': revenueThisWeek.first['total'] ?? 0.0,
        'revenue_this_month': revenueThisMonth.first['total'] ?? 0.0,
        'total_revenue': totalRevenue.first['total'] ?? 0.0,
        'transactions_today': transactionsToday.first['count'] ?? 0,
        'total_transactions': totalTransactions.first['count'] ?? 0,
        'avg_transaction_value': avgTransaction.first['avg'] ?? 0.0,
        'top_selling_item':
            topItem.isNotEmpty ? topItem.first['item_name'] : 'N/A',
        'top_item_quantity':
            topItem.isNotEmpty ? topItem.first['total_quantity'] : 0,
      };
    } catch (e) {
      return _emptyAnalytics();
    }
  }

  Map<String, dynamic> _emptyAnalytics() {
    return {
      'total_items_sold': 0,
      'items_sold_today': 0,
      'items_sold_this_week': 0,
      'items_sold_this_month': 0,
      'revenue_today': 0.0,
      'revenue_this_week': 0.0,
      'revenue_this_month': 0.0,
      'total_revenue': 0.0,
      'transactions_today': 0,
      'total_transactions': 0,
      'avg_transaction_value': 0.0,
      'top_selling_item': 'N/A',
      'top_item_quantity': 0,
    };
  }

  /// Get daily sales data for charts (last N days)
  Future<List<Map<String, dynamic>>> getDailySalesData({int days = 7}) async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final startDate = DateTime.now().subtract(Duration(days: days));

      final results = await db.rawQuery('''
        SELECT 
          DATE(date) as sale_date,
          SUM(quantity) as items_sold,
          SUM(subtotal) as revenue,
          COUNT(DISTINCT sale_id) as transactions
        FROM sale_items
        WHERE date >= ?
        GROUP BY DATE(date)
        ORDER BY sale_date ASC
      ''', [startDate.toIso8601String()]);

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get sales by item for a specific period
  Future<List<Map<String, dynamic>>> getSalesByItem({
    String period = 'all', // 'today', 'week', 'month', 'all'
  }) async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      String dateFilter = '';
      final now = DateTime.now();

      switch (period) {
        case 'today':
          final todayStart = DateTime(now.year, now.month, now.day);
          dateFilter = "WHERE date >= '${todayStart.toIso8601String()}'";
          break;
        case 'week':
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekStartDate =
              DateTime(weekStart.year, weekStart.month, weekStart.day);
          dateFilter = "WHERE date >= '${weekStartDate.toIso8601String()}'";
          break;
        case 'month':
          final monthStart = DateTime(now.year, now.month, 1);
          dateFilter = "WHERE date >= '${monthStart.toIso8601String()}'";
          break;
        default:
          dateFilter = '';
      }

      final results = await db.rawQuery('''
        SELECT 
          item_name,
          item_price,
          SUM(quantity) as total_quantity,
          SUM(subtotal) as total_revenue
        FROM sale_items
        $dateFilter
        GROUP BY item_name
        ORDER BY total_quantity DESC
      ''');

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get recent sales with item details
  Future<List<Map<String, dynamic>>> getRecentSalesWithItems(
      {int limit = 20}) async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final results = await db.rawQuery('''
        SELECT 
          s.id as sale_id,
          s.date,
          s.amount as total,
          s.transaction_type,
          GROUP_CONCAT(si.item_name || ' x' || si.quantity) as items
        FROM sales_history s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        GROUP BY s.id
        ORDER BY s.date DESC
        LIMIT ?
      ''', [limit]);

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get sales rows for CSV export with one row per sold item
  Future<List<Map<String, dynamic>>> getSalesExportRows() async {
    try {
      final db = await _ensureDb();
      if (db == null) return [];

      final results = await db.rawQuery('''
        SELECT
          s.id as sale_id,
          s.date as sale_date,
          s.transaction_type,
          s.amount as sale_total,
          si.item_name,
          si.quantity as quantity_sold,
          si.item_price as unit_price,
          si.subtotal as line_total
        FROM sales_history s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        ORDER BY s.date DESC, si.id ASC
      ''');

      return results;
    } catch (e) {
      return [];
    }
  }
}
