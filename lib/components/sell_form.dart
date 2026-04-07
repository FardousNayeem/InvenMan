import 'package:flutter/material.dart';
import 'package:invenman/components/app_text_field.dart';
import 'package:invenman/db.dart';
import 'package:invenman/models/item.dart';

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

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _sellPriceController =
        TextEditingController(text: widget.item.sellingPrice.toStringAsFixed(0));
    _customerNameController = TextEditingController();
    _customerPhoneController = TextEditingController();
    _customerAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _sellPriceController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  String? _validateMoney(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Invalid';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;
    final sellPrice = double.tryParse(_sellPriceController.text.trim()) ?? 0;
    final estimatedProfit = (sellPrice - item.costPrice) * quantity;

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
                        estimatedProfit.toStringAsFixed(2),
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
                      child: AppTextField(
                        controller: _quantityController,
                        label: 'Quantity',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed <= 0) return 'Invalid';
                          if (parsed > item.quantity) return 'Too many';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _sellPriceController,
                        label: 'Sell price per unit',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _validateMoney,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
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
                if (item.warranties.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Warranties included',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.warranties.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value} mo',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          await DBHelper.sellItem(
                            item: item,
                            quantitySold: int.parse(_quantityController.text.trim()),
                            sellPricePerUnit:
                                double.parse(_sellPriceController.text.trim()),
                            customerName: _customerNameController.text.trim().isEmpty
                                ? null
                                : _customerNameController.text.trim(),
                            customerPhone: _customerPhoneController.text.trim().isEmpty
                                ? null
                                : _customerPhoneController.text.trim(),
                            customerAddress: _customerAddressController.text.trim().isEmpty
                                ? null
                                : _customerAddressController.text.trim(),
                          );

                          if (!mounted) return;
                          Navigator.pop(context, true);
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
  }
}