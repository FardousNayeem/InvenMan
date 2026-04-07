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

    return _InteractiveCardShell(
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.imagePaths.isNotEmpty) ...[
          _ItemImagePreview(
            path: item.imagePaths.first,
            width: 102,
            height: 102,
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryPill(label: item.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _MetaText(label: 'Added', value: formattedCreatedAt),
                          _MetaText(label: 'Updated', value: formattedUpdatedAt),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              if (item.description.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.8,
                    height: 1.4,
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
                    valueText: '${item.quantity} • $stockLabel',
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
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              width: 76,
              height: 46,
              icon: Icons.point_of_sale_rounded,
              filled: true,
              tooltip: item.quantity <= 0 ? 'Out of stock' : 'Sell item',
              onPressed: item.quantity <= 0 ? null : onSell,
            ),
            const SizedBox(width: 10),
            _OverflowActionButton(
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.imagePaths.isNotEmpty) ...[
          _ItemImagePreview(
            path: item.imagePaths.first,
            width: double.infinity,
            height: 132,
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
                  _CategoryPill(label: item.category),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  width: 60,
                  height: 42,
                  icon: Icons.point_of_sale_rounded,
                  filled: true,
                  tooltip: item.quantity <= 0 ? 'Out of stock' : 'Sell item',
                  onPressed: item.quantity <= 0 ? null : onSell,
                ),
                const SizedBox(width: 8),
                _OverflowActionButton(
                  compact: true,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _MetaText(label: 'Added', value: formattedCreatedAt),
            _MetaText(label: 'Updated', value: formattedUpdatedAt),
          ],
        ),
        if (item.description.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.8,
              height: 1.4,
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
              valueText: '${item.quantity} • $stockLabel',
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

class _InteractiveCardShell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _InteractiveCardShell({
    required this.child,
    this.onTap,
  });

  @override
  State<_InteractiveCardShell> createState() => _InteractiveCardShellState();
}

class _InteractiveCardShellState extends State<_InteractiveCardShell> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final translateY = _pressed ? 1.5 : (_hovered ? -1.5 : 0.0);
    final scale = _pressed ? 0.992 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        offset: Offset(0, translateY / 100),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: cs.surfaceContainerLow,
                  border: Border.all(
                    color: _hovered ? cs.primary.withOpacity(0.22) : cs.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: _hovered ? 22 : 16,
                      offset: Offset(0, _hovered ? 10 : 6),
                      color: Colors.black.withOpacity(_hovered ? 0.07 : 0.05),
                    ),
                  ],
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
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

class _MetaText extends StatelessWidget {
  final String label;
  final String value;

  const _MetaText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Text(
      '$label: $value',
      style: TextStyle(
        fontSize: 11.8,
        color: cs.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double width;
  final double height;
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
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final button = filled
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Icon(icon, size: 21),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              side: BorderSide(color: cs.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Icon(icon, size: 21),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OverflowActionButton({
    this.compact = false,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: compact ? 38 : 42,
      height: compact ? 38 : 42,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(compact ? 13 : 14),
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: 'More actions',
        icon: Icon(
          Icons.more_vert_rounded,
          color: cs.onSurfaceVariant,
          size: compact ? 18 : 19,
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
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
              fontSize: 12.4,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isSensitive)
            SensitiveValueText(
              visibleText: sensitiveText ?? '',
              style: TextStyle(
                fontSize: 12.6,
                fontWeight: FontWeight.w800,
                color: valueColor ?? cs.onSurface,
              ),
            )
          else
            Text(
              valueText ?? '',
              style: TextStyle(
                fontSize: 12.6,
                fontWeight: FontWeight.w800,
                color: valueColor ?? cs.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}