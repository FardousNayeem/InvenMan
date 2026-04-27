import 'package:invenman/app/core/app_normalizers.dart';
import 'package:invenman/app/core/money_utils.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/item_repository.dart';

class DeleteItemAction {
  const DeleteItemAction._();

  static Future<void> execute(int id, String name) async {
    final dbClient = await AppDatabase.db;

    await dbClient.transaction((txn) async {
      final previousItem = await ItemRepository.fetchItemByIdTxn(txn, id);

      await ItemRepository.deleteItemRowTxn(txn, id);

      await HistoryRepository.logHistory(
        itemName: name,
        action: 'Deleted',
        details: previousItem == null
            ? 'Item deleted from inventory'
            : _buildItemSnapshot(previousItem),
        meta: {
          'eventType': 'item_deleted',
          'itemId': id,
          'name': name,
          if (previousItem != null) ...{
            'category': previousItem.category,
            'brand': previousItem.brand,
            'colors': previousItem.colors,
            'quantity': previousItem.quantity,
            'costPrice': previousItem.costPrice,
            'sellingPrice': previousItem.sellingPrice,
            'supplier': previousItem.supplier,
            'warranties': previousItem.warranties,
            'imageCount': previousItem.imagePaths.length,
          },
        },
        executor: txn,
      );
    });
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