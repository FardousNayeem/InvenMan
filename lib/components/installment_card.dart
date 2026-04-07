import 'package:flutter/material.dart';
import 'package:invenman/models/installment_plan.dart';

class InstallmentCard extends StatelessWidget {
  final InstallmentPlan plan;
  final String thisMonthStatus;
  final String formattedStartDate;
  final String formattedNextDueDate;
  final VoidCallback? onTap;

  const InstallmentCard({
    super.key,
    required this.plan,
    required this.thisMonthStatus,
    required this.formattedStartDate,
    required this.formattedNextDueDate,
    this.onTap,
  });

  Color _planStatusColor() {
    switch (plan.status) {
      case 'completed':
        return Colors.green.shade700;
      case 'overdue':
        return Colors.red.shade700;
      case 'active':
      default:
        return Colors.blue.shade700;
    }
  }

  String _planStatusLabel() {
    switch (plan.status) {
      case 'completed':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      case 'active':
      default:
        return 'Active';
    }
  }

  Color _currentMonthColor() {
    switch (thisMonthStatus) {
      case 'Paid':
        return Colors.green.shade700;
      case 'Partial':
        return Colors.orange.shade700;
      case 'Overdue':
        return Colors.red.shade700;
      case 'Due':
        return Colors.blue.shade700;
      case 'Not due':
      default:
        return Colors.grey.shade700;
    }
  }

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
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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
          child: compact ? _CompactCard(plan: plan, thisMonthStatus: thisMonthStatus, formattedStartDate: formattedStartDate, formattedNextDueDate: formattedNextDueDate, planStatusColor: _planStatusColor(), planStatusLabel: _planStatusLabel(), currentMonthColor: _currentMonthColor()) : _WideCard(plan: plan, thisMonthStatus: thisMonthStatus, formattedStartDate: formattedStartDate, formattedNextDueDate: formattedNextDueDate, planStatusColor: _planStatusColor(), planStatusLabel: _planStatusLabel(), currentMonthColor: _currentMonthColor()),
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final InstallmentPlan plan;
  final String thisMonthStatus;
  final String formattedStartDate;
  final String formattedNextDueDate;
  final Color planStatusColor;
  final String planStatusLabel;
  final Color currentMonthColor;

  const _WideCard({
    required this.plan,
    required this.thisMonthStatus,
    required this.formattedStartDate,
    required this.formattedNextDueDate,
    required this.planStatusColor,
    required this.planStatusLabel,
    required this.currentMonthColor,
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
                        'Installment details',
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
                            plan.itemName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            '(${plan.category})',
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
                                  label: 'Monthly',
                                  value: plan.monthlyAmount.toStringAsFixed(2),
                                ),
                                const SizedBox(height: 8),
                                _DetailLine(
                                  label: 'Balance',
                                  value: plan.remainingBalance.toStringAsFixed(2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _DetailLine(
                                  label: 'Progress',
                                  value: '${plan.paidMonths}/${plan.durationMonths} paid',
                                ),
                                const SizedBox(height: 8),
                                _DetailLine(
                                  label: 'Started',
                                  value: formattedStartDate,
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
                        value: (plan.customerName ?? '').trim().isEmpty
                            ? 'Not provided'
                            : plan.customerName!,
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Phone',
                        value: (plan.customerPhone ?? '').trim().isEmpty
                            ? 'Not provided'
                            : plan.customerPhone!,
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Address',
                        value: (plan.customerAddress ?? '').trim().isEmpty
                            ? 'Not provided'
                            : plan.customerAddress!,
                        multiline: true,
                      ),
                      const SizedBox(height: 8),
                      _DetailLine(
                        label: 'Next due',
                        value: formattedNextDueDate,
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
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatusChip(
              label: 'This month: $thisMonthStatus',
              color: currentMonthColor,
            ),
            _StatusChip(
              label: 'Plan: $planStatusLabel',
              color: planStatusColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactCard extends StatelessWidget {
  final InstallmentPlan plan;
  final String thisMonthStatus;
  final String formattedStartDate;
  final String formattedNextDueDate;
  final Color planStatusColor;
  final String planStatusLabel;
  final Color currentMonthColor;

  const _CompactCard({
    required this.plan,
    required this.thisMonthStatus,
    required this.formattedStartDate,
    required this.formattedNextDueDate,
    required this.planStatusColor,
    required this.planStatusLabel,
    required this.currentMonthColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                'Installment details',
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
                    plan.itemName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                  ),
                  Text(
                    '(${plan.category})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailLine(
                label: 'Monthly',
                value: plan.monthlyAmount.toStringAsFixed(2),
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Balance',
                value: plan.remainingBalance.toStringAsFixed(2),
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Progress',
                value: '${plan.paidMonths}/${plan.durationMonths} paid',
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Started',
                value: formattedStartDate,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Next due',
                value: formattedNextDueDate,
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
                value: (plan.customerName ?? '').trim().isEmpty
                    ? 'Not provided'
                    : plan.customerName!,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Phone',
                value: (plan.customerPhone ?? '').trim().isEmpty
                    ? 'Not provided'
                    : plan.customerPhone!,
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Address',
                value: (plan.customerAddress ?? '').trim().isEmpty
                    ? 'Not provided'
                    : plan.customerAddress!,
                multiline: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: 'This month: $thisMonthStatus',
              color: currentMonthColor,
            ),
            _StatusChip(
              label: 'Plan: $planStatusLabel',
              color: planStatusColor,
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _DetailLine({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
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