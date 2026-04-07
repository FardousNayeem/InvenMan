import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/models/sale_record.dart';

class SaleDetailsScreen extends StatefulWidget {
  final SaleRecord sale;

  const SaleDetailsScreen({
    super.key,
    required this.sale,
  });

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  int _selectedImageIndex = 0;

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 860;

    final profitColor = sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
    final selectedImagePath =
        sale.imagePaths.isNotEmpty ? sale.imagePaths[_selectedImageIndex] : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 18, end: 20),
              title: Text(
                sale.itemName,
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
                        icon: Icons.receipt_long_rounded,
                        label: sale.category,
                      ),
                    )
                  else
                    _HeroPlaceholder(
                      icon: Icons.receipt_long_rounded,
                      label: sale.category,
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.5),
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
                          label: sale.category,
                        ),
                        _TopPill(
                          icon: Icons.point_of_sale_rounded,
                          label: sale.paymentType == 'installment'
                              ? 'Installment'
                              : 'Direct',
                        ),
                        _TopPill(
                          icon: Icons.trending_up_rounded,
                          label: 'Profit ${sale.profit.toStringAsFixed(0)}',
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
                  if (sale.imagePaths.length > 1) ...[
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sale.imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          final path = sale.imagePaths[index];
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
                        _SaleOverviewCard(
                          sale: sale,
                          formattedDate: _formatDate(sale.soldAt),
                          profitColor: profitColor,
                        ),
                        const SizedBox(height: 14),
                        _CustomerCard(
                          sale: sale,
                          formattedDate: _formatDate(sale.soldAt),
                        ),
                        const SizedBox(height: 14),
                        _SaleWarrantyCard(
                          sale: sale,
                        ),
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
                              _SaleOverviewCard(
                                sale: sale,
                                formattedDate: _formatDate(sale.soldAt),
                                profitColor: profitColor,
                              ),
                              const SizedBox(height: 14),
                              _SaleWarrantyCard(sale: sale),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 4,
                          child: _CustomerCard(
                            sale: sale,
                            formattedDate: _formatDate(sale.soldAt),
                          ),
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

class _SaleOverviewCard extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;
  final Color profitColor;

  const _SaleOverviewCard({
    required this.sale,
    required this.formattedDate,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Purchase details',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Cost',
                  value: sale.costPrice.toStringAsFixed(0),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'MRP',
                  value: sale.sellPrice.toStringAsFixed(0),
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
                  label: 'Qty',
                  value: '${sale.quantitySold}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Profit',
                  value: sale.profit.toStringAsFixed(0),
                  icon: Icons.trending_up_rounded,
                  valueColor: profitColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LineItem(
            label: 'Payment',
            value: sale.isInstallment
                ? 'Installment (${sale.installmentMonths ?? '-'} months)'
                : 'Direct',
          ),
          const SizedBox(height: 8),
          _LineItem(label: 'Date', value: formattedDate),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;

  const _CustomerCard({
    required this.sale,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Customer details',
      child: Column(
        children: [
          _LineItem(
            label: 'Name',
            value: (sale.customerName ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerName!,
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Phone',
            value: (sale.customerPhone ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerPhone!,
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Address',
            value: (sale.customerAddress ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerAddress!,
          ),
        ],
      ),
    );
  }
}

class _SaleWarrantyCard extends StatelessWidget {
  final SaleRecord sale;

  const _SaleWarrantyCard({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Warranty remaining',
      child: sale.warranties.isEmpty
          ? Text(
              'No warranty included.',
              style: TextStyle(
                fontSize: 14.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: sale.warranties.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${entry.key}: ${_remainingWarrantyLabel(sale.soldAt, entry.value)}',
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

String _remainingWarrantyLabel(DateTime soldAt, int months) {
  final now = DateTime.now();
  final expiry = _addMonths(soldAt, months);

  if (!expiry.isAfter(now)) {
    return 'Expired';
  }

  final diff = _differenceInMonthsAndDays(now, expiry);

  if (diff.$1 > 0 && diff.$2 > 0) {
    return '${diff.$1} mo ${diff.$2} day left';
  }
  if (diff.$1 > 0) {
    return '${diff.$1} mo left';
  }
  if (diff.$2 > 0) {
    return '${diff.$2} day left';
  }
  return 'Less than 1 day left';
}

(int, int) _differenceInMonthsAndDays(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + (to.month - from.month);
  var candidate = _addMonths(from, months);

  if (candidate.isAfter(to)) {
    months--;
    candidate = _addMonths(from, months);
  }

  final days = to.difference(candidate).inDays;
  return (months, days);
}

DateTime _addMonths(DateTime date, int monthsToAdd) {
  final totalMonths = (date.year * 12 + date.month - 1) + monthsToAdd;
  final newYear = totalMonths ~/ 12;
  final newMonth = (totalMonths % 12) + 1;

  final lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
  final newDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

  return DateTime(
    newYear,
    newMonth,
    newDay,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}