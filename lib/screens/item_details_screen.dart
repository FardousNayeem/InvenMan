import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/models/item.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item item;

  const ItemDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int _selectedImageIndex = 0;

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 820;

    final stockColor = item.quantity <= 0
        ? Colors.red.shade700
        : item.quantity <= 3
            ? Colors.orange.shade700
            : Colors.green.shade700;

    final selectedImagePath =
        item.imagePaths.isNotEmpty ? item.imagePaths[_selectedImageIndex] : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: cs.surface,
            surfaceTintColor: cs.surfaceTint,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 18, end: 20),
              title: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
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
                          Colors.black.withOpacity(0.48),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 92,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _TopPill(
                          icon: Icons.category_rounded,
                          label: item.category,
                        ),
                        _TopPill(
                          icon: Icons.inventory_2_outlined,
                          label: 'Stock ${item.quantity}',
                        ),
                        _TopPill(
                          icon: Icons.sell_outlined,
                          label: 'MRP ${item.sellingPrice.toStringAsFixed(0)}',
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
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: item.imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final path = item.imagePaths[index];
                          final isSelected = _selectedImageIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 92,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? cs.primary : cs.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
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
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (isCompact)
                    Column(
                      children: [
                        _OverviewCard(
                          item: item,
                          stockColor: stockColor,
                          formattedCreatedAt: _formatDate(item.createdAt),
                          formattedUpdatedAt: _formatDate(item.updatedAt),
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
                          flex: 5,
                          child: Column(
                            children: [
                              _OverviewCard(
                                item: item,
                                stockColor: stockColor,
                                formattedCreatedAt: _formatDate(item.createdAt),
                                formattedUpdatedAt: _formatDate(item.updatedAt),
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
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: cs.onSurfaceVariant),
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

  const _TopPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
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

class _OverviewCard extends StatelessWidget {
  final Item item;
  final Color stockColor;
  final String formattedCreatedAt;
  final String formattedUpdatedAt;

  const _OverviewCard({
    required this.item,
    required this.stockColor,
    required this.formattedCreatedAt,
    required this.formattedUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _GlassSection(
      title: 'Overview',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Cost',
                  value: item.costPrice.toStringAsFixed(0),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'MRP',
                  value: item.sellingPrice.toStringAsFixed(0),
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
                  label: 'Stock',
                  value: '${item.quantity}',
                  icon: Icons.inventory_2_outlined,
                  valueColor: stockColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Images',
                  value: '${item.imagePaths.length}',
                  icon: Icons.image_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LineItem(label: 'Supplier', value: item.supplier.trim().isEmpty ? 'Not provided' : item.supplier),
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
      child: Text(
        description.trim().isEmpty ? 'No description provided.' : description,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.55,
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
      child: warranties.isEmpty
          ? Text(
              'No warranty added.',
              style: TextStyle(
                fontSize: 14.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: warranties.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value} mo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
  final Widget child;

  const _GlassSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
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
                Text(
                  value,
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
          width: 78,
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