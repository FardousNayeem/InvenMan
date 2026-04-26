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

    return InteractiveCardShell(
      onTap: onTap,
      borderRadius: compact ? 24 : 26,
      pressedScale: 0.988,
      child: Padding(
        padding: ResponsiveCardUtils.cardPadding(context),
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
            stockColor: stockColor,
            stockLabel: stockLabel,
            compact: false,
          ),
        ),
        const SizedBox(width: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _InventoryRightRail(
            formattedCreatedAt: formattedCreatedAt,
            formattedUpdatedAt: formattedUpdatedAt,
            item: item,
            onSell: onSell,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
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
  final Color stockColor;
  final String stockLabel;
  final bool compact;

  const _InventoryMainInfo({
    required this.item,
    required this.brandText,
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
        _InventoryTitleRow(item: item, compact: compact),
        const SizedBox(height: 8),
        _InventoryMetaChips(item: item, brandText: brandText),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InventoryTitleRow(item: item, compact: compact),
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
        Flexible(
          child: Text(
            title,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: ResponsiveCardUtils.titleFontSize(context),
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? -0.28 : -0.35,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 0,
          child: _CategoryPill(label: item.category),
        ),
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
            maxLines: 1,
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

class _InventoryRightRail extends StatelessWidget {
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final Item item;
  final VoidCallback onSell;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryRightRail({
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.item,
    required this.onSell,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ResponsiveCardUtils.visualSize(context) + 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _InventoryDateMeta(
            formattedCreatedAt: formattedCreatedAt,
            formattedUpdatedAt: formattedUpdatedAt,
            alignEnd: true,
            forceSingleLine: true,
          ),
          const Spacer(),
          _InventoryActions(
            item: item,
            onSell: onSell,
            onEdit: onEdit,
            onDelete: onDelete,
            compact: false,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _InventoryDateMeta extends StatelessWidget {
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final bool alignEnd;
  final bool forceSingleLine;

  const _InventoryDateMeta({
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    this.alignEnd = false,
    this.forceSingleLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MetaText(label: 'Added', value: formattedCreatedAt),
        const SizedBox(width: 10),
        MetaText(label: 'Updated', value: formattedUpdatedAt),
      ],
    );

    if (forceSingleLine) {
      return Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: row,
        ),
      );
    }

    return Wrap(
      alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        MetaText(label: 'Added', value: formattedCreatedAt),
        MetaText(label: 'Updated', value: formattedUpdatedAt),
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
          child: _InventoryDateMeta(
            formattedCreatedAt: formattedCreatedAt,
            formattedUpdatedAt: formattedUpdatedAt,
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
      spacing: 8,
      runSpacing: 8,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          width: compact ? 64 : 92,
          height: compact ? 52 : 64,
          icon: Icons.point_of_sale_rounded,
          iconSize: compact ? 24 : 32,
          borderRadius: compact ? 16 : 20,
          filled: true,
          tooltip: item.quantity <= 0 ? 'Out of stock' : 'Sell item',
          onPressed: item.quantity <= 0 ? null : onSell,
        ),
        SizedBox(width: compact ? 8 : 10),
        _OverflowActionButton(
          compact: compact,
          size: compact ? 42 : 48,
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
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 7),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(5),
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

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.onSecondaryContainer.withOpacity(0.06),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: 11.8,
          height: 1,
          letterSpacing: 0.15,
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
              elevation: 0,
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
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: 'More actions',
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withOpacity(0.68),
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: const Icon(Icons.more_vert_rounded),
      ),
    );
  }
}