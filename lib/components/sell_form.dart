import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/components/app_text_field.dart';
import 'package:invenman/components/sensitive_value_text.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/db_services.dart';
import 'package:invenman/services/image_service.dart';

class SellItemDialog extends StatefulWidget {
  final Item item;

  const SellItemDialog({
    super.key,
    required this.item,
  });

  @override
  State<SellItemDialog> createState() => _SellItemDialogState();
}

class _SellItemDialogState extends State<SellItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _quantityController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _installmentMonthsController;
  late final TextEditingController _downPaymentController;

  String _paymentType = 'direct';
  bool _isSubmitting = false;
  List<String> _installmentImagePaths = [];
  List<String> _selectedSoldColors = [];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _sellPriceController =
        TextEditingController(text: widget.item.sellingPrice.toStringAsFixed(0));
    _customerNameController = TextEditingController();
    _customerPhoneController = TextEditingController();
    _customerAddressController = TextEditingController();
    _installmentMonthsController = TextEditingController();
    _downPaymentController = TextEditingController();

    if (widget.item.colors.length == 1) {
      _selectedSoldColors = [widget.item.colors.first];
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _sellPriceController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _installmentMonthsController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  double get _sellPricePerUnit =>
      double.tryParse(_sellPriceController.text.trim()) ?? 0;

  int? get _installmentMonths =>
      int.tryParse(_installmentMonthsController.text.trim());

  double? get _downPayment =>
      double.tryParse(_downPaymentController.text.trim());

  double get _totalSaleAmount => _sellPricePerUnit * _quantity;

  double get _estimatedProfit =>
      (_sellPricePerUnit - widget.item.costPrice) * _quantity;

  double get _normalizedDownPayment {
    if (_paymentType != 'installment') return 0;
    return _downPayment ?? 0;
  }

  double get _financedAmount {
    final financed = _totalSaleAmount - _normalizedDownPayment;
    return financed < 0 ? 0 : financed;
  }

  double get _estimatedMonthlyAmount {
    final months = _installmentMonths;
    if (_paymentType != 'installment' || months == null || months <= 0) {
      return 0;
    }
    return _financedAmount / months;
  }

  DateTime get _estimatedFirstDueDate => _addMonths(DateTime.now(), 1);

  String? _validateQuantity(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter valid quantity';
    if (parsed > widget.item.quantity) return 'Exceeds available stock';
    return null;
  }

  String? _validateSellPrice(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter valid amount';
    return null;
  }

  String? _validateInstallmentMonths(String? value) {
    if (_paymentType != 'installment') return null;

    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter valid months';
    return null;
  }

  String? _validateDownPayment(String? value) {
    if (_paymentType != 'installment') return null;

    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Enter down payment';
    if (parsed <= 0) return 'Must be greater than zero';
    if (_totalSaleAmount > 0 && parsed >= _totalSaleAmount) {
      return 'Must be less than total sale';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  Future<void> _pickInstallmentImages() async {
    try {
      final picked = await ImageService.pickAndProcessInstallmentImages(
        existingPaths: _installmentImagePaths,
        context: context,
      );
      if (!mounted) return;

      setState(() {
        _installmentImagePaths = picked.take(5).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add installment images: $e')),
      );
    }
  }

  Future<void> _removeInstallmentImage(String path) async {
    setState(() {
      _installmentImagePaths.remove(path);
    });
    await ImageService.deleteImageFile(path);
  }

  void _toggleSoldColor(String color) {
    setState(() {
      if (_selectedSoldColors.any((e) => e.toLowerCase() == color.toLowerCase())) {
        _selectedSoldColors.removeWhere(
          (e) => e.toLowerCase() == color.toLowerCase(),
        );
      } else {
        _selectedSoldColors = [..._selectedSoldColors, color];
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (widget.item.colors.isNotEmpty && _selectedSoldColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one sold color.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await DBHelper.sellItem(
        item: widget.item,
        quantitySold: int.parse(_quantityController.text.trim()),
        sellPricePerUnit: double.parse(_sellPriceController.text.trim()),
        customerName: _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim().isEmpty
            ? null
            : _customerPhoneController.text.trim(),
        customerAddress: _customerAddressController.text.trim().isEmpty
            ? null
            : _customerAddressController.text.trim(),
        paymentType: _paymentType,
        installmentMonths: _paymentType == 'installment'
            ? int.parse(_installmentMonthsController.text.trim())
            : null,
        downPayment: _paymentType == 'installment'
            ? double.parse(_downPaymentController.text.trim())
            : null,
        soldColors: _selectedSoldColors,
        installmentImagePaths:
            _paymentType == 'installment' ? _installmentImagePaths : const [],
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cs = Theme.of(context).colorScheme;
    final totalSaleAmount = _totalSaleAmount;
    final estimatedProfit = _estimatedProfit;
    final financedAmount = _financedAmount;
    final estimatedMonthlyAmount = _estimatedMonthlyAmount;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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
                      'Sell ${item.name}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Available stock: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated profit',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SensitiveValueText(
                            visibleText: estimatedProfit.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: estimatedProfit >= 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This stays hidden when sensitive values are disabled.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: cs.onSecondaryContainer.withOpacity(0.82),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(title: 'Sale setup'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _quantityController,
                            label: 'Quantity',
                            keyboardType: TextInputType.number,
                            validator: _validateQuantity,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _sellPriceController,
                            label: 'Sales Price',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: _validateSellPrice,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Total sale amount: ',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              totalSaleAmount.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.colors.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SectionTitle(title: 'Sold colors'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.colors.map((color) {
                          final selected = _selectedSoldColors.any(
                            (e) => e.toLowerCase() == color.toLowerCase(),
                          );

                          return FilterChip(
                            selected: selected,
                            label: Text(color),
                            onSelected: (_) => _toggleSoldColor(color),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _SectionTitle(title: 'Customer details'),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _customerNameController,
                      label: 'Customer name',
                      hint: 'Optional',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _customerPhoneController,
                      label: 'Phone number',
                      hint: 'Optional',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _customerAddressController,
                      label: 'Address',
                      hint: 'Optional',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle(title: 'Payment type'),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'direct',
                          label: Text('Direct'),
                          icon: Icon(Icons.payments_outlined),
                        ),
                        ButtonSegment<String>(
                          value: 'installment',
                          label: Text('Installment'),
                          icon: Icon(Icons.calendar_month_outlined),
                        ),
                      ],
                      selected: {_paymentType},
                      onSelectionChanged: (value) {
                        setState(() {
                          _paymentType = value.first;
                          if (_paymentType == 'direct') {
                            _installmentMonthsController.clear();
                            _downPaymentController.clear();
                            _installmentImagePaths = [];
                          }
                        });
                      },
                    ),
                    if (_paymentType == 'installment') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _installmentMonthsController,
                              label: 'Installment months',
                              keyboardType: TextInputType.number,
                              validator: _validateInstallmentMonths,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _downPaymentController,
                              label: 'Down payment',
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              validator: _validateDownPayment,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Installment breakdown',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _BreakdownLine(
                              label: 'Total sale',
                              value: totalSaleAmount.toStringAsFixed(2),
                            ),
                            const SizedBox(height: 8),
                            _BreakdownLine(
                              label: 'Down payment',
                              value: _normalizedDownPayment.toStringAsFixed(2),
                            ),
                            const SizedBox(height: 8),
                            _BreakdownLine(
                              label: 'Financed amount',
                              value: financedAmount.toStringAsFixed(2),
                            ),
                            const SizedBox(height: 8),
                            _BreakdownLine(
                              label: 'Approx. monthly',
                              value: _installmentMonths != null &&
                                      _installmentMonths! > 0
                                  ? estimatedMonthlyAmount.toStringAsFixed(2)
                                  : '—',
                            ),
                            const SizedBox(height: 8),
                            _BreakdownLine(
                              label: 'First due',
                              value: _installmentMonths != null &&
                                      _installmentMonths! > 0
                                  ? _formatDate(_estimatedFirstDueDate)
                                  : '—',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'The remaining balance after down payment will be split across the entered installment months.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Installment images',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _installmentImagePaths.length >= 5
                                ? null
                                : _pickInstallmentImages,
                            icon: const Icon(Icons.add_photo_alternate_rounded),
                            label: Text('Add (${_installmentImagePaths.length}/5)'),
                          ),
                        ],
                      ),
                      if (_installmentImagePaths.isEmpty)
                        Text(
                          'No installment-related images selected.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _installmentImagePaths.map((path) {
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
                                    onTap: () => _removeInstallmentImage(path),
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
                    ],
                    if (item.warranties.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SectionTitle(title: 'Warranties included'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.warranties.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${entry.key}: ${entry.value} mo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
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
                                : const Text('Record Sale'),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  final String label;
  final String value;

  const _BreakdownLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

DateTime _addMonths(DateTime date, int monthsToAdd) {
  final totalMonths = (date.year * 12 + date.month - 1) + monthsToAdd;
  final newYear = totalMonths ~/ 12;
  final newMonth = (totalMonths % 12) + 1;

  final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
  final newDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

  return DateTime(
    newYear,
    newMonth,
    newDay,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}