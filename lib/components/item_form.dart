import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invenman/components/app_text_field.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/image_service.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? existingItem;

  const ItemFormDialog({super.key, this.existingItem});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _supplierController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _quantityController;

  final List<_WarrantyFieldData> _warrantyFields = [];
  List<String> _imagePaths = [];

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _supplierController = TextEditingController(text: item?.supplier ?? '');
    _costPriceController = TextEditingController(
      text: item != null ? item.costPrice.toString() : '',
    );
    _sellingPriceController = TextEditingController(
      text: item != null ? item.sellingPrice.toString() : '',
    );
    _quantityController = TextEditingController(
      text: item != null ? item.quantity.toString() : '',
    );

    _imagePaths = List<String>.from(item?.imagePaths ?? const []);

    final warranties = item?.warranties ?? const <String, int>{};
    if (warranties.isNotEmpty) {
      for (final entry in warranties.entries) {
        _warrantyFields.add(
          _WarrantyFieldData(
            keyController: TextEditingController(text: entry.key),
            valueController: TextEditingController(text: entry.value.toString()),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _supplierController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();

    for (final field in _warrantyFields) {
      field.dispose();
    }
    super.dispose();
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

  Future<void> _pickImages() async {
    try {
      final picked = await ImageService.pickAndProcessImages(
        existingPaths: _imagePaths,
      );
      if (!mounted) return;
      setState(() {
        _imagePaths = picked;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add images: $e')),
      );
    }
  }

  Future<void> _removeImage(String path) async {
    setState(() {
      _imagePaths.remove(path);
    });
    await ImageService.deleteImageFile(path);
  }

  void _addWarrantyField() {
    if (_warrantyFields.length >= 5) return;
    setState(() {
      _warrantyFields.add(
        _WarrantyFieldData(
          keyController: TextEditingController(),
          valueController: TextEditingController(),
        ),
      );
    });
  }

  void _removeWarrantyField(int index) {
    setState(() {
      _warrantyFields[index].dispose();
      _warrantyFields.removeAt(index);
    });
  }

  Map<String, int> _buildWarranties() {
    final map = <String, int>{};

    for (final field in _warrantyFields) {
      final key = field.keyController.text.trim();
      final valueText = field.valueController.text.trim();

      if (key.isEmpty && valueText.isEmpty) continue;
      if (key.isEmpty || valueText.isEmpty) {
        throw Exception('Each warranty row must have both name and months.');
      }

      final months = int.tryParse(valueText);
      if (months == null || months < 0) {
        throw Exception('Warranty months must be a valid positive number.');
      }

      if (map.containsKey(key)) {
        throw Exception('Duplicate warranty names are not allowed.');
      }

      map[key] = months;
    }

    return map;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final warranties = _buildWarranties();
      final now = DateTime.now().toUtc();

      final item = (_isEditing ? widget.existingItem! : null)?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            supplier: _supplierController.text.trim(),
            costPrice: double.parse(_costPriceController.text.trim()),
            sellingPrice: double.parse(_sellingPriceController.text.trim()),
            quantity: int.parse(_quantityController.text.trim()),
            warranties: warranties,
            imagePaths: _imagePaths,
            updatedAt: now,
          ) ??
          Item(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            supplier: _supplierController.text.trim(),
            costPrice: double.parse(_costPriceController.text.trim()),
            sellingPrice: double.parse(_sellingPriceController.text.trim()),
            quantity: int.parse(_quantityController.text.trim()),
            warranties: warranties,
            imagePaths: _imagePaths,
            createdAt: now,
            updatedAt: now,
          );

      if (_isEditing) {
        await DBHelper.updateItem(item);
      } else {
        await DBHelper.insertItem(item);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit item' : 'Add item',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set product details, supplier, warranty, stock, and images.',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _nameController,
                  label: 'Item name',
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _categoryController,
                        label: 'Category',
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _supplierController,
                        label: 'Supplier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _costPriceController,
                        label: 'Cost price',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _validateMoney,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _sellingPriceController,
                        label: 'Selling price',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _validateMoney,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  keyboardType: TextInputType.number,
                  validator: _validateQuantity,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Warranties',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _warrantyFields.length >= 5 ? null : _addWarrantyField,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (_warrantyFields.isEmpty)
                  Text(
                    'No warranty added.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ...List.generate(_warrantyFields.length, (index) {
                  final field = _warrantyFields[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextField(
                            controller: field.keyController,
                            label: 'Warranty name',
                            hint: 'Compressor',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            controller: field.valueController,
                            label: 'Months',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _removeWarrantyField(index),
                          icon: const Icon(Icons.remove_rounded),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Images',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _imagePaths.length >= 5 ? null : _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: Text('Add (${_imagePaths.length}/5)'),
                    ),
                  ],
                ),
                if (_imagePaths.isEmpty)
                  Text(
                    'No images selected.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _imagePaths.map((path) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(path),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(path),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(_isEditing ? 'Save changes' : 'Save item'),
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
  }
}

class _WarrantyFieldData {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _WarrantyFieldData({
    required this.keyController,
    required this.valueController,
  });

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}