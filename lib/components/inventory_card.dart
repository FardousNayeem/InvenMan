import 'dart:io';

import 'package:flutter/material.dart';
import 'package:invenman/models/item.dart';

import 'package:invenman/components/common/interactive_card_shell.dart';
import 'package:invenman/components/common/meta_inline_chip.dart';
import 'package:invenman/components/common/meta_text.dart';
import 'package:invenman/components/common/metric_chip.dart';

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

  Color _stockColor() {
    if (item.quantity <= 0) return Colors.red.shade700;
    if (item.quantity <= 3) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  String _stockLabel() {
    if (item.quantity <= 0) return 'Out';
    if (item.quantity <= 3) return 'Low';
    return 'Good';
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;

    return InteractiveCardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: compact
            ? _InventoryCardCompact(
                item: item,
                formattedCreatedAt: formattedCreatedAt,
                formattedUpdatedAt: formattedUpdatedAt,
                stockColor: _stockColor(),
                stockLabel: _stockLabel(),
                onSell: onSell,
                onEdit: onEdit,
                onDelete: onDelete,
              )
            : _InventoryCardWide(
                item: item,
                formattedCreatedAt: formattedCreatedAt,
                formattedUpdatedAt: formattedUpdatedAt,
                stockColor: _stockColor(),
                stockLabel: _stockLabel(),
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
  final String stockLabel;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCardWide({
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.stockColor,
    required this.stockLabel,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  String get _brandText =>
      item.brand.trim().isEmpty ? 'Unbranded' : item.brand.trim();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _InventoryItemVisual(
          item: item,
          size: 102,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.35,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryPill(label: item.category),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          MetaText(label: 'Added', value: formattedCreatedAt),
                          MetaText(label: 'Updated', value: formattedUpdatedAt),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  MetaInlineChip(
                    icon: Icons.workspace_premium_outlined,
                    text: _brandText,
                  ),
                  if (item.colors.isNotEmpty)
                    MetaInlineChip(
                      icon: Icons.palette_outlined,
                      text: item.colors.join(', '),
                    ),
                ],
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.8,
                    height: 1.38,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (item.supplier.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.supplier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  MetricChip(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Cost',
                    sensitiveText: item.costPrice.toStringAsFixed(0),
                    isSensitive: true,
                  ),
                  MetricChip(
                    icon: Icons.sell_outlined,
                    label: 'MRP',
                    valueText: item.sellingPrice.toStringAsFixed(0),
                  ),
                  MetricChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    valueText: '${item.quantity} • $stockLabel',
                    valueColor: stockColor,
                  ),
                  if (item.warranties.isNotEmpty)
                    MetricChip(
                      icon: Icons.verified_outlined,
                      label: 'Warranty',
                      valueText: '${item.warranties.length} type(s)',
                    ),
                  if (item.imagePaths.isNotEmpty)
                    MetricChip(
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ActionButton(
              width: 84,
              height: 56,
              icon: Icons.point_of_sale_rounded,
              iconSize: 29,
              borderRadius: 20,
              filled: true,
              tooltip: item.quantity <= 0 ? 'Out of stock' : 'Sell item',
              onPressed: item.quantity <= 0 ? null : onSell,
            ),
            const SizedBox(width: 10),
            _OverflowActionButton(
              size: 48,
              onEdit: onEdit,
              onDelete: onDelete,
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
  final String stockLabel;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryCardCompact({
    required this.item,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.stockColor,
    required this.stockLabel,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  String get _brandText =>
      item.brand.trim().isEmpty ? 'Unbranded' : item.brand.trim();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _InventoryItemVisual(
              item: item,
              size: 84,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18.8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.28,
                            height: 1.12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CategoryPill(label: item.category),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      MetaInlineChip(
                        icon: Icons.workspace_premium_outlined,
                        text: _brandText,
                      ),
                      if (item.colors.isNotEmpty)
                        MetaInlineChip(
                          icon: Icons.palette_outlined,
                          text: item.colors.join(', '),
                        ),
                    ],
                  ),
                  if (item.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (item.supplier.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 15.5,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.supplier,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                children: [
                  MetaText(label: 'Added', value: formattedCreatedAt),
                  MetaText(label: 'Updated', value: formattedUpdatedAt),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ActionButton(
              width: 58,
              height: 46,
              icon: Icons.point_of_sale_rounded,
              iconSize: 24,
              borderRadius: 16,
              filled: true,
              tooltip: item.quantity <= 0 ? 'Out of stock' : 'Sell item',
              onPressed: item.quantity <= 0 ? null : onSell,
            ),
            const SizedBox(width: 8),
            _OverflowActionButton(
              compact: true,
              size: 42,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            MetricChip(
              icon: Icons.shopping_bag_outlined,
              label: 'Cost',
              sensitiveText: item.costPrice.toStringAsFixed(0),
              isSensitive: true,
            ),
            MetricChip(
              icon: Icons.sell_outlined,
              label: 'MRP',
              valueText: item.sellingPrice.toStringAsFixed(0),
            ),
            MetricChip(
              icon: Icons.inventory_2_outlined,
              label: 'Stock',
              valueText: '${item.quantity} • $stockLabel',
              valueColor: stockColor,
            ),
            if (item.warranties.isNotEmpty)
              MetricChip(
                icon: Icons.verified_outlined,
                label: 'Warranty',
                valueText: '${item.warranties.length} type(s)',
              ),
            if (item.imagePaths.isNotEmpty)
              MetricChip(
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



class _InventoryItemVisual extends StatelessWidget {
  final Item item;
  final double size;

  const _InventoryItemVisual({
    required this.item,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (item.imagePaths.isNotEmpty) {
      return _ItemImagePreview(
        path: item.imagePaths.first,
        width: size,
        height: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.34,
        color: cs.onSurfaceVariant,
      ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        height: height,
        color: cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image_outlined,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double width;
  final double height;
  final double iconSize;
  final double borderRadius;
  final IconData icon;
  final bool filled;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.width,
    required this.height,
    required this.icon,
    required this.filled,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = 21,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final button = filled
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: Icon(icon, size: iconSize),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
            child: Icon(icon, size: iconSize),
          );

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: width,
        height: height,
        child: button,
      ),
    );
  }
}

class _OverflowActionButton extends StatelessWidget {
  final bool compact;
  final double size;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OverflowActionButton({
    this.compact = false,
    this.size = 42,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_rounded),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Icon(Icons.more_horiz_rounded),
      ),
    );
  }
}
