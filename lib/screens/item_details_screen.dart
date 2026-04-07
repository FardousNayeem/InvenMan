import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/components/sensitive_value_text.dart';
import 'package:invenman/models/item.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;
  final VoidCallback? onEdit;
  final VoidCallback? onSell;
  final VoidCallback? onDelete;

  const ItemDetailsScreen({
    super.key,
    required this.item,
    this.onEdit,
    this.onSell,
    this.onDelete,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int _selectedImageIndex = 0;

  Item get item => widget.item;

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  String get _stockLabel {
    if (item.quantity <= 0) return 'Out of stock';
    if (item.quantity <= 3) return 'Low stock';
    return 'In stock';
  }

  Color _stockColor(ColorScheme cs) {
    if (item.quantity <= 0) return Colors.red.shade700;
    if (item.quantity <= 3) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  double get _marginAmount => item.sellingPrice - item.costPrice;

  String get _marginPercent {
    if (item.costPrice <= 0) return '—';
    final percent = ((_marginAmount / item.costPrice) * 100);
    return '${percent.toStringAsFixed(1)}%';
  }

  int get _safeSelectedIndex {
    if (item.imagePaths.isEmpty) return 0;
    return math.min(_selectedImageIndex, item.imagePaths.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 860;
    final stockColor = _stockColor(cs);

    final selectedImagePath =
        item.imagePaths.isNotEmpty ? item.imagePaths[_safeSelectedIndex] : null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 390,
            backgroundColor: cs.surface,
            surfaceTintColor: cs.surfaceTint,
            leading: _HeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (widget.onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _HeaderIconButton(
                    icon: Icons.edit_rounded,
                    onPressed: widget.onEdit,
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 20,
                bottom: 18,
              ),
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (selectedImagePath != null)
                    Image.file(
                      File(selectedImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _HeroPlaceholder(
                        icon: Icons.inventory_2_rounded,
                        label: item.category,
                      ),
                    )
                  else
                    _HeroPlaceholder(
                      icon: Icons.inventory_2_rounded,
                      label: item.category,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.58),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 94,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _TopPill(
                              icon: Icons.category_rounded,
                              label: item.category,
                            ),
                            _TopPill(
                              icon: Icons.inventory_2_outlined,
                              label: _stockLabel,
                              accentColor: stockColor,
                            ),
                            _TopPill(
                              icon: Icons.sell_outlined,
                              label: 'MRP ${item.sellingPrice.toStringAsFixed(0)}',
                            ),
                            if (item.supplier.trim().isNotEmpty)
                              _TopPill(
                                icon: Icons.local_shipping_outlined,
                                label: item.supplier,
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.description.trim().isEmpty
                              ? 'A clean inventory profile for this product.'
                              : item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imagePaths.length > 1) ...[
                    _ThumbnailRail(
                      imagePaths: item.imagePaths,
                      selectedIndex: _safeSelectedIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (widget.onSell != null || widget.onEdit != null || widget.onDelete != null)
                    _ActionStrip(
                      canSell: item.quantity > 0,
                      onSell: widget.onSell,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                    ),
                  if (widget.onSell != null || widget.onEdit != null || widget.onDelete != null)
                    const SizedBox(height: 18),
                  if (isCompact)
                    Column(
                      children: [
                        _OverviewCard(
                          item: item,
                          stockColor: stockColor,
                          formattedCreatedAt: _formatDate(item.createdAt),
                          formattedUpdatedAt: _formatDate(item.updatedAt),
                          marginAmount: _marginAmount,
                          marginPercent: _marginPercent,
                        ),
                        const SizedBox(height: 14),
                        _DescriptionCard(description: item.description),
                        const SizedBox(height: 14),
                        _WarrantyCard(warranties: item.warranties),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _OverviewCard(
                                item: item,
                                stockColor: stockColor,
                                formattedCreatedAt: _formatDate(item.createdAt),
                                formattedUpdatedAt: _formatDate(item.updatedAt),
                                marginAmount: _marginAmount,
                                marginPercent: _marginPercent,
                              ),
                              const SizedBox(height: 14),
                              _DescriptionCard(description: item.description),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: _WarrantyCard(warranties: item.warranties),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _HeaderIconButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.18),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPlaceholder({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHighest,
            cs.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _TopPill({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = accentColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailRail extends StatelessWidget {
  final List<String> imagePaths;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ThumbnailRail({
    required this.imagePaths,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final path = imagePaths[index];
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 94,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                          color: cs.primary.withOpacity(0.18),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  final bool canSell;
  final VoidCallback? onSell;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ActionStrip({
    required this.canSell,
    this.onSell,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;

    if (compact) {
      return Column(
        children: [
          Row(
            children: [
              if (onSell != null)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canSell ? onSell : null,
                    icon: const Icon(Icons.point_of_sale_rounded),
                    label: const Text('Sell'),
                  ),
                ),
              if (onSell != null && onEdit != null) const SizedBox(width: 10),
              if (onEdit != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                ),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        if (onSell != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: canSell ? onSell : null,
              icon: const Icon(Icons.point_of_sale_rounded),
              label: Text(canSell ? 'Sell Item' : 'Out of Stock'),
            ),
          ),
        if (onSell != null && onEdit != null) const SizedBox(width: 10),
        if (onEdit != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Item'),
            ),
          ),
        if ((onSell != null || onEdit != null) && onDelete != null)
          const SizedBox(width: 10),
        if (onDelete != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
            ),
          ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final Item item;
  final Color stockColor;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;
  final double marginAmount;
  final String marginPercent;

  const _OverviewCard({
    required this.item,
    required this.stockColor,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
    required this.marginAmount,
    required this.marginPercent,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Overview',
      subtitle: 'Core pricing, stock, and sourcing details',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Cost',
                  sensitiveText: item.costPrice.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'MRP',
                  valueText: item.sellingPrice.toStringAsFixed(0),
                  icon: Icons.sell_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Margin',
                  sensitiveText: marginAmount.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.trending_up_rounded,
                  valueColor: marginAmount >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Markup',
                  sensitiveText: marginPercent,
                  isSensitive: true,
                  icon: Icons.percent_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Stock',
                  valueText: '${item.quantity}',
                  icon: Icons.inventory_2_outlined,
                  valueColor: stockColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Images',
                  valueText: '${item.imagePaths.length}',
                  icon: Icons.image_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LineItem(
            label: 'Supplier',
            value: item.supplier.trim().isEmpty ? 'Not provided' : item.supplier,
          ),
          const SizedBox(height: 8),
          _LineItem(label: 'Created', value: formattedCreatedAt),
          const SizedBox(height: 8),
          _LineItem(label: 'Updated', value: formattedUpdatedAt),
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  final String description;

  const _DescriptionCard({
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Description',
      subtitle: 'Product notes and descriptive context',
      child: Text(
        description.trim().isEmpty ? 'No description provided.' : description,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  final Map<String, int> warranties;

  const _WarrantyCard({
    required this.warranties,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Warranty breakdown',
      subtitle: 'Coverage by component or part',
      child: warranties.isEmpty
          ? Text(
              'No warranty added.',
              style: TextStyle(
                fontSize: 14.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: warranties.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} mo',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _GlassSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String? valueText;
  final String? sensitiveText;
  final bool isSensitive;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    this.valueText,
    this.sensitiveText,
    this.isSensitive = false,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                if (isSensitive)
                  SensitiveValueText(
                    visibleText: sensitiveText ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? cs.onSurface,
                    ),
                  )
                else
                  Text(
                    valueText ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? cs.onSurface,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  final String label;
  final String value;

  const _LineItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}