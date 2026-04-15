import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invenman/components/app_text_field.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/db_services.dart';
import 'package:invenman/services/image_service.dart';

class ItemFormDialog extends StatefulWidget {
  final Item? existingItem;

  const ItemFormDialog({
    super.key,
    this.existingItem,
  });

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _brandController;
  late final TextEditingController _supplierController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _colorInputController;
  late final FocusNode _categoryFocusNode;

  final List<_WarrantyFieldData> _warrantyFields = [];
  List<String> _imagePaths = [];
  List<String> _categorySuggestions = [];
  List<String> _colors = [];

  bool _isSubmitting = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _categoryController = TextEditingController(text: item?.category ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _supplierController = TextEditingController(text: item?.supplier ?? '');
    _costPriceController = TextEditingController(
      text: item != null ? item.costPrice.toStringAsFixed(0) : '',
    );
    _sellingPriceController = TextEditingController(
      text: item != null ? item.sellingPrice.toStringAsFixed(0) : '',
    );
    _quantityController = TextEditingController(
      text: item != null ? item.quantity.toString() : '',
    );
    _colorInputController = TextEditingController();

    _categoryFocusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _categoryController.addListener(() {
      if (mounted) setState(() {});
    });

    _costPriceController.addListener(() {
      if (mounted) setState(() {});
    });

    _sellingPriceController.addListener(() {
      if (mounted) setState(() {});
    });

    _imagePaths = List<String>.from(item?.imagePaths ?? const []);
    _colors = _normalizeColors(item?.colors ?? const []);

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

    _loadCategorySuggestions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _supplierController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _colorInputController.dispose();
    _categoryFocusNode.dispose();

    for (final field in _warrantyFields) {
      field.dispose();
    }

    super.dispose();
  }

  Future<void> _loadCategorySuggestions() async {
    final categories = await DBHelper.fetchDistinctCategories();
    if (!mounted) return;

    setState(() {
      _categorySuggestions = _dedupeCategories(categories);
    });
  }

  List<String> _dedupeCategories(List<String> categories) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in categories) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final key = trimmed.toLowerCase();
      if (seen.contains(key)) continue;

      seen.add(key);
      cleaned.add(trimmed);
    }

    return cleaned;
  }

  List<String> _normalizeColors(List<String> colors) {
    final seen = <String>{};
    final normalized = <String>[];

    for (final raw in colors) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final cleaned = trimmed
          .split(RegExp(r'\s+'))
          .where((e) => e.trim().isNotEmpty)
          .map((word) {
            if (word.length == 1) return word.toUpperCase();
            return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
          })
          .join(' ');

      final key = cleaned.toLowerCase();
      if (seen.contains(key)) continue;

      seen.add(key);
      normalized.add(cleaned);
    }

    return normalized;
  }

  List<String> get _filteredCategorySuggestions {
    if (_categorySuggestions.isEmpty) return const [];

    final input = _categoryController.text.trim().toLowerCase();

    if (input.isEmpty) {
      return _categorySuggestions.take(8).toList();
    }

    final startsWith = <String>[];
    final contains = <String>[];

    for (final category in _categorySuggestions) {
      final lower = category.toLowerCase();
      if (lower == input) continue;

      if (lower.startsWith(input)) {
        startsWith.add(category);
      } else if (lower.contains(input)) {
        contains.add(category);
      }
    }

    return [...startsWith, ...contains].take(8).toList();
  }

  bool get _showCategorySuggestions {
    return _categoryFocusNode.hasFocus && _categorySuggestions.isNotEmpty;
  }

  bool get _hasExactCategoryMatch {
    final input = _categoryController.text.trim().toLowerCase();
    if (input.isEmpty) return false;
    return _categorySuggestions.any((c) => c.toLowerCase() == input);
  }

  void _applyCategorySuggestion(String value) {
    setState(() {
      _categoryController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    });
    _categoryFocusNode.unfocus();
  }

  void _addColor() {
    final raw = _colorInputController.text.trim();
    if (raw.isEmpty) return;

    final normalized = _normalizeColors([raw]);
    if (normalized.isEmpty) return;

    final color = normalized.first;
    final exists = _colors.any((e) => e.toLowerCase() == color.toLowerCase());
    if (exists) {
      _colorInputController.clear();
      return;
    }

    setState(() {
      _colors = [..._colors, color];
      _colorInputController.clear();
    });
  }

  void _removeColor(String color) {
    setState(() {
      _colors.removeWhere((e) => e.toLowerCase() == color.toLowerCase());
    });
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

  String? _validateCostAgainstMrp() {
    final cost = double.tryParse(_costPriceController.text.trim());
    final mrp = double.tryParse(_sellingPriceController.text.trim());

    if (cost == null || mrp == null) return null;
    if (cost > mrp) return 'Cost price cannot be greater than MRP.';
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

      final duplicateKey = map.keys.any(
        (existing) => existing.toLowerCase() == key.toLowerCase(),
      );
      if (duplicateKey) {
        throw Exception('Duplicate warranty names are not allowed.');
      }

      map[key] = months;
    }

    return map;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final moneyRelationshipError = _validateCostAgainstMrp();
    if (moneyRelationshipError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(moneyRelationshipError)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final warranties = _buildWarranties();
      final now = DateTime.now().toUtc();
      final normalizedColors = _normalizeColors(_colors);

      final item = (_isEditing ? widget.existingItem! : null)?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            brand: _brandController.text.trim(),
            colors: normalizedColors,
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
            brand: _brandController.text.trim(),
            colors: normalizedColors,
            costPrice: double.parse(_costPriceController.text.trim()),
            sellingPrice: double.parse(_sellingPriceController.text.trim()),
            quantity: int.parse(_quantityController.text.trim()),
            supplier: _supplierController.text.trim(),
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filteredSuggestions = _filteredCategorySuggestions;
    final moneyRelationshipError = _validateCostAgainstMrp();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: AbsorbPointer(
              absorbing: _isSubmitting,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit item' : 'Add item',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set product details, brand, colors, supplier, category, warranty, stock, and images.',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _categoryController,
                                focusNode: _categoryFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  hintText: 'AC, Fridge, Rice Cooker...',
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    borderSide: BorderSide(
                                      color: cs.outlineVariant,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty ? 'Required' : null,
                              ),
                              if (_showCategorySuggestions) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: cs.outlineVariant),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 16,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _categoryController.text.trim().isEmpty
                                                ? 'Previously used categories'
                                                : _hasExactCategoryMatch
                                                    ? 'Matching saved categories'
                                                    : 'Suggested saved categories',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (filteredSuggestions.isEmpty)
                                        Text(
                                          'No saved category matches yet. You can create a new one.',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: cs.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        )
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: filteredSuggestions.map((category) {
                                            return ActionChip(
                                              label: Text(category),
                                              onPressed: () => _applyCategorySuggestion(category),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
                            controller: _brandController,
                            label: 'Brand',
                            hint: 'Optional',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _quantityController,
                            label: 'Quantity',
                            keyboardType: TextInputType.number,
                            validator: _validateQuantity,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Colors',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _colorInputController,
                                  label: 'Add color',
                                  hint: 'Black, Silver, Blue...',
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: _colorInputController.text.trim().isEmpty
                                    ? null
                                    : _addColor,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_colors.isEmpty)
                            Text(
                              'No colors added.',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _colors.map((color) {
                                return InputChip(
                                  label: Text(color),
                                  onDeleted: () => _removeColor(color),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _costPriceController,
                            label: 'Cost price',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _sellingPriceController,
                            label: 'MRP',
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            validator: _validateMoney,
                          ),
                        ),
                      ],
                    ),
                    if (moneyRelationshipError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        moneyRelationshipError,
                        style: TextStyle(
                          color: cs.error,
                          fontSize: 12.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Warranties',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
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
                                  width: 92,
                                  height: 92,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 92,
                                    height: 92,
                                    color: cs.surfaceContainerHighest,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: InkWell(
                                  onTap: () => _removeImage(path),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.65),
                                      shape: BoxShape.circle,
                                    ),
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
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.2),
                                  )
                                : Text(_isEditing ? 'Save Changes' : 'Add Item'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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