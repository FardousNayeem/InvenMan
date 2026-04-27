import 'package:invenman/app/actions/create_item_action.dart';
import 'package:invenman/app/actions/delete_item_action.dart';
import 'package:invenman/app/actions/update_item_action.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/repositories/item_repository.dart';

class InventoryService {
  const InventoryService._();

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) {
    return ItemRepository.fetchItems(sortBy: sortBy);
  }

  static Future<Item?> fetchItemById(int id) {
    return ItemRepository.fetchItemById(id);
  }

  static Future<List<String>> fetchDistinctCategories() {
    return ItemRepository.fetchDistinctCategories();
  }

  static Future<List<String>> fetchDistinctBrands() {
    return ItemRepository.fetchDistinctBrands();
  }

  // ---------------------------------------------------------------------------
  // Workflows
  // ---------------------------------------------------------------------------

  static Future<void> insertItem(Item item) {
    return CreateItemAction.execute(item);
  }

  static Future<void> updateItem(Item item) {
    return UpdateItemAction.execute(item);
  }

  static Future<void> deleteItem(int id, String name) {
    return DeleteItemAction.execute(id, name);
  }
}