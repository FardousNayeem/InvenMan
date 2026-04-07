import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/components/sensitive_value_text.dart';
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

  SaleRecord get sale => widget.sale;

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  String get _paymentLabel {
    if (sale.isInstallment) {
      return 'Installment (${sale.installmentMonths ?? '-'} months)';
    }
    return 'Direct';
  }

  Color _profitColor() {
    return sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
  }

  int get _safeSelectedIndex {
    if (sale.imagePaths.isEmpty) return 0;
    return math.min(_selectedImageIndex, sale.imagePaths.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 900;
    final selectedImagePath =
        sale.imagePaths.isNotEmpty ? sale.imagePaths[_safeSelectedIndex] : null;
    final profitColor = _profitColor();

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
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 20,
                bottom: 18,
              ),
              title: Text(
                sale.itemName,
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
                              label: sale.category,
                            ),
                            _TopPill(
                              icon: sale.isInstallment
                                  ? Icons.calendar_month_rounded
                                  : Icons.payments_rounded,
                              label: _paymentLabel,
                            ),
                            _TopPill(
                              icon: Icons.trending_up_rounded,
                              label: 'Profit',
                              accentColor: profitColor,
                            ),
                            _TopPill(
                              icon: Icons.schedule_rounded,
                              label: _formatDate(sale.soldAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          (sale.customerName ?? '').trim().isNotEmpty
                              ? 'Sold to ${sale.customerName}'
                              : 'Transaction details and warranty coverage for this sale.',
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
                  if (sale.imagePaths.length > 1) ...[
                    _ThumbnailRail(
                      imagePaths: sale.imagePaths,
                      selectedIndex: _safeSelectedIndex,
                      onSelected: (index) {
                        setState(() {
                          _selectedImageIndex = index;
                        });
                      },
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
                        _CustomerCard(sale: sale),
                        const SizedBox(height: 14),
                        _PaymentCard(sale: sale),
                        const SizedBox(height: 14),
                        _SaleWarrantyCard(sale: sale),
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
                          child: Column(
                            children: [
                              _CustomerCard(sale: sale),
                              const SizedBox(height: 14),
                              _PaymentCard(sale: sale),
                            ],
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
      padding: const EdgeInsets.all(8),
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
      subtitle: 'Transaction pricing, quantity, and outcome',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Cost',
                  sensitiveText: sale.costPrice.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'MRP',
                  valueText: sale.sellPrice.toStringAsFixed(0),
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
                  valueText: '${sale.quantitySold}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Profit',
                  sensitiveText: sale.profit.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.trending_up_rounded,
                  valueColor: profitColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LineItem(label: 'Date', value: formattedDate),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Category',
            value: sale.category,
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final SaleRecord sale;

  const _CustomerCard({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Customer details',
      subtitle: 'Buyer information captured at the time of sale',
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

class _PaymentCard extends StatelessWidget {
  final SaleRecord sale;

  const _PaymentCard({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Payment details',
      subtitle: 'Settlement mode and installment terms',
      child: Column(
        children: [
          _LineItem(
            label: 'Type',
            value: sale.isInstallment ? 'Installment' : 'Direct',
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Duration',
            value: sale.isInstallment
                ? '${sale.installmentMonths ?? '-'} month(s)'
                : 'Not applicable',
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
      subtitle: 'Current coverage left from the purchase date',
      child: sale.warranties.isEmpty
          ? Text(
              'No warranty included.',
              style: TextStyle(
                fontSize: 14.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: sale.warranties.entries.map((entry) {
                final remaining = _remainingWarrantyLabel(sale.soldAt, entry.value);
                final expired = remaining == 'Expired';

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
                        Icon(
                          expired ? Icons.gpp_bad_outlined : Icons.verified_outlined,
                          size: 18,
                          color: expired ? Colors.red.shade700 : null,
                        ),
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
                          remaining,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: expired
                                ? Colors.red.shade700
                                : Theme.of(context).colorScheme.onSurfaceVariant,
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