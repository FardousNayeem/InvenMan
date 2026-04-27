import 'package:invenman/app/core/app_exception.dart';
import 'package:invenman/app/core/app_normalizers.dart';
import 'package:invenman/app/core/money_utils.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/item_repository.dart';

class CreateItemAction {
  const CreateItemAction._();

  static Future<void> execute(Item item) async {
    _validateItemFinancials(
      costPrice: item.costPrice,
      sellingPrice: item.sellingPrice,
    );

    final normalizedItem = item.copyWith(
      category: AppNormalizers.category(item.category),
      brand: AppNormalizers.brand(item.brand),
      colors: AppNormalizers.colors(item.colors),
    );

    final dbClient = await AppDatabase.db;

    await dbClient.transaction((txn) async {
      final itemId = await ItemRepository.insertItemRowTxn(txn, normalizedItem);

      await HistoryRepository.logHistory(
        itemName: normalizedItem.name,
        action: 'Added',
        details: _buildItemSnapshot(normalizedItem),
        meta: {
          'eventType': 'item_created',
          'itemId': itemId,
          'name': normalizedItem.name,
          'category': normalizedItem.category,
          'brand': normalizedItem.brand,
          'colors': normalizedItem.colors,
          'quantity': normalizedItem.quantity,
          'costPrice': normalizedItem.costPrice,
          'sellingPrice': normalizedItem.sellingPrice,
          'supplier': normalizedItem.supplier,
          'warranties': normalizedItem.warranties,
          'imageCount': normalizedItem.imagePaths.length,
          'createdAt': normalizedItem.createdAt.toIso8601String(),
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
}