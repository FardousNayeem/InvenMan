import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/app/core/app_normalizers.dart';
import 'package:invenman/app/core/app_exception.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/database/app_database.dart';

class ItemRepository {
  const ItemRepository._();

  // ---------------------------------------------------------------------------
  // Transaction-scoped writes
  // ---------------------------------------------------------------------------

  static Future<int> insertItemRowTxn(
    sqflite.DatabaseExecutor executor,
    Item item,
  ) {
    return executor.insert(
      'items',
      item.toMap(),
    );
  }

  static Future<int> updateItemRowTxn(
    sqflite.DatabaseExecutor executor,
    Item item,
  ) {
    if (item.id == null) {
      throw const AppException.validation(
        code: 'item_update_missing_id',
        message: 'Cannot update an item without an id.',
      );
    }

    return executor.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<int> deleteItemRowTxn(
    sqflite.DatabaseExecutor executor,
    int id,
  ) {
    return executor.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Item?> fetchItemByIdTxn(
    sqflite.DatabaseExecutor executor,
    int id,
  ) async {
    final maps = await executor.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Item.fromMap(maps.first);
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) async {
    final dbClient = await AppDatabase.db;

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
      default:
        orderBy = 'name ASC';
    }

    final maps = await dbClient.query(
      'items',
      orderBy: orderBy,
    );

    return maps.map(Item.fromMap).toList();
  }

  static Future<Item?> fetchItemById(int id) async {
    final dbClient = await AppDatabase.db;
    return fetchItemByIdTxn(dbClient, id);
  }

  static Future<List<String>> fetchDistinctCategories() async {
    final dbClient = await AppDatabase.db;

    final result = await dbClient.rawQuery('''
      SELECT DISTINCT category
      FROM items
      WHERE TRIM(category) != ''
      ORDER BY category COLLATE NOCASE ASC
    ''');

    final seen = <String>{};
    final categories = <String>[];

    for (final row in result) {
      final raw = (row['category'] as String?)?.trim() ?? '';
      if (raw.isEmpty) continue;

      final normalized = AppNormalizers.category(raw);
      if (seen.add(normalized.toLowerCase())) {
        categories.add(normalized);
      }
    }

    return categories;
  }

  static Future<List<String>> fetchDistinctBrands() async {
    final dbClient = await AppDatabase.db;

    final result = await dbClient.rawQuery('''
      SELECT DISTINCT brand
      FROM items
      WHERE TRIM(brand) != ''
      ORDER BY brand COLLATE NOCASE ASC
    ''');

    final seen = <String>{};
    final brands = <String>[];

    for (final row in result) {
      final raw = (row['brand'] as String?)?.trim() ?? '';
      if (raw.isEmpty) continue;

      final normalized = AppNormalizers.brand(raw);
      final key = normalized.toLowerCase();

      if (seen.add(key)) {
        brands.add(normalized);
      }
    }

    return brands;
  }
}