import 'package:invenman/app/core/app_exception.dart';
import 'package:invenman/app/core/app_normalizers.dart';
import 'package:invenman/app/core/money_utils.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/item_repository.dart';

class UpdateItemAction {
  const UpdateItemAction._();

  static Future<void> execute(Item item) async {
    if (item.id == null) {
      throw const AppException.validation(
        code: 'item_update_missing_id',
        message: 'Cannot update an item without an id.',
      );
    }

    _validateItemFinancials(
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    final dbClient = await AppDatabase.db;

    await dbClient.transaction((txn) async {
      final previousItem = await ItemRepository.fetchItemByIdTxn(txn, item.id!);

      final normalizedItem = item.copyWith(
        category: AppNormalizers.category(item.category),
        brand: AppNormalizers.brand(item.brand),
        colors: AppNormalizers.colors(item.colors),
      );

      await ItemRepository.updateItemRowTxn(txn, normalizedItem);

      final historyName = previousItem?.name ?? normalizedItem.name;
      final details = previousItem == null
          ? _buildItemSnapshot(normalizedItem)
          : _buildItemEditDetails(previousItem, normalizedItem);

      await HistoryRepository.logHistory(
        itemName: historyName,
        action: 'Edited',
        details: details,
        meta: {
          'eventType': 'item_updated',
          'itemId': normalizedItem.id,
          'nameBefore': previousItem?.name,
          'nameAfter': normalizedItem.name,
          'categoryBefore': previousItem?.category,
          'categoryAfter': normalizedItem.category,
          'brandBefore': previousItem?.brand,
          'brandAfter': normalizedItem.brand,
          'colorsBefore': previousItem?.colors,
          'colorsAfter': normalizedItem.colors,
          'quantityBefore': previousItem?.quantity,
          'quantityAfter': normalizedItem.quantity,
          'costPriceBefore': previousItem?.costPrice,
          'costPriceAfter': normalizedItem.costPrice,
          'sellingPriceBefore': previousItem?.sellingPrice,
          'sellingPriceAfter': normalizedItem.sellingPrice,
          'supplierBefore': previousItem?.supplier,
          'supplierAfter': normalizedItem.supplier,
          'warrantiesBefore': previousItem?.warranties,
          'warrantiesAfter': normalizedItem.warranties,
          'imageCountBefore': previousItem?.imagePaths.length,
          'imageCountAfter': normalizedItem.imagePaths.length,
          'updatedAt': normalizedItem.updatedAt.toIso8601String(),
        },
        executor: txn,
      );
    });
  }

  static void _validateItemFinancials({
    required double costPrice,
    required double sellingPrice,
  }) {
    if (costPrice < 0 || sellingPrice < 0) {
      throw const AppException.validation(
        code: 'item_negative_price',
        message: 'Cost price and MRP cannot be negative.',
      );
    }

    if (costPrice > sellingPrice) {
      throw const AppException.validation(
        code: 'item_cost_exceeds_mrp',
        message: 'Cost price cannot be greater than MRP.',
      );
    }
  }

  static String _normalizeText(String value) => value.trim();

  static bool _sameText(String a, String b) {
    return _normalizeText(a) == _normalizeText(b);
  }

  static bool _sameMoney(double a, double b) {
    return MoneyUtils.same(a, b);
  }

  static bool _sameWarranties(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;

    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }

    return true;
  }

  static bool _sameStringLists(List<String> a, List<String> b) {
    final normalizedA = AppNormalizers.colors(a);
    final normalizedB = AppNormalizers.colors(b);

    if (normalizedA.length != normalizedB.length) return false;

    for (var i = 0; i < normalizedA.length; i++) {
      if (normalizedA[i].toLowerCase() != normalizedB[i].toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  static String _arrowChange(String before, String after) {
    return '$before -> $after';
  }

  static String _formatBrand(String brand) {
    final normalized = AppNormalizers.brand(brand);
    return normalized.isEmpty ? 'Not provided' : normalized;
  }

  static String _formatSupplier(String supplier) {
    final trimmed = supplier.trim();
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }

  static String _formatColors(List<String> colors) {
    final cleaned = AppNormalizers.colors(colors);
    if (cleaned.isEmpty) return 'Not provided';
    return cleaned.join(', ');
  }

  static String _formatWarranties(Map<String, int> warranties) {
    if (warranties.isEmpty) return 'No warranty';

    return warranties.entries.map((entry) {
      final suffix = entry.value == 1 ? '' : 's';
      return '${entry.key}: ${entry.value} month$suffix';
    }).join(', ');
  }

  static String _buildItemSnapshot(Item item) {
    return [
      'Brand: ${_formatBrand(item.brand)}',
      'Colors: ${_formatColors(item.colors)}',
      'Qty: ${item.quantity}',
      'Cost: ${MoneyUtils.text(item.costPrice)}',
      'Sell: ${MoneyUtils.text(item.sellingPrice)}',
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
        'Cost: ${_arrowChange(MoneyUtils.text(before.costPrice), MoneyUtils.text(after.costPrice))}',
      );
    }

    if (!_sameMoney(before.sellingPrice, after.sellingPrice)) {
      changes.add(
        'Sell: ${_arrowChange(MoneyUtils.text(before.sellingPrice), MoneyUtils.text(after.sellingPrice))}',
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