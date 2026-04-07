import 'package:flutter/material.dart';
import 'package:invenman/components/sensitive_value_text.dart';
import 'package:invenman/models/sale_record.dart';

class SaleCard extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;
  final VoidCallback? onTap;

  const SaleCard({
    super.key,
    required this.sale,
    required this.formattedDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 820;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: compact
              ? _SaleCardCompact(
                  sale: sale,
                  formattedDate: formattedDate,
                )
              : _SaleCardWide(
                  sale: sale,
                  formattedDate: formattedDate,
                ),
        ),
      ),
    );
  }
}

class _SaleCardWide extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;

  const _SaleCardWide({
    required this.sale,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitColor = sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchase details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Text(
                            sale.itemName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            '(${sale.category})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _DetailLine(
                                  label: 'Cost',
                                  sensitiveValue: sale.costPrice.toStringAsFixed(0),
                                  isSensitive: true,
                                ),
                                const SizedBox(height: 8),
                                _DetailLine(
                                  label: 'MRP',
                                  value: sale.sellPrice.toStringAsFixed(0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _DetailLine(
                                  label: 'Qty',
                                  value: '${sale.quantitySold}',
                                ),
                                const SizedBox(height: 8),
                                _DetailLine(
                                  label: 'Profit',
                                  sensitiveValue: sale.profit.toStringAsFixed(0),
                                  isSensitive: true,
                                  valueColor: profitColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DetailLine(
                        label: 'Name',
                        value: (sale.customerName ?? '').trim().isEmpty
                            ? 'Not provided'
                            : sale.customerName!,
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Phone',
                        value: (sale.customerPhone ?? '').trim().isEmpty
                            ? 'Not provided'
                            : sale.customerPhone!,
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Address',
                        value: (sale.customerAddress ?? '').trim().isEmpty
                            ? 'Not provided'
                            : sale.customerAddress!,
                        multiline: true,
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Payment',
                        value: sale.isInstallment
                            ? 'Installment (${sale.installmentMonths ?? '-'} mo)'
                            : 'Direct',
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Date',
                        value: formattedDate,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (sale.warranties.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Warranty Remaining:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: sale.warranties.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${entry.key}: ${_remainingWarrantyLabel(sale.soldAt, entry.value)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SaleCardCompact extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;

  const _SaleCardCompact({
    required this.sale,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitColor = sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.75),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    sale.itemName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                  ),
                  Text(
                    '(${sale.category})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailLine(
                label: 'Cost',
                sensitiveValue: sale.costPrice.toStringAsFixed(0),
                isSensitive: true,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'MRP',
                value: sale.sellPrice.toStringAsFixed(0),
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Qty',
                value: '${sale.quantitySold}',
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Profit',
                sensitiveValue: sale.profit.toStringAsFixed(0),
                isSensitive: true,
                valueColor: profitColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.75),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _DetailLine(
                label: 'Name',
                value: (sale.customerName ?? '').trim().isEmpty
                    ? 'Not provided'
                    : sale.customerName!,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Phone',
                value: (sale.customerPhone ?? '').trim().isEmpty
                    ? 'Not provided'
                    : sale.customerPhone!,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Address',
                value: (sale.customerAddress ?? '').trim().isEmpty
                    ? 'Not provided'
                    : sale.customerAddress!,
                multiline: true,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Payment',
                value: sale.isInstallment
                    ? 'Installment (${sale.installmentMonths ?? '-'} mo)'
                    : 'Direct',
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Date',
                value: formattedDate,
              ),
            ],
          ),
        ),
        if (sale.warranties.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Warranty Remaining',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sale.warranties.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${entry.key}: ${_remainingWarrantyLabel(sale.soldAt, entry.value)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String? value;
  final String? sensitiveValue;
  final bool isSensitive;
  final bool multiline;
  final Color? valueColor;

  const _DetailLine({
    required this.label,
    this.value,
    this.sensitiveValue,
    this.isSensitive = false,
    this.multiline = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: isSensitive
              ? SensitiveValueText(
                  visibleText: sensitiveValue ?? '',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: multiline ? 10 : 1,
                )
              : Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w600,
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