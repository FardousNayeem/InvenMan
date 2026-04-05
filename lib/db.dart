import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/models/history.dart';

class DBHelper {
  static sqflite.Database? _db;
  static bool _isInitialized = false;

  static const String _databaseName = 'inventory.db';
  static const int _databaseVersion = 4;

  static Future<void> _initPlatform() async {
    if (_isInitialized) return;

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _isInitialized = true;
  }

  static Future<sqflite.Database> get db async {
    await _initPlatform();
    _db ??= await _initDB();
    return _db!;
  }

  static Future<sqflite.Database> _initDB() async {
    final path = join(await sqflite.getDatabasesPath(), _databaseName);

    final factory = (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)
        ? databaseFactory
        : sqflite.databaseFactory;

    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Destructive migration for now because the old schema is very different.
          // Replace with a proper migration later if you need to preserve old local data.
          await db.execute('DROP TABLE IF EXISTS history_entries');
          await db.execute('DROP TABLE IF EXISTS sale_records');
          await db.execute('DROP TABLE IF EXISTS item_history');
          await db.execute('DROP TABLE IF EXISTS sold_items');
          await db.execute('DROP TABLE IF EXISTS items');
          await _createTables(db);
        },
      ),
    );
  }

  static Future<void> _createTables(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 0),
        warranty_months INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity_sold INTEGER NOT NULL CHECK (quantity_sold > 0),
        cost_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        profit REAL NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        customer_address TEXT,
        warranty_months INTEGER,
        sold_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE history_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_items_name ON items(name)',
    );
    await db.execute(
      'CREATE INDEX idx_items_category ON items(category)',
    );
    await db.execute(
      'CREATE INDEX idx_items_updated_at ON items(updated_at)',
    );
    await db.execute(
      'CREATE INDEX idx_sale_records_item_id ON sale_records(item_id)',
    );
    await db.execute(
      'CREATE INDEX idx_sale_records_category ON sale_records(category)',
    );
    await db.execute(
      'CREATE INDEX idx_sale_records_sold_at ON sale_records(sold_at)',
    );
    await db.execute(
      'CREATE INDEX idx_history_entries_created_at ON history_entries(created_at)',
    );
  }

  static Future<void> insertItem(Item item) async {
    final dbClient = await db;

    await dbClient.insert('items', item.toMap());

    await logHistory(
      item.name,
      'Added',
      'Qty: ${item.quantity}, Cost: ${item.costPrice}, Sell: ${item.sellingPrice}'
      '${item.warrantyMonths != null ? ', Warranty: ${item.warrantyMonths} months' : ''}',
    );
  }

  static Future<void> updateItem(Item item) async {
    final dbClient = await db;

    await dbClient.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    await logHistory(
      item.name,
      'Edited',
      'Qty: ${item.quantity}, Cost: ${item.costPrice}, Sell: ${item.sellingPrice}'
      '${item.warrantyMonths != null ? ', Warranty: ${item.warrantyMonths} months' : ''}',
    );
  }

  static Future<void> deleteItem(int id, String name) async {
    final dbClient = await db;

    await dbClient.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    await logHistory(name, 'Deleted', 'Item deleted');
  }

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) async {
    final dbClient = await db;

    String orderBy = 'name ASC';

    switch (sortBy) {
      case 'cost_price_asc':
        orderBy = 'cost_price ASC';
        break;
      case 'cost_price_desc':
        orderBy = 'cost_price DESC';
        break;
      case 'selling_price_asc':
        orderBy = 'selling_price ASC';
        break;
      case 'selling_price_desc':
        orderBy = 'selling_price DESC';
        break;
      case 'category':
        orderBy = 'category ASC';
        break;
      case 'quantity_asc':
        orderBy = 'quantity ASC';
        break;
      case 'quantity_desc':
        orderBy = 'quantity DESC';
        break;
      case 'updated_at_desc':
        orderBy = 'updated_at DESC';
        break;
      case 'created_at_desc':
        orderBy = 'created_at DESC';
        break;
      case 'name':
      default:
        orderBy = 'name ASC';
        break;
    }

    final maps = await dbClient.query(
      'items',
      orderBy: orderBy,
    );

    return maps.map((map) => Item.fromMap(map)).toList();
  }

  static Future<Item?> fetchItemById(int id) async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  static Future<void> insertSaleRecord(SaleRecord sale) async {
    final dbClient = await db;

    await dbClient.insert('sale_records', sale.toMap());

    final details = StringBuffer()
      ..write('Qty: ${sale.quantitySold}, Sell: ${sale.sellPrice}, Profit: ${sale.profit}');

    if (sale.customerName != null && sale.customerName!.trim().isNotEmpty) {
      details.write(', Customer: ${sale.customerName}');
    }
    if (sale.customerPhone != null && sale.customerPhone!.trim().isNotEmpty) {
      details.write(', Phone: ${sale.customerPhone}');
    }
    if (sale.warrantyMonths != null) {
      details.write(', Warranty: ${sale.warrantyMonths} months');
    }

    await logHistory(
      sale.itemName,
      'Sold',
      details.toString(),
    );
  }

  static Future<List<SaleRecord>> fetchSaleRecords() async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'sale_records',
      orderBy: 'sold_at DESC',
    );

    return maps.map((map) => SaleRecord.fromMap(map)).toList();
  }

  static Future<void> logHistory(
    String itemName,
    String action,
    String details,
  ) async {
    final dbClient = await db;

    await dbClient.insert('history_entries', {
      'item_name': itemName,
      'action': action,
      'details': details,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<List<HistoryEntry>> fetchHistoryEntries() async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'history_entries',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => HistoryEntry.fromMap(map)).toList();
  }

  static Future<void> sellItem({
    required Item item,
    required int quantitySold,
    required double sellPricePerUnit,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
  }) async {
    final dbClient = await db;

    if (item.id == null) {
      throw Exception('Cannot sell an item without an id.');
    }

    if (quantitySold <= 0) {
      throw Exception('Quantity sold must be greater than zero.');
    }

    if (item.quantity < quantitySold) {
      throw Exception('Not enough stock available.');
    }

    final updatedItem = item.copyWith(
      quantity: item.quantity - quantitySold,
      updatedAt: DateTime.now().toUtc(),
    );

    final profit =
        (sellPricePerUnit - item.costPrice) * quantitySold;

    final sale = SaleRecord(
      itemId: item.id!,
      itemName: item.name,
      category: item.category,
      quantitySold: quantitySold,
      costPrice: item.costPrice,
      sellPrice: sellPricePerUnit,
      profit: profit,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      warrantyMonths: item.warrantyMonths,
      soldAt: DateTime.now().toUtc(),
    );

    await dbClient.transaction((txn) async {
      await txn.update(
        'items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      await txn.insert('sale_records', sale.toMap());

      final details = StringBuffer()
        ..write('Qty: $quantitySold, Sell: $sellPricePerUnit, Profit: $profit');

      if (customerName != null && customerName.trim().isNotEmpty) {
        details.write(', Customer: $customerName');
      }
      if (customerPhone != null && customerPhone.trim().isNotEmpty) {
        details.write(', Phone: $customerPhone');
      }
      if (item.warrantyMonths != null) {
        details.write(', Warranty: ${item.warrantyMonths} months');
      }

      await txn.insert('history_entries', {
        'item_name': item.name,
        'action': 'Sold',
        'details': details.toString(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  static Future<void> clearAllData() async {
    final dbClient = await db;

    await dbClient.delete('history_entries');
    await dbClient.delete('sale_records');
    await dbClient.delete('items');
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}