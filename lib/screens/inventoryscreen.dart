import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/items.dart';
import 'package:invenman/models/sold_items.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String sortBy = 'name';

  final DateFormat dateFormat = DateFormat('h.mma, d MMMM, yyyy');

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final categoryController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Add New Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: "Category"),
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final description = descController.text.trim();
              final category = categoryController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              final quantity = int.tryParse(quantityController.text.trim());

              if (name.isEmpty ||
                  description.isEmpty ||
                  category.isEmpty ||
                  price == null ||
                  quantity == null) {
                _showMessage('Please fill all fields with valid values.');
                return;
              }

              if (price < 0) {
                _showMessage('Price cannot be negative.');
                return;
              }

              if (quantity < 0) {
                _showMessage('Quantity cannot be negative.');
                return;
              }

              final item = Item(
                name: name,
                description: description,
                price: price,
                category: category,
                quantity: quantity,
                createdAt: DateTime.now(),
                updatedAt: null,
              );

              await DBHelper.insertItem(item);

              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
              _showMessage('Item added successfully.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text("Add Item"),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(Item item) {
    final descController = TextEditingController(text: item.description);
    final quantityController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text("Edit Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: TextEditingController(text: item.name),
                decoration: const InputDecoration(labelText: "Name"),
                enabled: false,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              TextField(
                controller: TextEditingController(text: item.category),
                decoration: const InputDecoration(labelText: "Category"),
                enabled: false,
              ),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final description = descController.text.trim();
              final quantity = int.tryParse(quantityController.text.trim());

              if (description.isEmpty || quantity == null) {
                _showMessage('Please enter valid description and quantity.');
                return;
              }

              if (quantity < 0) {
                _showMessage('Quantity cannot be negative.');
                return;
              }

              final updatedItem = Item(
                id: item.id,
                name: item.name,
                description: description,
                price: item.price,
                category: item.category,
                quantity: quantity,
                createdAt: item.createdAt,
                updatedAt: DateTime.now(),
              );

              await DBHelper.updateItem(updatedItem);

              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
              _showMessage('Item updated successfully.');
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _sellItem(Item item) async {
    if (item.quantity <= 0) {
      _showMessage('This item is out of stock.');
      return;
    }

    final sellController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text("Sell ${item.name}"),
        content: TextField(
          controller: sellController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Selling Price"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final sellPrice = double.tryParse(sellController.text.trim());

              if (sellPrice == null) {
                _showMessage('Please enter a valid selling price.');
                return;
              }

              if (sellPrice < 0) {
                _showMessage('Selling price cannot be negative.');
                return;
              }

              final updatedItem = Item(
                id: item.id,
                name: item.name,
                description: item.description,
                price: item.price,
                category: item.category,
                quantity: item.quantity - 1,
                createdAt: item.createdAt,
                updatedAt: DateTime.now(),
              );

              await DBHelper.updateItem(updatedItem);

              await DBHelper.insertSoldItem(
                SoldItem(
                  name: item.name,
                  costPrice: item.price,
                  sellPrice: sellPrice,
                  date: DateFormat.yMd().add_jm().format(DateTime.now()),
                ),
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              setState(() {});
              _showMessage('Item sold successfully.');
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    String formatted = DateFormat('h.m').format(date).toLowerCase();
    String ampm = DateFormat('a').format(date).toLowerCase();
    String dayMonthYear = DateFormat('d MMMM, yyyy').format(date);
    return '$formatted$ampm, $dayMonthYear';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: sortBy,
                  onChanged: (value) => setState(() => sortBy = value!),
                  alignment: Alignment.center,
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Center(child: Text("Name")),
                    ),
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Center(child: Text("Price: Low to High")),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Center(child: Text("Price: High to Low")),
                    ),
                    DropdownMenuItem(
                      value: 'category',
                      child: Center(child: Text("Category")),
                    ),
                  ],
                  underline: Container(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add Item"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Item>>(
            future: DBHelper.fetchItems(sortBy: sortBy),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data!;

              if (items.isEmpty) {
                return const Center(child: Text('No Products Found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onLongPress: () async {
                        final action = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Choose Action:"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'edit'),
                                child: const Text("Edit"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, 'delete'),
                                child: const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (action == 'edit') {
                          _showEditItemDialog(item);
                        } else if (action == 'delete') {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Item"),
                              content: Text("Are you sure to delete '${item.name}'?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                              ],
                            ),
                          );

                          if (shouldDelete == true) {
                            await DBHelper.deleteItem(item.id!, item.name);
                            if (!mounted) return;
                            setState(() {});
                            _showMessage('Item deleted successfully.');
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item.category,
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.deepPurple.shade300,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.normal,
                                          color: Color.fromARGB(206, 255, 236, 236),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "Price:  \$${item.price.toStringAsFixed(0)} BDT,",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            "Quantity: ${item.quantity}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Divider(color: Colors.deepPurple.shade100),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Added: ${_formatDate(item.createdAt)}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (item.updatedAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          "Edited: ${_formatDate(item.updatedAt!)}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        onPressed: () => _sellItem(item),
                                        icon: const Icon(Icons.sell),
                                        label: const Text("Sell"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}