import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/models/item.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/repositories/history_repository.dart';

class ItemRepository {
  const ItemRepository._();

  // ---------------------------------------------------------------------------
  // Transaction-scoped writes. Business workflows in actions.
  // ---------------------------------------------------------------------------

  static Future<int> updateItemRowTxn(
    sqflite.DatabaseExecutor executor,
    Item item,
  ) {
    if (item.id == null) {
      throw Exception('Cannot update an item without an id.');
    }

    return executor.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static String normalizeStoredCategory(String value) {
    return value.trim().toUpperCase();
  }

  static String normalizeStoredBrand(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return _titleCase(trimmed);
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

      final normalized = normalizeStoredCategory(raw);
      if (seen.add(normalized)) {
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

      final normalized = normalizeStoredBrand(raw);
      final key = normalized.toLowerCase();

      if (seen.add(key)) {
        brands.add(normalized);
      }
    }

    return brands;
  }

  static Future<void> insertItem(Item item) async {
    _validateItemFinancials(
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    final dbClient = await AppDatabase.db;

    final normalizedItem = item.copyWith(
      category: normalizeStoredCategory(item.category),
      brand: normalizeStoredBrand(item.brand),
      colors: _normalizeColors(item.colors),
    );

    await dbClient.insert('items', normalizedItem.toMap());

    await HistoryRepository.logHistory(
      itemName: normalizedItem.name,
      action: 'Added',
      details: _buildItemSnapshot(normalizedItem),
    );
  }

  static Future<void> updateItem(Item item) async {
    _validateItemFinancials(
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    final dbClient = await AppDatabase.db;

    Item? previousItem;

    if (item.id != null) {
      final maps = await dbClient.query(
        'items',
        where: 'id = ?',
        whereArgs: [item.id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        previousItem = Item.fromMap(maps.first);
      }
    }

    final normalizedItem = item.copyWith(
      category: normalizeStoredCategory(item.category),
      brand: normalizeStoredBrand(item.brand),
      colors: _normalizeColors(item.colors),
    );

    await dbClient.update(
      'items',
      normalizedItem.toMap(),
      where: 'id = ?',
      whereArgs: [normalizedItem.id],
    );

    final historyName = previousItem?.name ?? normalizedItem.name;
    final details = previousItem == null
        ? _buildItemSnapshot(normalizedItem)
        : _buildItemEditDetails(previousItem, normalizedItem);

    await HistoryRepository.logHistory(
      itemName: historyName,
      action: 'Edited',
      details: details,
    );
  }

  static Future<void> deleteItem(int id, String name) async {
    final dbClient = await AppDatabase.db;

    Item? previousItem;

    final maps = await dbClient.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      previousItem = Item.fromMap(maps.first);
    }

    await dbClient.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    await HistoryRepository.logHistory(
      itemName: name,
      action: 'Deleted',
      details: previousItem == null
          ? 'Item deleted from inventory'
          : _buildItemSnapshot(previousItem),
    );
  }

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

    final maps = await dbClient.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return Item.fromMap(maps.first);
  }

  static String _formatBrand(String brand) {
    final normalized = normalizeStoredBrand(brand);
    return normalized.isEmpty ? 'Not provided' : normalized;
  }

  static String _formatSupplier(String supplier) {
    final trimmed = supplier.trim();
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  static List<String> _normalizeColors(List<String> colors) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in colors) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final normalized = _titleCase(trimmed);
      final key = normalized.toLowerCase();

      if (seen.contains(key)) continue;

      seen.add(key);
      cleaned.add(normalized);
    }

    return cleaned;
  }

  static String _formatColors(List<String> colors) {
    final cleaned = _normalizeColors(colors);
    if (cleaned.isEmpty) return 'Not provided';
    return cleaned.join(', ');
  }

  static String _titleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
      if (word.length == 1) return word.toUpperCase();

      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  static String _normalizeText(String value) => value.trim();

  static bool _sameText(String a, String b) {
    return _normalizeText(a) == _normalizeText(b);
  }

  static bool _sameMoney(double a, double b) {
    return (DbShared.roundMoney(a) - DbShared.roundMoney(b)).abs() < 0.009;
  }

  static bool _sameWarranties(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }

    return true;
  }

  static bool _sameStringLists(List<String> a, List<String> b) {
    final normalizedA = _normalizeColors(a);
    final normalizedB = _normalizeColors(b);

    if (normalizedA.length != normalizedB.length) return false;

    for (var i = 0; i < normalizedA.length; i++) {
      if (normalizedA[i].toLowerCase() != normalizedB[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  static String _moneyText(double value) {
    return DbShared.roundMoney(value).toStringAsFixed(0);
  }

  static String _arrowChange(String before, String after) {
    return '$before -> $after';
  }

  static void _validateItemFinancials({
    required double costPrice,
    required double sellingPrice,
  }) {
    if (costPrice < 0 || sellingPrice < 0) {
      throw Exception('Cost price and MRP cannot be negative.');
    }

    if (costPrice > sellingPrice) {
      throw Exception('Cost price cannot be greater than MRP.');
    }
  }

  static String _formatWarranties(Map<String, int> warranties) {
    if (warranties.isEmpty) return 'No warranty';

    return warranties.entries
        .map((entry) {
          final suffix = entry.value == 1 ? '' : 's';
          return '${entry.key}: ${entry.value} month$suffix';
        })
        .join(', ');
  }

  static String _buildItemSnapshot(Item item) {
    return [
      'Brand: ${_formatBrand(item.brand)}',
      'Colors: ${_formatColors(item.colors)}',
      'Qty: ${item.quantity}',
      'Cost: ${_moneyText(item.costPrice)}',
      'Sell: ${_moneyText(item.sellingPrice)}',
      'Supplier: ${_formatSupplier(item.supplier)}',
      'Warranties: ${_formatWarranties(item.warranties)}',
      'Images: ${item.imagePaths.length}',
    ].join(', ');
  }

  static String _buildItemEditDetails(Item before, Item after) {
    final changes = <String>[];

    if (!_sameText(before.name, after.name)) {
      changes.add('Name: ${_arrowChange(before.name, after.name)}');
    }

    if (!_sameText(before.description, after.description)) {
      final beforeDesc = before.description.trim().isEmpty ? 'Empty' : 'Updated';
      final afterDesc = after.description.trim().isEmpty ? 'Empty' : 'Updated';

      changes.add('Description: ${_arrowChange(beforeDesc, afterDesc)}');
    }

    if (!_sameText(before.category, after.category)) {
      changes.add('Category: ${_arrowChange(before.category, after.category)}');
    }

    if (!_sameText(before.brand, after.brand)) {
      changes.add(
        'Brand: ${_arrowChange(_formatBrand(before.brand), _formatBrand(after.brand))}',
      );
    }

    if (!_sameStringLists(before.colors, after.colors)) {
      changes.add(
        'Colors: ${_arrowChange(_formatColors(before.colors), _formatColors(after.colors))}',
      );
    }

    if (before.quantity != after.quantity) {
      changes.add(
        'Qty: ${_arrowChange('${before.quantity}', '${after.quantity}')}',
      );
    }

    if (!_sameMoney(before.costPrice, after.costPrice)) {
      changes.add(
        'Cost: ${_arrowChange(_moneyText(before.costPrice), _moneyText(after.costPrice))}',
      );
    }

    if (!_sameMoney(before.sellingPrice, after.sellingPrice)) {
      changes.add(
        'Sell: ${_arrowChange(_moneyText(before.sellingPrice), _moneyText(after.sellingPrice))}',
      );
    }

    if (!_sameText(before.supplier, after.supplier)) {
      changes.add(
        'Supplier: ${_arrowChange(_formatSupplier(before.supplier), _formatSupplier(after.supplier))}',
      );
    }

    if (!_sameWarranties(before.warranties, after.warranties)) {
      changes.add(
        'Warranties: ${_arrowChange(_formatWarranties(before.warranties), _formatWarranties(after.warranties))}',
      );
    }

    if (before.imagePaths.length != after.imagePaths.length) {
      changes.add(
        'Images: ${_arrowChange('${before.imagePaths.length}', '${after.imagePaths.length}')}',
      );
    }

    if (changes.isEmpty) {
      return 'No tracked fields changed.';
    }

    return changes.join(', ');
  }
}