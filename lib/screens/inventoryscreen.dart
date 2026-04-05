import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/item.dart';

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

  String? _validateMoney(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Invalid';
    return null;
  }

  String? _validateQuantity(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Invalid';
    return null;
  }

  Future<void> _showAddItemDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final costPriceController = TextEditingController();
    final sellingPriceController = TextEditingController();
    final quantityController = TextEditingController();
    final warrantyController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add item',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a new inventory entry with pricing, stock, and warranty details.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AppTextField(
                      controller: nameController,
                      label: 'Item name',
                      hint: 'Samsung Fridge 250L',
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _AppTextField(
                      controller: descriptionController,
                      label: 'Description',
                      hint: 'Color, condition, key specs, notes',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _AppTextField(
                      controller: categoryController,
                      label: 'Category',
                      hint: 'Fridge, AC, TV, Mobile',
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AppTextField(
                            controller: costPriceController,
                            label: 'Cost price',
                            hint: '35000',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppTextField(
                            controller: sellingPriceController,
                            label: 'Selling price',
                            hint: '39500',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AppTextField(
                            controller: quantityController,
                            label: 'Quantity',
                            hint: '5',
                            keyboardType: TextInputType.number,
                            validator: _validateQuantity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppTextField(
                            controller: warrantyController,
                            label: 'Warranty (months)',
                            hint: '12',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed < 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final item = Item(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: categoryController.text.trim(),
                                costPrice: double.parse(costPriceController.text.trim()),
                                sellingPrice: double.parse(sellingPriceController.text.trim()),
                                quantity: int.parse(quantityController.text.trim()),
                                warrantyMonths: warrantyController.text.trim().isEmpty
                                    ? null
                                    : int.parse(warrantyController.text.trim()),
                                createdAt: DateTime.now().toUtc(),
                                updatedAt: DateTime.now().toUtc(),
                              );

                              await DBHelper.insertItem(item);

                              if (!mounted) return;
                              Navigator.pop(dialogContext);
                              _notifyChanged();
                              _showMessage('Item added successfully.');
                            },
                            child: const Text('Save item'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditItemDialog(Item item) async {
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final categoryController = TextEditingController(text: item.category);
    final costPriceController = TextEditingController(text: item.costPrice.toString());
    final sellingPriceController = TextEditingController(text: item.sellingPrice.toString());
    final quantityController = TextEditingController(text: item.quantity.toString());
    final warrantyController =
        TextEditingController(text: item.warrantyMonths?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit item',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Update details, pricing, stock, and warranty.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AppTextField(
                      controller: nameController,
                      label: 'Item name',
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _AppTextField(
                      controller: descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _AppTextField(
                      controller: categoryController,
                      label: 'Category',
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AppTextField(
                            controller: costPriceController,
                            label: 'Cost price',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppTextField(
                            controller: sellingPriceController,
                            label: 'Selling price',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AppTextField(
                            controller: quantityController,
                            label: 'Quantity',
                            keyboardType: TextInputType.number,
                            validator: _validateQuantity,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppTextField(
                            controller: warrantyController,
                            label: 'Warranty (months)',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return null;
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed < 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              final updatedItem = item.copyWith(
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: categoryController.text.trim(),
                                costPrice: double.parse(costPriceController.text.trim()),
                                sellingPrice: double.parse(sellingPriceController.text.trim()),
                                quantity: int.parse(quantityController.text.trim()),
                                warrantyMonths: warrantyController.text.trim().isEmpty
                                    ? null
                                    : int.parse(warrantyController.text.trim()),
                                updatedAt: DateTime.now().toUtc(),
                              );

                              await DBHelper.updateItem(updatedItem);

                              if (!mounted) return;
                              Navigator.pop(dialogContext);
                              _notifyChanged();
                              _showMessage('Item updated successfully.');
                            },
                            child: const Text('Save changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSellItemDialog(Item item) async {
    if (item.quantity <= 0) {
      _showMessage('This item is out of stock.', error: true);
      return;
    }

    final quantityController = TextEditingController(text: '1');
    final sellPriceController = TextEditingController(
      text: item.sellingPrice.toStringAsFixed(0),
    );
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final customerAddressController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
            final sellPrice = double.tryParse(sellPriceController.text.trim()) ?? 0;
            final estimatedProfit = (sellPrice - item.costPrice) * quantity;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sell ${item.name}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Available stock: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated profit',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${estimatedProfit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: estimatedProfit >= 0
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _AppTextField(
                                controller: quantityController,
                                label: 'Quantity',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final parsed = int.tryParse(value?.trim() ?? '');
                                  if (parsed == null || parsed <= 0) return 'Invalid';
                                  if (parsed > item.quantity) return 'Too many';
                                  return null;
                                },
                                onChanged: (_) => setLocalState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AppTextField(
                                controller: sellPriceController,
                                label: 'Sell price per unit',
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                validator: _validateMoney,
                                onChanged: (_) => setLocalState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _AppTextField(
                          controller: customerNameController,
                          label: 'Customer name',
                          hint: 'Optional',
                        ),
                        const SizedBox(height: 14),
                        _AppTextField(
                          controller: customerPhoneController,
                          label: 'Phone number',
                          hint: 'Optional',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _AppTextField(
                          controller: customerAddressController,
                          label: 'Address',
                          hint: 'Optional',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        if (item.warrantyMonths != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Warranty included: ${item.warrantyMonths} month(s)',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  await DBHelper.sellItem(
                                    item: item,
                                    quantitySold: int.parse(quantityController.text.trim()),
                                    sellPricePerUnit:
                                        double.parse(sellPriceController.text.trim()),
                                    customerName: customerNameController.text.trim().isEmpty
                                        ? null
                                        : customerNameController.text.trim(),
                                    customerPhone: customerPhoneController.text.trim().isEmpty
                                        ? null
                                        : customerPhoneController.text.trim(),
                                    customerAddress: customerAddressController.text.trim().isEmpty
                                        ? null
                                        : customerAddressController.text.trim(),
                                  );

                                  if (!mounted) return;
                                  Navigator.pop(dialogContext);
                                  _notifyChanged();
                                  _showMessage('Sale recorded successfully.');
                                },
                                child: const Text('Confirm sale'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

  List<Item> _applySearch(List<Item> allItems) {
    if (_searchQuery.isEmpty) return allItems;

    return allItems.where((item) {
      return item.name.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: _TopControls(
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
                final emptyText = _searchQuery.isNotEmpty
                    ? 'No matching items found'
                    : 'No items yet';

                final emptySubText = _searchQuery.isNotEmpty
                    ? 'Try searching by a different item name, description, or category.'
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

                    return _InventoryCard(
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

class _TopControls extends StatelessWidget {
  final String sortBy;
  final bool isSearchActive;
  final bool isSortExpanded;
  final TextEditingController searchController;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onActivateSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCancelSearch;
  final VoidCallback onAddItem;

  const _TopControls({
    required this.sortBy,
    required this.isSearchActive,
    required this.isSortExpanded,
    required this.searchController,
    required this.onSortChanged,
    required this.onActivateSearch,
    required this.onSearchChanged,
    required this.onCancelSearch,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;
    final rowHeight = compact ? 64.0 : 72.0;
    final gap = compact ? 8.0 : 12.0;

    if (compact) {
      return Column(
        children: [
          if (!isSearchActive)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: rowHeight,
                    child: _SortControl(
                      value: sortBy,
                      onChanged: onSortChanged,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  width: rowHeight,
                  child: IconButton.filledTonal(
                    onPressed: onActivateSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  child: FilledButton.icon(
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: rowHeight,
              child: _SearchBarControl(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onCancelSearch,
              ),
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: rowHeight,
                    child: _SortControl(
                      value: sortBy,
                      onChanged: onSortChanged,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  child: FilledButton.icon(
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    final sortFlex = isSearchActive
        ? 2
        : (isSortExpanded ? 8 : 4);
    final middleFlex = isSearchActive ? 7 : 1;
    final addFlex = isSearchActive
        ? 2
        : (isSortExpanded ? 2 : 3);

    return Row(
      children: [
        Expanded(
          flex: sortFlex,
          child: SizedBox(
            height: rowHeight,
            child: _SortControl(
              value: sortBy,
              onChanged: onSortChanged,
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: middleFlex,
          child: SizedBox(
            height: rowHeight,
            child: isSearchActive
                ? _SearchBarControl(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    onClear: onCancelSearch,
                  )
                : IconButton.filledTonal(
                    onPressed: onActivateSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: addFlex,
          child: SizedBox(
            height: rowHeight,
            child: FilledButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add_rounded),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(isSearchActive ? 'Add' : 'Add Item'),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _SortControl({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Center(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sort by',
            border: InputBorder.none,
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Name')),
            DropdownMenuItem(
              value: 'cost_price_asc',
              child: Text('Cost: Low to High'),
            ),
            DropdownMenuItem(
              value: 'cost_price_desc',
              child: Text('Cost: High to Low'),
            ),
            DropdownMenuItem(
              value: 'selling_price_asc',
              child: Text('Selling: Low to High'),
            ),
            DropdownMenuItem(
              value: 'selling_price_desc',
              child: Text('Selling: High to Low'),
            ),
            DropdownMenuItem(
              value: 'quantity_desc',
              child: Text('Stock: High to Low'),
            ),
            DropdownMenuItem(
              value: 'quantity_asc',
              child: Text('Stock: Low to High'),
            ),
            DropdownMenuItem(value: 'category', child: Text('Category')),
            DropdownMenuItem(
              value: 'updated_at_desc',
              child: Text('Recently Updated'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SearchBarControl extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBarControl({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search inventory',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel search',
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Item item;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCard({
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 760;

    final stockColor = item.quantity <= 0
        ? Colors.red.shade700
        : item.quantity <= 3
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: compact
            ? _InventoryCardCompact(
                item: item,
                formattedCreatedAt: formattedCreatedAt,
                formattedUpdatedAt: formattedUpdatedAt,
                stockColor: stockColor,
                onSell: onSell,
                onEdit: onEdit,
                onDelete: onDelete,
              )
            : _InventoryCardWide(
                item: item,
                formattedCreatedAt: formattedCreatedAt,
                formattedUpdatedAt: formattedUpdatedAt,
                stockColor: stockColor,
                onSell: onSell,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
      ),
    );
  }
}

class _InventoryCardWide extends StatelessWidget {
  final Item item;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final Color stockColor;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCardWide({
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.stockColor,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        color: cs.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Added: $formattedCreatedAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          Text(
                            'Updated: $formattedUpdatedAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricChip(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Cost',
                    value: '${item.costPrice.toStringAsFixed(0)}',
                  ),
                  _MetricChip(
                    icon: Icons.sell_outlined,
                    label: 'Selling',
                    value: '${item.sellingPrice.toStringAsFixed(0)}',
                  ),
                  _MetricChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    value: '${item.quantity}',
                    valueColor: stockColor,
                  ),
                  if (item.warrantyMonths != null)
                    _MetricChip(
                      icon: Icons.verified_outlined,
                      label: 'Warranty',
                      value: '${item.warrantyMonths} mo',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 78,
                height: 46,
                child: FilledButton(
                  onPressed: item.quantity <= 0 ? null : onSell,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.point_of_sale_rounded, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: 'More actions',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: cs.onSurfaceVariant,
                    size: 19,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryCardCompact extends StatelessWidget {
  final Item item;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final Color stockColor;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCardCompact({
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.stockColor,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Added: $formattedCreatedAt',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: cs.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              Text(
                                'Updated: $formattedUpdatedAt',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: cs.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 62,
                  height: 42,
                  child: FilledButton(
                    onPressed: item.quantity <= 0 ? null : onSell,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.point_of_sale_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    tooltip: 'More actions',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: cs.onSurfaceVariant,
                      size: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (item.description.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricChip(
              icon: Icons.shopping_bag_outlined,
              label: 'Cost',
              value: '${item.costPrice.toStringAsFixed(0)}',
            ),
            _MetricChip(
              icon: Icons.sell_outlined,
              label: 'Selling',
              value: '${item.sellingPrice.toStringAsFixed(0)}',
            ),
            _MetricChip(
              icon: Icons.inventory_2_outlined,
              label: 'Stock',
              value: '${item.quantity}',
              valueColor: stockColor,
            ),
            if (item.warrantyMonths != null)
              _MetricChip(
                icon: Icons.verified_outlined,
                label: 'Warranty',
                value: '${item.warrantyMonths} mo',
              ),
          ],
        ),
      ],
    );
  }
}

class _SquareActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _SquareActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }
}

class _OverflowActionButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OverflowActionButton({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert_rounded),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _AppTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}