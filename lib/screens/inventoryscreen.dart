import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/components/top_controls.dart';
import 'package:invenman/components/inventory_card.dart';
import 'package:invenman/components/item_form.dart';
import 'package:invenman/components/sell_form.dart';

class InventoryPage extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const InventoryPage({super.key, this.onDataChanged});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  static const String _defaultSort = 'name';

  String _sortBy = _defaultSort;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadItems() {
    _itemsFuture = DBHelper.fetchItems(sortBy: _sortBy);
  }

  Future<void> _refresh() async {
    setState(_loadItems);
  }

  void _notifyChanged() {
    widget.onDataChanged?.call();
    setState(_loadItems);
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  bool get _isSortExpanded => !_isSearchActive && _sortBy != _defaultSort;

  void _activateSearch() {
    setState(() {
      _isSearchActive = true;
    });
  }

  void _cancelSearch() {
    setState(() {
      _searchController.clear();
      _isSearchActive = false;
      _sortBy = _defaultSort;
      _loadItems();
    });
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  List<Item> _applySearch(List<Item> allItems) {
    if (_searchQuery.isEmpty) return allItems;

    return allItems.where((item) {
      return item.name.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery) ||
          item.supplier.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _showAddItemDialog() async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => const ItemFormDialog(),
    );

    if (didSave == true && mounted) {
      _notifyChanged();
      _showMessage('Item added successfully.');
    }
  }

  Future<void> _showEditItemDialog(Item item) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => ItemFormDialog(existingItem: item),
    );

    if (didSave == true && mounted) {
      _notifyChanged();
      _showMessage('Item updated successfully.');
    }
  }

  Future<void> _showSellItemDialog(Item item) async {
    if (item.quantity <= 0) {
      _showMessage('This item is out of stock.', error: true);
      return;
    }

    final didSell = await showDialog<bool>(
      context: context,
      builder: (_) => SellItemDialog(item: item),
    );

    if (didSell == true && mounted) {
      _notifyChanged();
      _showMessage('Sale recorded successfully.');
    }
  }

  Future<void> _confirmDelete(Item item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Delete item'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await DBHelper.deleteItem(item.id!, item.name);
      _notifyChanged();
      _showMessage('Item deleted successfully.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: InventoryTopControls(
            sortBy: _sortBy,
            isSearchActive: _isSearchActive,
            isSortExpanded: _isSortExpanded,
            searchController: _searchController,
            onSortChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
                _loadItems();
              });
            },
            onActivateSearch: _activateSearch,
            onSearchChanged: (_) => setState(() {}),
            onCancelSearch: _cancelSearch,
            onAddItem: _showAddItemDialog,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Item>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Something went wrong.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                );
              }

              final allItems = snapshot.data ?? [];
              final items = _applySearch(allItems);

              if (items.isEmpty) {
                final emptyText =
                    _searchQuery.isNotEmpty ? 'No matching items found' : 'No items yet';

                final emptySubText = _searchQuery.isNotEmpty
                    ? 'Try searching by a different item name, description, category, or supplier.'
                    : 'Add your first item to start building your inventory.';

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 90),
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.inventory_2_outlined,
                        size: 68,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          emptyText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            emptySubText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final item = items[i];

                    return InventoryCard(
                      item: item,
                      formattedCreatedAt: _formatDate(item.createdAt),
                      formattedUpdatedAt: _formatDate(item.updatedAt),
                      onSell: () => _showSellItemDialog(item),
                      onEdit: () => _showEditItemDialog(item),
                      onDelete: () => _confirmDelete(item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}