import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invenman/components/common/app_text_field.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/database/db_services.dart';
import 'package:invenman/services/media/image_service.dart';

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
  late final FocusNode _brandFocusNode;

  bool _showCategorySuggestionPanel = false;
  bool _showBrandSuggestionPanel = false;

  final List<_WarrantyFieldData> _warrantyFields = [];
  List<String> _categorySuggestions = [];
  List<String> _brandSuggestions = [];
  List<String> _colors = [];
  List<String> _imagePaths = [];

  late final List<String> _initialImagePaths;
  final Set<String> _newImagePaths = {};
  final Set<String> _removedExistingImagePaths = {};
  bool _didCommitImageChanges = false;

  bool _isSubmitting = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _categoryController = TextEditingController(
      text: _normalizeCategory(item?.category ?? ''),
    );
    _brandController = TextEditingController(
      text: _normalizeBrand(item?.brand ?? ''),
    );
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

    _categoryFocusNode = FocusNode()..addListener(_handleCategoryFocusChange);
    _brandFocusNode = FocusNode()..addListener(_handleBrandFocusChange);

    _categoryController.addListener(_handleCategoryChanged);
    _brandController.addListener(_handleBrandChanged);

    _costPriceController.addListener(() {
      if (mounted) setState(() {});
    });

    _sellingPriceController.addListener(() {
      if (mounted) setState(() {});
    });

    _imagePaths = List<String>.from(item?.imagePaths ?? const []);
    _initialImagePaths = List<String>.from(_imagePaths);
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
    _loadBrandSuggestions();
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
    _brandFocusNode.dispose();

    for (final field in _warrantyFields) {
      field.dispose();
    }
    if (!_didCommitImageChanges && _newImagePaths.isNotEmpty) {
      unawaited(ImageService.deleteImageFiles(_newImagePaths));
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

  Future<void> _loadBrandSuggestions() async {
    final brands = await DBHelper.fetchDistinctBrands();
    if (!mounted) return;

    setState(() {
      _brandSuggestions = _dedupeBrands(brands);
    });
  }

  void _handleCategoryFocusChange() {
    if (_categoryFocusNode.hasFocus) {
      if (!_showCategorySuggestionPanel && mounted) {
        setState(() => _showCategorySuggestionPanel = true);
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      if (_categoryFocusNode.hasFocus) return;
      if (_showCategorySuggestionPanel) {
        setState(() => _showCategorySuggestionPanel = false);
      }
    });
  }

  void _handleBrandFocusChange() {
    if (_brandFocusNode.hasFocus) {
      if (!_showBrandSuggestionPanel && mounted) {
        setState(() => _showBrandSuggestionPanel = true);
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 140), () {
      if (!mounted) return;
      if (_brandFocusNode.hasFocus) return;
      if (_showBrandSuggestionPanel) {
        setState(() => _showBrandSuggestionPanel = false);
      }
    });
  }

  void _handleCategoryChanged() {
    final normalized = _normalizeCategory(_categoryController.text);

    if (_categoryController.text != normalized) {
      _categoryController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      return;
    }

    if (!_showCategorySuggestionPanel && _categoryFocusNode.hasFocus && mounted) {
      setState(() => _showCategorySuggestionPanel = true);
      return;
    }

    if (mounted) setState(() {});
  }

  void _handleBrandChanged() {
    final normalized = _normalizeBrand(_brandController.text);

    if (_brandController.text != normalized) {
      _brandController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      return;
    }

    if (!_showBrandSuggestionPanel && _brandFocusNode.hasFocus && mounted) {
      setState(() => _showBrandSuggestionPanel = true);
      return;
    }

    if (mounted) setState(() {});
  }

  String _normalizeCategory(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ')
        .toUpperCase();
  }

  String _normalizeBrand(String value) {
    final cleaned = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');

    if (cleaned.isEmpty) return '';

    final lower = cleaned.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  List<String> _dedupeCategories(List<String> categories) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in categories) {
      final normalized = _normalizeCategory(raw);
      if (normalized.isEmpty) continue;
      if (seen.contains(normalized)) continue;

      seen.add(normalized);
      cleaned.add(normalized);
    }

    cleaned.sort();
    return cleaned;
  }

  List<String> _dedupeBrands(List<String> brands) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in brands) {
      final normalized = _normalizeBrand(raw);
      if (normalized.isEmpty) continue;

      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;

      seen.add(key);
      cleaned.add(normalized);
    }

    cleaned.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
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

    final input = _normalizeCategory(_categoryController.text);

    if (input.isEmpty) {
      return _categorySuggestions.take(8).toList();
    }

    final startsWith = <String>[];
    final contains = <String>[];

    for (final category in _categorySuggestions) {
      if (category == input) continue;

      if (category.startsWith(input)) {
        startsWith.add(category);
      } else if (category.contains(input)) {
        contains.add(category);
      }
    }

    return [...startsWith, ...contains].take(8).toList();
  }

  List<String> get _filteredBrandSuggestions {
    if (_brandSuggestions.isEmpty) return const [];

    final input = _normalizeBrand(_brandController.text);
    final inputLower = input.toLowerCase();

    if (inputLower.isEmpty) {
      return _brandSuggestions.take(8).toList();
    }

    final startsWith = <String>[];
    final contains = <String>[];

    for (final brand in _brandSuggestions) {
      final brandLower = brand.toLowerCase();
      if (brandLower == inputLower) continue;

      if (brandLower.startsWith(inputLower)) {
        startsWith.add(brand);
      } else if (brandLower.contains(inputLower)) {
        contains.add(brand);
      }
    }

    return [...startsWith, ...contains].take(8).toList();
  }

  bool get _showCategorySuggestions {
    return _showCategorySuggestionPanel && _categorySuggestions.isNotEmpty;
  }

  bool get _showBrandSuggestions {
    return _showBrandSuggestionPanel && _brandSuggestions.isNotEmpty;
  }

  bool get _hasExactCategoryMatch {
    final input = _normalizeCategory(_categoryController.text);
    if (input.isEmpty) return false;
    return _categorySuggestions.any((c) => c == input);
  }

  bool get _hasExactBrandMatch {
    final input = _normalizeBrand(_brandController.text).toLowerCase();
    if (input.isEmpty) return false;
    return _brandSuggestions.any((b) => b.toLowerCase() == input);
  }

  void _applyCategorySuggestion(String value) {
    final normalized = _normalizeCategory(value);

    setState(() {
      _categoryController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      _showCategorySuggestionPanel = false;
    });

    _categoryFocusNode.unfocus();
  }

  void _applyBrandSuggestion(String value) {
    final normalized = _normalizeBrand(value);

    setState(() {
      _brandController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      _showBrandSuggestionPanel = false;
    });

    _brandFocusNode.unfocus();
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
      final before = _imagePaths.toSet();

      final picked = await ImageService.pickAndProcessImages(
        existingPaths: _imagePaths,
      );

      if (!mounted) return;

      final addedPaths = picked.where((path) => !before.contains(path));

      setState(() {
        _imagePaths = picked;
        _newImagePaths.addAll(addedPaths);
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

    if (_newImagePaths.remove(path)) {
      await ImageService.deleteImageFile(path);
      return;
    }

    if (_initialImagePaths.contains(path)) {
      _removedExistingImagePaths.add(path);
    }
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
      final normalizedCategory = _normalizeCategory(_categoryController.text);
      final normalizedBrand = _normalizeBrand(_brandController.text);

      final item = (_isEditing ? widget.existingItem! : null)?.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            category: normalizedCategory,
            brand: normalizedBrand,
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
            category: normalizedCategory,
            brand: normalizedBrand,
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

      final deletedPaths = _removedExistingImagePaths.where(
        (path) => !_imagePaths.contains(path),
      );

      await ImageService.deleteImageFiles(deletedPaths);
      _didCommitImageChanges = true;
      _newImagePaths.clear();
      _removedExistingImagePaths.clear();

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

  InputDecoration _suggestionFieldDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
    );
  }

  Widget _buildSuggestionPanel({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<String> suggestions,
    required String emptyText,
    required ValueChanged<String> onSelected,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
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
                icon,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (suggestions.isEmpty)
            Text(
              emptyText,
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
              children: suggestions.map((value) {
                return ActionChip(
                  label: Text(value),
                  onPressed: () => onSelected(value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filteredCategorySuggestions = _filteredCategorySuggestions;
    final filteredBrandSuggestions = _filteredBrandSuggestions;
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
                                textCapitalization: TextCapitalization.characters,
                                decoration: _suggestionFieldDecoration(
                                  context,
                                  labelText: 'Category',
                                  hintText: 'AC, Fridge, Rice Cooker...',
                                ),
                                validator: (value) => value == null || value.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              if (_showCategorySuggestions) ...[
                                const SizedBox(height: 10),
                                _buildSuggestionPanel(
                                  context: context,
                                  icon: Icons.auto_awesome_rounded,
                                  title: _categoryController.text.trim().isEmpty
                                      ? 'Previously used categories'
                                      : _hasExactCategoryMatch
                                          ? 'Matching saved categories'
                                          : 'Suggested saved categories',
                                  suggestions: filteredCategorySuggestions,
                                  emptyText:
                                      'No saved category matches yet. You can create a new one.',
                                  onSelected: _applyCategorySuggestion,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _brandController,
                                focusNode: _brandFocusNode,
                                textCapitalization: TextCapitalization.words,
                                decoration: _suggestionFieldDecoration(
                                  context,
                                  labelText: 'Brand',
                                  hintText: 'Optional',
                                ),
                              ),
                              if (_showBrandSuggestions) ...[
                                const SizedBox(height: 10),
                                _buildSuggestionPanel(
                                  context: context,
                                  icon: Icons.sell_rounded,
                                  title: _brandController.text.trim().isEmpty
                                      ? 'Previously used brands'
                                      : _hasExactBrandMatch
                                          ? 'Matching saved brands'
                                          : 'Suggested saved brands',
                                  suggestions: filteredBrandSuggestions,
                                  emptyText:
                                      'No saved brand matches yet. You can create a new one.',
                                  onSelected: _applyBrandSuggestion,
                                ),
                              ],
                            ],
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