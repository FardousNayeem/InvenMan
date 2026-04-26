import 'dart:io';

import 'package:flutter/material.dart';

import 'package:invenman/components/common/interactive_card_shell.dart';
import 'package:invenman/components/common/meta_inline_chip.dart';
import 'package:invenman/components/common/meta_text.dart';
import 'package:invenman/components/common/metric_chip.dart';
import 'package:invenman/components/common/responsive_card_utils.dart';
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
    final compact = ResponsiveCardUtils.isCompact(context);
    final stockColor = _stockColor();
    final stockLabel = _stockLabel();

    return InteractiveCardShell(
      onTap: onTap,
      borderRadius: compact ? 24 : 26,
      child: Padding(
        padding: ResponsiveCardUtils.cardPadding(context),
        child: compact
            ? _InventoryCardCompact(
                item: item,
                formattedCreatedAt: formattedCreatedAt,
                formattedUpdatedAt: formattedUpdatedAt,
                stockColor: stockColor,
                stockLabel: stockLabel,
                onSell: onSell,
                onEdit: onEdit,
                onDelete: onDelete,
              )
            : _InventoryCardWide(
                item: item,
                formattedCreatedAt: formattedCreatedAt,
                formattedUpdatedAt: formattedUpdatedAt,
                stockColor: stockColor,
                stockLabel: stockLabel,
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

  String get _brandText {
    final brand = item.brand.trim();
    return brand.isEmpty ? 'Unbranded' : brand;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _InventoryItemVisual(
          item: item,
          size: ResponsiveCardUtils.visualSize(context),
        ),
        SizedBox(width: ResponsiveCardUtils.horizontalGap(context)),
        Expanded(
          child: _InventoryMainInfo(
            item: item,
            brandText: _brandText,
            formattedCreatedAt: formattedCreatedAt,
            formattedUpdatedAt: formattedUpdatedAt,
            stockColor: stockColor,
            stockLabel: stockLabel,
            compact: false,
          ),
        ),
        const SizedBox(width: 18),
        _InventoryActions(
          item: item,
          onSell: onSell,
          onEdit: onEdit,
          onDelete: onDelete,
          compact: false,
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

  String get _brandText {
    final brand = item.brand.trim();
    return brand.isEmpty ? 'Unbranded' : brand;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _InventoryItemVisual(
              item: item,
              size: ResponsiveCardUtils.visualSize(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InventoryHeaderAndMeta(
                item: item,
                brandText: _brandText,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InventoryDateAndActionsRow(
          formattedCreatedAt: formattedCreatedAt,
          formattedUpdatedAt: formattedUpdatedAt,
          item: item,
          onSell: onSell,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        const SizedBox(height: 12),
        _InventoryMetrics(
          item: item,
          stockColor: stockColor,
          stockLabel: stockLabel,
        ),
      ],
    );
  }
}

class _InventoryMainInfo extends StatelessWidget {
  final Item item;
  final String brandText;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final Color stockColor;
  final String stockLabel;
  final bool compact;

  const _InventoryMainInfo({
    required this.item,
    required this.brandText,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.stockColor,
    required this.stockLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _InventoryTitleRow(
                item: item,
                compact: compact,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              flex: 4,
              child: Align(
                alignment: Alignment.topRight,
                child: ResponsiveChipWrap(
                  spacing: 12,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
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
        _InventoryMetaChips(
          item: item,
          brandText: brandText,
        ),
        _InventoryOptionalDescriptionAndSupplier(item: item),
        const SizedBox(height: 14),
        _InventoryMetrics(
          item: item,
          stockColor: stockColor,
          stockLabel: stockLabel,
        ),
      ],
    );
  }
}

class _InventoryHeaderAndMeta extends StatelessWidget {
  final Item item;
  final String brandText;
  final bool compact;

  const _InventoryHeaderAndMeta({
    required this.item,
    required this.brandText,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InventoryTitleRow(
          item: item,
          compact: compact,
        ),
        const SizedBox(height: 6),
        _InventoryMetaChips(
          item: item,
          brandText: brandText,
          compact: compact,
        ),
        _InventoryOptionalDescriptionAndSupplier(
          item: item,
          compact: compact,
        ),
      ],
    );
  }
}

class _InventoryTitleRow extends StatelessWidget {
  final Item item;
  final bool compact;

  const _InventoryTitleRow({
    required this.item,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.name.trim().isEmpty ? 'Unnamed item' : item.name.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: ResponsiveCardUtils.titleFontSize(context),
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? -0.28 : -0.35,
              height: compact ? 1.12 : 1.1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _CategoryPill(label: item.category),
      ],
    );
  }
}

class _InventoryMetaChips extends StatelessWidget {
  final Item item;
  final String brandText;
  final bool compact;

  const _InventoryMetaChips({
    required this.item,
    required this.brandText,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveChipWrap(
      spacing: compact ? 8 : 10,
      runSpacing: 8,
      children: [
        MetaInlineChip(
          icon: Icons.workspace_premium_outlined,
          text: brandText,
        ),
        if (item.colors.isNotEmpty)
          MetaInlineChip(
            icon: Icons.palette_outlined,
            text: item.colors.join(', '),
          ),
      ],
    );
  }
}

class _InventoryOptionalDescriptionAndSupplier extends StatelessWidget {
  final Item item;
  final bool compact;

  const _InventoryOptionalDescriptionAndSupplier({
    required this.item,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final description = item.description.trim();
    final supplier = item.supplier.trim();

    if (description.isEmpty && supplier.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 13.5 : 13.8,
              height: compact ? 1.35 : 1.38,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (supplier.isNotEmpty) ...[
          SizedBox(height: compact ? 6 : 8),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: compact ? 15.5 : 16,
                color: cs.onSurfaceVariant,
              ),
              SizedBox(width: compact ? 6 : 7),
              Expanded(
                child: Text(
                  supplier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 12.8 : 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InventoryDateAndActionsRow extends StatelessWidget {
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final Item item;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryDateAndActionsRow({
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.item,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ResponsiveChipWrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              MetaText(label: 'Added', value: formattedCreatedAt),
              MetaText(label: 'Updated', value: formattedUpdatedAt),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _InventoryActions(
          item: item,
          onSell: onSell,
          onEdit: onEdit,
          onDelete: onDelete,
          compact: true,
        ),
      ],
    );
  }
}

class _InventoryMetrics extends StatelessWidget {
  final Item item;
  final Color stockColor;
  final String stockLabel;

  const _InventoryMetrics({
    required this.item,
    required this.stockColor,
    required this.stockLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveChipWrap(
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
    );
  }
}

class _InventoryActions extends StatelessWidget {
  final Item item;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  const _InventoryActions({
    required this.item,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
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
    final text = label.trim().isEmpty ? 'Uncategorized' : label.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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