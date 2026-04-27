import 'package:flutter/material.dart';

import 'package:invenman/components/common/card_panel.dart';
import 'package:invenman/components/common/detail_line.dart';
import 'package:invenman/components/common/inline_badge.dart';
import 'package:invenman/components/common/interactive_card_shell.dart';
import 'package:invenman/components/common/responsive_card_utils.dart';
import 'package:invenman/components/common/status_pill.dart';
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

  Color _profitColor() {
    return sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
  }

  Color _paymentColor() {
    return sale.isInstallment
        ? Colors.deepPurple.shade700
        : Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveCardUtils.isCompact(context, breakpoint: 820);

    return InteractiveCardShell(
      onTap: onTap,
      borderRadius: compact ? 24 : 28,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
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
    final details = _SaleCardDetails.fromSale(
      sale: sale,
      formattedDate: formattedDate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PurchaseDetailsPanel(
                  sale: sale,
                  profitColor: profitColor,
                  compact: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CustomerDetailsPanel(
                  details: details,
                  paymentColor: paymentColor,
                  compact: false,
                ),
              ),
            ],
          ),
        ),
        _SaleStatusAndWarrantySection(
          sale: sale,
          paymentColor: paymentColor,
          compact: false,
        ),
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
    final details = _SaleCardDetails.fromSale(
      sale: sale,
      formattedDate: formattedDate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PurchaseDetailsPanel(
          sale: sale,
          profitColor: profitColor,
          compact: true,
        ),
        const SizedBox(height: 12),
        _CustomerDetailsPanel(
          details: details,
          paymentColor: paymentColor,
          compact: true,
        ),
        _SaleStatusAndWarrantySection(
          sale: sale,
          paymentColor: paymentColor,
          compact: true,
        ),
      ],
    );
  }
}

class _PurchaseDetailsPanel extends StatelessWidget {
  final SaleRecord sale;
  final Color profitColor;
  final bool compact;

  const _PurchaseDetailsPanel({
    required this.sale,
    required this.profitColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CardPanel(
      title: 'Purchase details',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SaleTitleRow(
            sale: sale,
            compact: compact,
          ),
          SizedBox(height: compact ? 12 : 14),
          if (compact)
            _PurchaseDetailsCompact(
              sale: sale,
              profitColor: profitColor,
            )
          else
            _PurchaseDetailsWide(
              sale: sale,
              profitColor: profitColor,
            ),
          if (sale.category.trim().isEmpty) ...[
            const SizedBox(height: 10),
            InlineBadge(
              label: 'Uncategorized',
              background: cs.secondaryContainer,
              foreground: cs.onSecondaryContainer,
            ),
          ],
        ],
      ),
    );
  }
}

class _SaleTitleRow extends StatelessWidget {
  final SaleRecord sale;
  final bool compact;

  const _SaleTitleRow({
    required this.sale,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final itemName = sale.itemName.trim().isEmpty ? 'Unnamed item' : sale.itemName;
    final category = sale.category.trim();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        Text(
          itemName,
          style: TextStyle(
            fontSize: compact ? 18.5 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? -0.35 : -0.4,
            height: 1.1,
          ),
        ),
        if (category.isNotEmpty)
          InlineBadge(
            label: category,
            background: cs.secondaryContainer,
            foreground: cs.onSecondaryContainer,
          ),
      ],
    );
  }
}

class _PurchaseDetailsWide extends StatelessWidget {
  final SaleRecord sale;
  final Color profitColor;

  const _PurchaseDetailsWide({
    required this.sale,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

class _PurchaseDetailsCompact extends StatelessWidget {
  final SaleRecord sale;
  final Color profitColor;

  const _PurchaseDetailsCompact({
    required this.sale,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _CustomerDetailsPanel extends StatelessWidget {
  final _SaleCardDetails details;
  final Color paymentColor;
  final bool compact;

  const _CustomerDetailsPanel({
    required this.details,
    required this.paymentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: 'Customer details',
      compact: compact,
      child: compact
          ? _CustomerDetailsCompact(
              details: details,
              paymentColor: paymentColor,
            )
          : _CustomerDetailsWide(
              details: details,
              paymentColor: paymentColor,
            ),
    );
  }
}

class _CustomerDetailsWide extends StatelessWidget {
  final _SaleCardDetails details;
  final Color paymentColor;

  const _CustomerDetailsWide({
    required this.details,
    required this.paymentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CustomerIdentityColumn(details: details),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _CustomerTransactionColumn(
            details: details,
            paymentColor: paymentColor,
          ),
        ),
      ],
    );
  }
}

class _CustomerDetailsCompact extends StatelessWidget {
  final _SaleCardDetails details;
  final Color paymentColor;

  const _CustomerDetailsCompact({
    required this.details,
    required this.paymentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CustomerIdentityColumn(details: details),
        const SizedBox(height: 8),
        _CustomerTransactionColumn(
          details: details,
          paymentColor: paymentColor,
        ),
      ],
    );
  }
}

class _CustomerIdentityColumn extends StatelessWidget {
  final _SaleCardDetails details;

  const _CustomerIdentityColumn({
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailLine(
          label: 'Name',
          value: details.customerName,
          labelMinWidth: 68,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Phone',
          value: details.customerPhone,
          labelMinWidth: 68,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Address',
          value: details.customerAddress,
          labelMinWidth: 68,
          multiline: true,
        ),
      ],
    );
  }
}

class _CustomerTransactionColumn extends StatelessWidget {
  final _SaleCardDetails details;
  final Color paymentColor;

  const _CustomerTransactionColumn({
    required this.details,
    required this.paymentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailLine(
          label: 'Payment',
          value: details.paymentText,
          valueColor: paymentColor,
          labelMinWidth: 78,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Docs',
          value: details.docsCount,
          labelMinWidth: 78,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Date',
          value: details.formattedDate,
          labelMinWidth: 78,
        ),
      ],
    );
  }
}

class _SaleStatusAndWarrantySection extends StatelessWidget {
  final SaleRecord sale;
  final Color paymentColor;
  final bool compact;

  const _SaleStatusAndWarrantySection({
    required this.sale,
    required this.paymentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: compact ? 12 : 16),
        ResponsiveChipWrap(
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
          SizedBox(height: compact ? 12 : 16),
          if (compact) ...[
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
            _WarrantyWrap(sale: sale),
          ] else
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
                  child: _WarrantyWrap(sale: sale),
                ),
              ],
            ),
        ],
      ],
    );
  }
}

class _WarrantyWrap extends StatelessWidget {
  final SaleRecord sale;

  const _WarrantyWrap({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveChipWrap(
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
        color: color.withValues(alpha:0.12),
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

class _SaleCardDetails {
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String paymentText;
  final String docsCount;
  final String formattedDate;

  const _SaleCardDetails({
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.paymentText,
    required this.docsCount,
    required this.formattedDate,
  });

  factory _SaleCardDetails.fromSale({
    required SaleRecord sale,
    required String formattedDate,
  }) {
    return _SaleCardDetails(
      customerName: _fallbackText(sale.customerName),
      customerPhone: _fallbackText(sale.customerPhone),
      customerAddress: _fallbackText(sale.customerAddress),
      paymentText: sale.isInstallment
          ? 'Installment (${sale.installmentMonths ?? '-'} mo)'
          : 'Direct',
      docsCount: '${sale.installmentImagePaths.length}',
      formattedDate: formattedDate,
    );
  }

  static String _fallbackText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Not provided' : trimmed;
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