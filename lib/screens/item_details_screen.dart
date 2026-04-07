import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/theme/app_ui.dart';

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

  Color _stockColor() {
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
    final stockColor = _stockColor();

    final selectedImagePath =
        item.imagePaths.isNotEmpty ? item.imagePaths[_safeSelectedIndex] : null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 360,
            backgroundColor: cs.surface,
            surfaceTintColor: cs.surfaceTint,
            leading: AppHeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              if (widget.onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppHeaderIconButton(
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
                  letterSpacing: -0.65,
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
                    bottom: 88,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            AppHeroPill(
                              icon: Icons.category_rounded,
                              label: item.category,
                            ),
                            AppHeroPill(
                              icon: Icons.inventory_2_outlined,
                              label: _stockLabel,
                              accentColor: stockColor,
                            ),
                            AppHeroPill(
                              icon: Icons.sell_outlined,
                              label: 'MRP ${item.sellingPrice.toStringAsFixed(0)}',
                            ),
                            if (item.supplier.trim().isNotEmpty)
                              AppHeroPill(
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
              padding: const EdgeInsets.fromLTRB(
                AppUi.pageHPadding,
                18,
                AppUi.pageHPadding,
                AppUi.pageBottomPadding,
              ),
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
                    const SizedBox(height: 16),
                  ],
                  if (widget.onSell != null ||
                      widget.onEdit != null ||
                      widget.onDelete != null)
                    _ActionStrip(
                      canSell: item.quantity > 0,
                      onSell: widget.onSell,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                    ),
                  if (widget.onSell != null ||
                      widget.onEdit != null ||
                      widget.onDelete != null)
                    const SizedBox(height: 16),
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
                        const SizedBox(height: AppUi.sectionGap),
                        _DescriptionCard(description: item.description),
                        const SizedBox(height: AppUi.sectionGap),
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
                              const SizedBox(height: AppUi.sectionGap),
                              _DescriptionCard(description: item.description),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppUi.sectionGap),
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
      height: 92,
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
              width: 92,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                          color: cs.primary.withOpacity(0.16),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
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
              if (onSell != null && onEdit != null)
                const SizedBox(width: AppUi.tileGap),
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
            const SizedBox(height: AppUi.tileGap),
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
        if (onSell != null && onEdit != null)
          const SizedBox(width: AppUi.tileGap),
        if (onEdit != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Item'),
            ),
          ),
        if ((onSell != null || onEdit != null) && onDelete != null)
          const SizedBox(width: AppUi.tileGap),
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
    return AppSectionCard(
      title: 'Overview',
      subtitle: 'Core pricing, stock, and sourcing details',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Cost',
                  sensitiveText: item.costPrice.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'MRP',
                  valueText: item.sellingPrice.toStringAsFixed(0),
                  icon: Icons.sell_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Margin',
                  sensitiveText: marginAmount.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.trending_up_rounded,
                  valueColor: marginAmount >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Markup',
                  sensitiveText: marginPercent,
                  isSensitive: true,
                  icon: Icons.percent_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Stock',
                  valueText: '${item.quantity}',
                  icon: Icons.inventory_2_outlined,
                  valueColor: stockColor,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Images',
                  valueText: '${item.imagePaths.length}',
                  icon: Icons.image_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppLineItem(
            label: 'Supplier',
            value: item.supplier.trim().isEmpty ? 'Not provided' : item.supplier,
          ),
          const SizedBox(height: 8),
          AppLineItem(label: 'Created', value: formattedCreatedAt),
          const SizedBox(height: 8),
          AppLineItem(label: 'Updated', value: formattedUpdatedAt),
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
    return AppSectionCard(
      title: 'Description',
      subtitle: 'Product notes and descriptive context',
      child: Text(
        description.trim().isEmpty ? 'No description provided.' : description,
        style: TextStyle(
          fontSize: 14.25,
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
    return AppSectionCard(
      title: 'Warranty breakdown',
      subtitle: 'Coverage by component or part',
      child: warranties.isEmpty
          ? Text(
              'No warranty added.',
              style: TextStyle(
                fontSize: 14.25,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: warranties.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
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
                              fontSize: 13.4,
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