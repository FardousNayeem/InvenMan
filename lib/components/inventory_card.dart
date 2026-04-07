import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invenman/components/sensitive_value_text.dart';
import 'package:invenman/models/item.dart';

class InventoryCard extends StatelessWidget {
  final Item item;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const InventoryCard({
    super.key,
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
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

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
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
        if (item.imagePaths.isNotEmpty) ...[
          _ItemImagePreview(path: item.imagePaths.first),
          const SizedBox(width: 14),
        ],
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
                          ),
                          Text(
                            'Updated: $formattedUpdatedAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
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
              if (item.supplier.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Supplier: ${item.supplier}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
                    sensitiveText: item.costPrice.toStringAsFixed(0),
                    isSensitive: true,
                  ),
                  _MetricChip(
                    icon: Icons.sell_outlined,
                    label: 'MRP',
                    valueText: item.sellingPrice.toStringAsFixed(0),
                  ),
                  _MetricChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    valueText: '${item.quantity}',
                    valueColor: stockColor,
                  ),
                  if (item.warranties.isNotEmpty)
                    _MetricChip(
                      icon: Icons.verified_outlined,
                      label: 'Warranty',
                      valueText: '${item.warranties.length} type(s)',
                    ),
                  if (item.imagePaths.isNotEmpty)
                    _MetricChip(
                      icon: Icons.image_outlined,
                      label: 'Images',
                      valueText: '${item.imagePaths.length}',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Row(
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
                child: const Icon(Icons.point_of_sale_rounded, size: 22),
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
        if (item.imagePaths.isNotEmpty) ...[
          _ItemImagePreview(
            path: item.imagePaths.first,
            height: 120,
            width: double.infinity,
          ),
          const SizedBox(height: 12),
        ],
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
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Updated: $formattedUpdatedAt',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                ),
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
                    child: const Icon(Icons.point_of_sale_rounded, size: 20),
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
        if (item.supplier.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Supplier: ${item.supplier}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
              sensitiveText: item.costPrice.toStringAsFixed(0),
              isSensitive: true,
            ),
            _MetricChip(
              icon: Icons.sell_outlined,
              label: 'MRP',
              valueText: item.sellingPrice.toStringAsFixed(0),
            ),
            _MetricChip(
              icon: Icons.inventory_2_outlined,
              label: 'Stock',
              valueText: '${item.quantity}',
              valueColor: stockColor,
            ),
            if (item.warranties.isNotEmpty)
              _MetricChip(
                icon: Icons.verified_outlined,
                label: 'Warranty',
                valueText: '${item.warranties.length} type(s)',
              ),
            if (item.imagePaths.isNotEmpty)
              _MetricChip(
                icon: Icons.image_outlined,
                label: 'Images',
                valueText: '${item.imagePaths.length}',
              ),
          ],
        ),
      ],
    );
  }
}

class _ItemImagePreview extends StatelessWidget {
  final String path;
  final double width;
  final double height;

  const _ItemImagePreview({
    required this.path,
    this.width = 92,
    this.height = 92,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_outlined,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? valueText;
  final String? sensitiveText;
  final bool isSensitive;
  final Color? valueColor;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.valueText,
    this.sensitiveText,
    this.isSensitive = false,
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
          if (isSensitive)
            SensitiveValueText(
              visibleText: sensitiveText ?? '',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? cs.onSurface,
              ),
            )
          else
            Text(
              valueText ?? '',
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