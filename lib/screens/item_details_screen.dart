import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/models/item.dart';
import 'package:invenman/services/db_services.dart';
import 'package:invenman/theme/app_ui.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;
  final Future<void> Function(Item item)? onEdit;
  final Future<void> Function(Item item)? onSell;
  final Future<void> Function(Item item)? onDelete;

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
  late Item _item;
  int _selectedImageIndex = 0;
  bool _isRefreshingItem = false;

  Item get item => _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  Future<void> _reloadItemFromDb() async {
    if (_item.id == null || _isRefreshingItem) return;

    _isRefreshingItem = true;
    try {
      final freshItem = await DBHelper.fetchItemById(_item.id!);
      if (!mounted || freshItem == null) return;

      setState(() {
        _item = freshItem;
        if (_item.imagePaths.isEmpty) {
          _selectedImageIndex = 0;
        } else if (_selectedImageIndex >= _item.imagePaths.length) {
          _selectedImageIndex = _item.imagePaths.length - 1;
        }
      });
    } finally {
      _isRefreshingItem = false;
    }
  }

  Future<void> _handleEdit() async {
    if (widget.onEdit == null) return;
    await widget.onEdit!.call(item);
    await _reloadItemFromDb();
  }

  Future<void> _handleSell() async {
    if (widget.onSell == null) return;
    await widget.onSell!.call(item);
    await _reloadItemFromDb();
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete == null) return;
    await widget.onDelete!.call(item);
  }

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
    if (_selectedImageIndex < 0) return 0;
    if (_selectedImageIndex >= item.imagePaths.length) {
      return item.imagePaths.length - 1;
    }
    return _selectedImageIndex;
  }

  Future<void> _openImageViewer([int? initialIndex]) async {
    if (item.imagePaths.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(
          imagePaths: item.imagePaths,
          initialIndex: initialIndex ?? _safeSelectedIndex,
        ),
      ),
    );
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
            expandedHeight: 390,
            backgroundColor: cs.surface,
            surfaceTintColor: cs.surfaceTint,
            leading: AppHeaderIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
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
                  _HeroImageArea(
                    imagePath: selectedImagePath,
                    category: item.category,
                    onTap: selectedImagePath == null
                        ? null
                        : () => _openImageViewer(_safeSelectedIndex),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.02),
                            Colors.black.withOpacity(0.48),
                          ],
                        ),
                      ),
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
                  _TopSection(
                    imagePaths: item.imagePaths,
                    selectedIndex: _safeSelectedIndex,
                    onImageSelected: (index) {
                      setState(() {
                        _selectedImageIndex = index;
                      });
                    },
                    category: item.category,
                    brand: item.brand,
                    colors: item.colors,
                    supplier: item.supplier,
                    stockLabel: _stockLabel,
                    stockColor: stockColor,
                    mrp: item.sellingPrice.toStringAsFixed(0),
                    canSell: item.quantity > 0,
                    onSell: widget.onSell == null ? null : _handleSell,
                    onEdit: widget.onEdit == null ? null : _handleEdit,
                    onDelete: widget.onDelete == null ? null : _handleDelete,
                  ),
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
                        const SizedBox(height: AppUi.sectionGap),
                        _WarrantyCard(
                          warranties: item.warranties,
                          minHeight: 260,
                        ),
                        const SizedBox(height: AppUi.sectionGap),
                        _DescriptionCard(
                          description: item.description,
                          minHeight: 220,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _OverviewCard(
                                  item: item,
                                  stockColor: stockColor,
                                  formattedCreatedAt: _formatDate(item.createdAt),
                                  formattedUpdatedAt: _formatDate(item.updatedAt),
                                  marginAmount: _marginAmount,
                                  marginPercent: _marginPercent,
                                ),
                              ),
                              const SizedBox(width: AppUi.sectionGap),
                              Expanded(
                                flex: 4,
                                child: _WarrantyCard(
                                  warranties: item.warranties,
                                  minHeight: double.infinity,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppUi.sectionGap),
                        _DescriptionCard(
                          description: item.description,
                          minHeight: 220,
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

class _HeroImageArea extends StatelessWidget {
  final String? imagePath;
  final String category;
  final VoidCallback? onTap;

  const _HeroImageArea({
    required this.imagePath,
    required this.category,
    this.onTap,
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
      child: imagePath == null
          ? _HeroPlaceholder(
              icon: Icons.inventory_2_rounded,
              label: category,
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 34),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.file(
                        File(imagePath!),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => _HeroPlaceholder(
                          icon: Icons.inventory_2_rounded,
                          label: category,
                        ),
                      ),
                    ),
                  ),
                ),
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

    return Center(
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
    );
  }
}

class _TopSection extends StatelessWidget {
  final List<String> imagePaths;
  final int selectedIndex;
  final ValueChanged<int> onImageSelected;
  final String category;
  final String brand;
  final List<String> colors;
  final String supplier;
  final String stockLabel;
  final Color stockColor;
  final String mrp;
  final bool canSell;
  final Future<void> Function()? onSell;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

  const _TopSection({
    required this.imagePaths,
    required this.selectedIndex,
    required this.onImageSelected,
    required this.category,
    required this.brand,
    required this.colors,
    required this.supplier,
    required this.stockLabel,
    required this.stockColor,
    required this.mrp,
    required this.canSell,
    this.onSell,
    this.onEdit,
    this.onDelete,
  });

  String get _brandText => brand.trim().isEmpty ? 'Unbranded' : brand.trim();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imagePaths.isNotEmpty)
          _ThumbnailRail(
            imagePaths: imagePaths,
            selectedIndex: selectedIndex,
            onSelected: onImageSelected,
          ),
        if (imagePaths.isNotEmpty) const SizedBox(height: 16),
        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppHeroPill(
                    icon: Icons.category_rounded,
                    label: category,
                  ),
                  AppHeroPill(
                    icon: Icons.workspace_premium_outlined,
                    label: _brandText,
                  ),
                  if (colors.isNotEmpty)
                    AppHeroPill(
                      icon: Icons.palette_outlined,
                      label: colors.join(', '),
                    ),
                  AppHeroPill(
                    icon: Icons.inventory_2_outlined,
                    label: stockLabel,
                    accentColor: stockColor,
                  ),
                  AppHeroPill(
                    icon: Icons.sell_outlined,
                    label: 'MRP $mrp',
                  ),
                  if (supplier.trim().isNotEmpty)
                    AppHeroPill(
                      icon: Icons.local_shipping_outlined,
                      label: supplier,
                    ),
                ],
              ),
              if (onSell != null || onEdit != null || onDelete != null) ...[
                const SizedBox(height: 14),
                _ActionStrip(
                  canSell: canSell,
                  onSell: onSell,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ],
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppHeroPill(
                      icon: Icons.category_rounded,
                      label: category,
                    ),
                    AppHeroPill(
                      icon: Icons.workspace_premium_outlined,
                      label: _brandText,
                    ),
                    if (colors.isNotEmpty)
                      AppHeroPill(
                        icon: Icons.palette_outlined,
                        label: colors.join(', '),
                      ),
                    AppHeroPill(
                      icon: Icons.inventory_2_outlined,
                      label: stockLabel,
                      accentColor: stockColor,
                    ),
                    AppHeroPill(
                      icon: Icons.sell_outlined,
                      label: 'MRP $mrp',
                    ),
                    if (supplier.trim().isNotEmpty)
                      AppHeroPill(
                        icon: Icons.local_shipping_outlined,
                        label: supplier,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _ActionStrip(
                  canSell: canSell,
                  onSell: onSell,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
      ],
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
      height: 96,
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
              width: 96,
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
  final Future<void> Function()? onSell;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;

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
                    label: Text(canSell ? 'Sell' : 'Out of Stock'),
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

    return Align(
      alignment: Alignment.topRight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
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
      ),
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

  String get _brandText =>
      item.brand.trim().isEmpty ? 'Not provided' : item.brand.trim();

  String get _colorsText =>
      item.colors.isEmpty ? 'Not provided' : item.colors.join(', ');

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
          AppLineItem(label: 'Brand', value: _brandText),
          const SizedBox(height: 8),
          AppLineItem(label: 'Colors', value: _colorsText),
          const SizedBox(height: 8),
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
  final double minHeight;

  const _DescriptionCard({
    required this.description,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Description',
      subtitle: 'Product notes and descriptive context',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            description.trim().isEmpty ? 'No description provided.' : description,
            style: TextStyle(
              fontSize: 14.25,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  final Map<String, int> warranties;
  final double minHeight;

  const _WarrantyCard({
    required this.warranties,
    required this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Warranty Breakdown',
      subtitle: 'Coverage by component or part',
      child: SizedBox(
        height: minHeight.isFinite ? minHeight : null,
        child: warranties.isEmpty
            ? Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'No warranty added.',
                  style: TextStyle(
                    fontSize: 14.25,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Column(
                children: [
                  ...warranties.entries.map((entry) {
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
                  }),
                  if (minHeight.isFinite) const Spacer(),
                ],
              ),
      ),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _FullscreenImageViewer({
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
  }

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
  }

  void _goNext() {
    if (_currentIndex >= widget.imagePaths.length - 1) return;
    setState(() => _currentIndex++);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.imagePaths[_currentIndex];
    final canGoLeft = _currentIndex > 0;
    final canGoRight = _currentIndex < widget.imagePaths.length - 1;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.96),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white70,
                      size: 72,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed: canGoLeft ? _goPrevious : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withOpacity(0.06),
                    disabledForegroundColor: Colors.white24,
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed: canGoRight ? _goNext : null,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withOpacity(0.06),
                    disabledForegroundColor: Colors.white24,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imagePaths.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}