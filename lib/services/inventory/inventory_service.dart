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
  // Writes
  //
  // For now these intentionally delegate to ItemRepository.
  // Later, create/update/delete should move behind dedicated action classes.
  // ---------------------------------------------------------------------------

  static Future<void> insertItem(Item item) {
    return ItemRepository.insertItem(item);
  }

  static Future<void> updateItem(Item item) {
    return ItemRepository.updateItem(item);
  }

  static Future<void> deleteItem(int id, String name) {
    return ItemRepository.deleteItem(id, name);
  }
}