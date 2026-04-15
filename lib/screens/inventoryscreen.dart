import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/services/db_services.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/components/top_controls.dart';
import 'package:invenman/components/inventory_card.dart';
import 'package:invenman/components/item_form.dart';
import 'package:invenman/components/sell_form.dart';
import 'package:invenman/screens/item_details_screen.dart';
import 'package:invenman/theme/app_ui.dart';

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
      final colorsText = item.colors.join(' ').toLowerCase();

      return item.name.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery) ||
          item.brand.toLowerCase().contains(_searchQuery) ||
          item.supplier.toLowerCase().contains(_searchQuery) ||
          colorsText.contains(_searchQuery);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppUi.dialogRadius),
          ),
          title: const Text('Delete item'),
          content: Text(
            'Are you sure you want to delete "${item.name}"?\n\nSales and history will be preserved.',
          ),
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
      if (!mounted) return;
      Navigator.of(context).maybePop();
      _notifyChanged();
      _showMessage('Item deleted successfully.');
    }
  }

  Future<void> _openItemDetails(Item item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen(
          item: item,
          onEdit: (currentItem) async {
            await _showEditItemDialog(currentItem);
          },
          onSell: (currentItem) async {
            await _showSellItemDialog(currentItem);
          },
          onDelete: (currentItem) async {
            if (currentItem.id != null) {
              await _confirmDelete(currentItem);
            }
          },
        ),
      ),
    );

    if (!mounted) return;
    setState(_loadItems);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppUi.pageHPadding,
            AppUi.pageTopPadding,
            AppUi.pageHPadding,
            8,
          ),
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
                    style: TextStyle(color: cs.error),
                  ),
                );
              }

              final allItems = snapshot.data ?? [];
              final items = _applySearch(allItems);

              final lowStockCount = allItems
                  .where((item) => item.quantity > 0 && item.quantity <= 3)
                  .length;
              final outOfStockCount =
                  allItems.where((item) => item.quantity <= 0).length;
              final totalUnits =
                  allItems.fold<int>(0, (sum, item) => sum + item.quantity);

              if (items.isEmpty) {
                final isSearching = _searchQuery.isNotEmpty;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppUi.pageHPadding,
                      8,
                      AppUi.pageHPadding,
                      AppUi.pageBottomPadding,
                    ),
                    children: [
                      AppEmptyState(
                        icon: isSearching
                            ? Icons.search_off_rounded
                            : Icons.inventory_2_outlined,
                        title: isSearching
                            ? 'No matching items found'
                            : 'Inventory is empty',
                        message: isSearching
                            ? 'Try a different item name, description, category, brand, supplier, or color.'
                            : 'Add your first product to start tracking stock, warranties, images, and sales.',
                        action: isSearching
                            ? OutlinedButton.icon(
                                onPressed: _cancelSearch,
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Clear search'),
                              )
                            : FilledButton.icon(
                                onPressed: _showAddItemDialog,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add first item'),
                              ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  key: const PageStorageKey('inventory_list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppUi.pageHPadding,
                          2,
                          AppUi.pageHPadding,
                          12,
                        ),
                        child: _InventoryInsightBar(
                          totalItems: allItems.length,
                          totalUnits: totalUnits,
                          lowStockCount: lowStockCount,
                          outOfStockCount: outOfStockCount,
                          isSearching: _searchQuery.isNotEmpty,
                          resultCount: items.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppUi.pageHPadding,
                        0,
                        AppUi.pageHPadding,
                        AppUi.pageBottomPadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppUi.listGap),
                        itemBuilder: (_, i) {
                          final item = items[i];

                          return InventoryCard(
                            item: item,
                            formattedCreatedAt: _formatDate(item.createdAt),
                            formattedUpdatedAt: _formatDate(item.updatedAt),
                            onSell: () => _showSellItemDialog(item),
                            onEdit: () => _showEditItemDialog(item),
                            onDelete: () => _confirmDelete(item),
                            onTap: () => _openItemDetails(item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InventoryInsightBar extends StatelessWidget {
  final int totalItems;
  final int totalUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final bool isSearching;
  final int resultCount;

  const _InventoryInsightBar({
    required this.totalItems,
    required this.totalUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.isSearching,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;

    if (compact) {
      return Column(
        children: [
          if (isSearching) AppSearchNotice(resultCount: resultCount),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Items',
                  value: '$totalItems',
                  icon: Icons.widgets_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppInsightTile(
                  label: 'Units',
                  value: '$totalUnits',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Low stock',
                  value: '$lowStockCount',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppInsightTile(
                  label: 'Out',
                  value: '$outOfStockCount',
                  icon: Icons.remove_shopping_cart_outlined,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppInsightTile(
            label: 'Items',
            value: '$totalItems',
            icon: Icons.widgets_outlined,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: 'Units',
            value: '$totalUnits',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: 'Low stock',
            value: '$lowStockCount',
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: isSearching ? 'Results' : 'Out of stock',
            value: isSearching ? '$resultCount' : '$outOfStockCount',
            icon: isSearching
                ? Icons.search_rounded
                : Icons.remove_shopping_cart_outlined,
          ),
        ),
      ],
    );
  }
}