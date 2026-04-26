import 'package:flutter/material.dart';
import 'package:invenman/models/sale_record.dart';

import 'package:invenman/components/common/card_panel.dart';
import 'package:invenman/components/common/detail_line.dart';
import 'package:invenman/components/common/inline_badge.dart';
import 'package:invenman/components/common/interactive_card_shell.dart';
import 'package:invenman/components/common/status_pill.dart';


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

  Color _profitColor() {
    return sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
  }

  Color _paymentColor() {
    return sale.isInstallment ? Colors.deepPurple.shade700 : Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 820;

    return InteractiveCardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: compact
            ? _SaleCardCompact(
                sale: sale,
                formattedDate: formattedDate,
                profitColor: _profitColor(),
                paymentColor: _paymentColor(),
              )
            : _SaleCardWide(
                sale: sale,
                formattedDate: formattedDate,
                profitColor: _profitColor(),
                paymentColor: _paymentColor(),
              ),
      ),
    );
  }
}

class _SaleCardWide extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;
  final Color profitColor;
  final Color paymentColor;

  const _SaleCardWide({
    required this.sale,
    required this.formattedDate,
    required this.profitColor,
    required this.paymentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final customerName = (sale.customerName ?? '').trim().isEmpty
        ? 'Not provided'
        : sale.customerName!;
    final customerPhone = (sale.customerPhone ?? '').trim().isEmpty
        ? 'Not provided'
        : sale.customerPhone!;
    final customerAddress = (sale.customerAddress ?? '').trim().isEmpty
        ? 'Not provided'
        : sale.customerAddress!;
    final paymentText = sale.isInstallment
        ? 'Installment (${sale.installmentMonths ?? '-'} mo)'
        : 'Direct';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: CardPanel(
                  title: 'Purchase details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          InlineBadge(
                            label: sale.category,
                            background: cs.secondaryContainer,
                            foreground: cs.onSecondaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DetailLine(
                                  label: 'Cost',
                                  sensitiveValue: sale.costPrice.toStringAsFixed(0),
                                  isSensitive: true,
                                ),
                                const SizedBox(height: 8),
                                DetailLine(
                                  label: 'Sold At',
                                  value: sale.sellPrice.toStringAsFixed(0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DetailLine(
                                  label: 'Qty',
                                  value: '${sale.quantitySold}',
                                ),
                                const SizedBox(height: 8),
                                DetailLine(
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
              const SizedBox(width: 16),
              Expanded(
                child: CardPanel(
                  title: 'Customer details',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DetailLine(
                              label: 'Name',
                              value: customerName,
                              labelMinWidth: 68,
                            ),
                            const SizedBox(height: 8),
                            DetailLine(
                              label: 'Phone',
                              value: customerPhone,
                              labelMinWidth: 68,
                            ),
                            const SizedBox(height: 8),
                            DetailLine(
                              label: 'Address',
                              value: customerAddress,
                              labelMinWidth: 68,
                              multiline: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DetailLine(
                              label: 'Payment',
                              value: paymentText,
                              valueColor: paymentColor,
                              labelMinWidth: 78,
                            ),
                            const SizedBox(height: 8),
                            DetailLine(
                              label: 'Docs',
                              value: '${sale.installmentImagePaths.length}',
                              labelMinWidth: 78,
                            ),
                            const SizedBox(height: 8),
                            DetailLine(
                              label: 'Date',
                              value: formattedDate,
                              labelMinWidth: 78,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
              label: sale.isInstallment ? 'Installment' : 'Direct',
              color: paymentColor,
            ),
            if (sale.soldColors.isNotEmpty)
              StatusPill(
                label: 'Colors: ${sale.soldColors.join(', ')}',
                color: Colors.indigo.shade700,
              ),
            if (sale.isInstallment && sale.installmentImagePaths.isNotEmpty)
              StatusPill(
                label: 'Docs: ${sale.installmentImagePaths.length}',
                color: Colors.teal.shade700,
              ),
          ],
        ),
        if (sale.warranties.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    final remaining =
                        _remainingWarrantyLabel(sale.soldAt, entry.value);
                    final expired = remaining == 'Expired';

                    return _WarrantyChip(
                      label: '${entry.key}: $remaining',
                      expired: expired,
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
  final Color profitColor;
  final Color paymentColor;

  const _SaleCardCompact({
    required this.sale,
    required this.formattedDate,
    required this.profitColor,
    required this.paymentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final customerName = (sale.customerName ?? '').trim().isEmpty
        ? 'Not provided'
        : sale.customerName!;
    final customerPhone = (sale.customerPhone ?? '').trim().isEmpty
        ? 'Not provided'
        : sale.customerPhone!;
    final customerAddress = (sale.customerAddress ?? '').trim().isEmpty
        ? 'Not provided'
        : sale.customerAddress!;
    final paymentText = sale.isInstallment
        ? 'Installment (${sale.installmentMonths ?? '-'} mo)'
        : 'Direct';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardPanel(
          title: 'Purchase details',
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  Text(
                    sale.itemName,
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                  ),
                  InlineBadge(
                    label: sale.category,
                    background: cs.secondaryContainer,
                    foreground: cs.onSecondaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DetailLine(
                label: 'Cost',
                sensitiveValue: sale.costPrice.toStringAsFixed(0),
                isSensitive: true,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Sold At',
                value: sale.sellPrice.toStringAsFixed(0),
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Qty',
                value: '${sale.quantitySold}',
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Profit',
                sensitiveValue: sale.profit.toStringAsFixed(0),
                isSensitive: true,
                valueColor: profitColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CardPanel(
          title: 'Customer details',
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailLine(
                label: 'Name',
                value: customerName,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Phone',
                value: customerPhone,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Address',
                value: customerAddress,
                multiline: true,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Payment',
                value: paymentText,
                valueColor: paymentColor,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Docs',
                value: '${sale.installmentImagePaths.length}',
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Date',
                value: formattedDate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill(
              label: sale.isInstallment ? 'Installment' : 'Direct',
              color: paymentColor,
            ),
            if (sale.soldColors.isNotEmpty)
              StatusPill(
                label: 'Colors: ${sale.soldColors.join(', ')}',
                color: Colors.indigo.shade700,
              ),
            if (sale.isInstallment && sale.installmentImagePaths.isNotEmpty)
              StatusPill(
                label: 'Docs: ${sale.installmentImagePaths.length}',
                color: Colors.teal.shade700,
              ),
          ],
        ),
        if (sale.warranties.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Warranty Remaining',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sale.warranties.entries.map((entry) {
              final remaining = _remainingWarrantyLabel(sale.soldAt, entry.value);
              final expired = remaining == 'Expired';

              return _WarrantyChip(
                label: '${entry.key}: $remaining',
                expired: expired,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _WarrantyChip extends StatelessWidget {
  final String label;
  final bool expired;

  const _WarrantyChip({
    required this.label,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final color = expired ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.3,
          fontWeight: FontWeight.w800,
          color: color,
        ),
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
  final newDay =
      date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

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