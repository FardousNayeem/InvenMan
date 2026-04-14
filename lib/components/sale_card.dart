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

  Color _profitColor() {
    return sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
  }

  Color _paymentColor() {
    return sale.isInstallment ? Colors.deepPurple.shade700 : Colors.blue.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 820;

    return _InteractiveCardShell(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _Panel(
                  title: 'Purchase Details',
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
                          _InlineBadge(
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
              const SizedBox(width: 16),
              Expanded(
                child: _Panel(
                  title: 'Customer Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        valueColor: paymentColor,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          title: 'Purchase Details',
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
                  _InlineBadge(
                    label: sale.category,
                    background: cs.secondaryContainer,
                    foreground: cs.onSecondaryContainer,
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
        const SizedBox(height: 12),
        _Panel(
          title: 'Customer Details',
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                valueColor: paymentColor,
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

class _InteractiveCardShell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _InteractiveCardShell({
    required this.child,
    this.onTap,
  });

  @override
  State<_InteractiveCardShell> createState() => _InteractiveCardShellState();
}

class _InteractiveCardShellState extends State<_InteractiveCardShell> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scale = _pressed ? 0.992 : 1.0;
    final borderColor = _hovered ? cs.primary.withOpacity(0.22) : cs.outlineVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: scale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    blurRadius: _hovered ? 22 : 18,
                    offset: Offset(0, _hovered ? 10 : 8),
                    color: Colors.black.withOpacity(_hovered ? 0.07 : 0.05),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;
  final bool compact;

  const _Panel({
    required this.title,
    required this.child,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.all(compact ? 14 : 15),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.78),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.45,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _InlineBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.2,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
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
          width: 72,
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
                    fontSize: 13.4,
                    height: 1.4,
                    color: valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: multiline ? 10 : 1,
                )
              : Text(
                  value ?? '',
                  style: TextStyle(
                    fontSize: 13.4,
                    height: 1.4,
                    color: valueColor ?? cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
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
    final color = expired ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: expired
            ? Colors.red.withOpacity(0.10)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
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