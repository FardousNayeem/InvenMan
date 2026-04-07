import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/theme/app_ui.dart';

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
            expandedHeight: 360,
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
                sale.itemName,
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
                              label: sale.category,
                            ),
                            AppHeroPill(
                              icon: sale.isInstallment
                                  ? Icons.calendar_month_rounded
                                  : Icons.payments_rounded,
                              label: _paymentLabel,
                            ),
                            AppHeroPill(
                              icon: Icons.trending_up_rounded,
                              label: 'Profit',
                              accentColor: profitColor,
                            ),
                            AppHeroPill(
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
              padding: const EdgeInsets.fromLTRB(
                AppUi.pageHPadding,
                18,
                AppUi.pageHPadding,
                AppUi.pageBottomPadding,
              ),
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
                    const SizedBox(height: 16),
                  ],
                  if (isCompact)
                    Column(
                      children: [
                        _SaleOverviewCard(
                          sale: sale,
                          formattedDate: _formatDate(sale.soldAt),
                          profitColor: profitColor,
                        ),
                        const SizedBox(height: AppUi.sectionGap),
                        _CustomerCard(sale: sale),
                        const SizedBox(height: AppUi.sectionGap),
                        _PaymentCard(sale: sale),
                        const SizedBox(height: AppUi.sectionGap),
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
                              const SizedBox(height: AppUi.sectionGap),
                              _SaleWarrantyCard(sale: sale),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppUi.sectionGap),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _CustomerCard(sale: sale),
                              const SizedBox(height: AppUi.sectionGap),
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
    return AppSectionCard(
      title: 'Purchase details',
      subtitle: 'Transaction pricing, quantity, and outcome',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Cost',
                  sensitiveText: sale.costPrice.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'MRP',
                  valueText: sale.sellPrice.toStringAsFixed(0),
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
                  label: 'Qty',
                  valueText: '${sale.quantitySold}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
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
          AppLineItem(label: 'Date', value: formattedDate),
          const SizedBox(height: 8),
          AppLineItem(label: 'Category', value: sale.category),
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
    return AppSectionCard(
      title: 'Customer details',
      subtitle: 'Buyer information captured at the time of sale',
      child: Column(
        children: [
          AppLineItem(
            label: 'Name',
            value: (sale.customerName ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerName!,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Phone',
            value: (sale.customerPhone ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerPhone!,
          ),
          const SizedBox(height: 8),
          AppLineItem(
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
    return AppSectionCard(
      title: 'Payment details',
      subtitle: 'Settlement mode and installment terms',
      child: Column(
        children: [
          AppLineItem(
            label: 'Type',
            value: sale.isInstallment ? 'Installment' : 'Direct',
          ),
          const SizedBox(height: 8),
          AppLineItem(
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
    return AppSectionCard(
      title: 'Warranty remaining',
      subtitle: 'Current coverage left from the purchase date',
      child: sale.warranties.isEmpty
          ? Text(
              'No warranty included.',
              style: TextStyle(
                fontSize: 14.25,
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
                              fontSize: 13.4,
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