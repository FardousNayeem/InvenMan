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
  String _sortBy = 'name';
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppTextField(
                            controller: sellingPriceController,
                            label: 'Selling price',
                            hint: '39500',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                              if (parsed == null || parsed < 0) {
                                return 'Invalid';
                              }
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AppTextField(
                            controller: sellingPriceController,
                            label: 'Selling price',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                                'BDT ${estimatedProfit.toStringAsFixed(2)}',
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
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
                      DropdownMenuItem(value: 'quantity_desc', child: Text('Stock: High to Low')),
                      DropdownMenuItem(value: 'quantity_asc', child: Text('Stock: Low to High')),
                      DropdownMenuItem(value: 'category', child: Text('Category')),
                      DropdownMenuItem(
                        value: 'updated_at_desc',
                        child: Text('Recently Updated'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _sortBy = value;
                        _loadItems();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
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

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 90),
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 68,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'No items yet',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Add your first item to start building your inventory.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
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
    final stockColor = item.quantity <= 0
        ? Colors.red.shade700
        : item.quantity <= 3
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                const Spacer(),
                PopupMenuButton<String>(
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
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            if (item.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricChip(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Cost',
                  value: 'BDT ${item.costPrice.toStringAsFixed(0)}',
                ),
                _MetricChip(
                  icon: Icons.sell_outlined,
                  label: 'Selling',
                  value: 'BDT ${item.sellingPrice.toStringAsFixed(0)}',
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
            const SizedBox(height: 16),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 10),
            Text(
              'Added: $formattedCreatedAt',
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Updated: $formattedUpdatedAt',
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: item.quantity <= 0 ? null : onSell,
                icon: const Icon(Icons.point_of_sale_rounded),
                label: const Text('Sell item'),
              ),
            ),
          ],
        ),
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