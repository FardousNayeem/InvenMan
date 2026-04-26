import 'package:flutter/material.dart';
import 'package:invenman/models/installment_plan.dart';

import 'package:invenman/components/common/card_panel.dart';
import 'package:invenman/components/common/detail_line.dart';
import 'package:invenman/components/common/inline_badge.dart';
import 'package:invenman/components/common/interactive_card_shell.dart';


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

  String _money(double value) => value.toStringAsFixed(0);

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

  double _progressValue() {
    if (plan.durationMonths <= 0) return 0;
    if (plan.status == 'completed' || plan.remainingBalance <= 0.009) {
      return 1.0;
    }
    final value = plan.paidMonths / plan.durationMonths;
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 820;

    return InteractiveCardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: compact
            ? _CompactCard(
                plan: plan,
                thisMonthStatus: thisMonthStatus,
                formattedStartDate: formattedStartDate,
                formattedNextDueDate: formattedNextDueDate,
                planStatusColor: _planStatusColor(),
                planStatusLabel: _planStatusLabel(),
                currentMonthColor: _currentMonthColor(),
                progressValue: _progressValue(),
                money: _money,
              )
            : _WideCard(
                plan: plan,
                thisMonthStatus: thisMonthStatus,
                formattedStartDate: formattedStartDate,
                formattedNextDueDate: formattedNextDueDate,
                planStatusColor: _planStatusColor(),
                planStatusLabel: _planStatusLabel(),
                currentMonthColor: _currentMonthColor(),
                progressValue: _progressValue(),
                money: _money,
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
  final double progressValue;
  final String Function(double) money;

  const _WideCard({
    required this.plan,
    required this.thisMonthStatus,
    required this.formattedStartDate,
    required this.formattedNextDueDate,
    required this.planStatusColor,
    required this.planStatusLabel,
    required this.currentMonthColor,
    required this.progressValue,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CardPanel(
                  title: 'Installment Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              height: 1.15,
                            ),
                          ),
                          InlineBadge(
                            label: plan.category,
                            background: cs.secondaryContainer,
                            foreground: cs.onSecondaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                DetailLine(
                                  label: 'Monthly',
                                  value: money(plan.monthlyAmount),
                                ),
                                const SizedBox(height: 10),
                                DetailLine(
                                  label: 'Balance',
                                  value: money(plan.remainingBalance),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              children: [
                                DetailLine(
                                  label: 'Progress',
                                  value: plan.status == 'completed' ||
                                          plan.remainingBalance <= 0.009
                                      ? '${plan.durationMonths}/${plan.durationMonths} paid'
                                      : '${plan.paidMonths}/${plan.durationMonths} paid',
                                ),
                                const SizedBox(height: 10),
                                DetailLine(
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
              const SizedBox(width: 16),
              Expanded(
                child: CardPanel(
                  title: 'Customer Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailLine(
                        label: 'Name',
                        value: (plan.customerName ?? '').trim().isEmpty
                            ? 'Not provided'
                            : plan.customerName!,
                      ),
                      const SizedBox(height: 10),
                      DetailLine(
                        label: 'Phone',
                        value: (plan.customerPhone ?? '').trim().isEmpty
                            ? 'Not provided'
                            : plan.customerPhone!,
                      ),
                      const SizedBox(height: 10),
                      DetailLine(
                        label: 'Address',
                        value: (plan.customerAddress ?? '').trim().isEmpty
                            ? 'Not provided'
                            : plan.customerAddress!,
                        multiline: true,
                      ),
                      const SizedBox(height: 10),
                      DetailLine(
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
        const SizedBox(height: 8),
        _FooterBar(
          chips: [
            _StatusChip(
              label: 'This month: $thisMonthStatus',
              color: currentMonthColor,
            ),
            _StatusChip(
              label: 'Plan: $planStatusLabel',
              color: planStatusColor,
            ),
            if (plan.installmentImagePaths.isNotEmpty)
              _StatusChip(
                label: 'Docs: ${plan.installmentImagePaths.length}',
                color: Colors.teal.shade700,
              ),
          ],
          progress: _ProgressStrip(
            value: progressValue,
            color: planStatusColor,
            label: 'Completion',
          ),
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
  final double progressValue;
  final String Function(double) money;

  const _CompactCard({
    required this.plan,
    required this.thisMonthStatus,
    required this.formattedStartDate,
    required this.formattedNextDueDate,
    required this.planStatusColor,
    required this.planStatusLabel,
    required this.currentMonthColor,
    required this.progressValue,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardPanel(
          title: 'Installment Details',
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
                    plan.itemName,
                    style: const TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                      height: 1.15,
                    ),
                  ),
                  InlineBadge(
                    label: plan.category,
                    background: Theme.of(context).colorScheme.secondaryContainer,
                    foreground:
                        Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DetailLine(
                label: 'Monthly',
                value: money(plan.monthlyAmount),
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Balance',
                value: money(plan.remainingBalance),
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Progress',
                value: plan.status == 'completed' ||
                        plan.remainingBalance <= 0.009
                    ? '${plan.durationMonths}/${plan.durationMonths} paid'
                    : '${plan.paidMonths}/${plan.durationMonths} paid',
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Started',
                value: formattedStartDate,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Next due',
                value: formattedNextDueDate,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Images',
                value: '${plan.installmentImagePaths.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CardPanel(
          title: 'Customer Details',
          compact: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailLine(
                label: 'Name',
                value: (plan.customerName ?? '').trim().isEmpty
                    ? 'Not provided'
                    : plan.customerName!,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Phone',
                value: (plan.customerPhone ?? '').trim().isEmpty
                    ? 'Not provided'
                    : plan.customerPhone!,
              ),
              const SizedBox(height: 8),
              DetailLine(
                label: 'Address',
                value: (plan.customerAddress ?? '').trim().isEmpty
                    ? 'Not provided'
                    : plan.customerAddress!,
                multiline: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CardPanel(
          compact: true,
          title: 'Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  if (plan.installmentImagePaths.isNotEmpty)
                    _StatusChip(
                      label: 'Docs: ${plan.installmentImagePaths.length}',
                      color: Colors.teal.shade700,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _ProgressStrip(
                value: progressValue,
                color: planStatusColor,
                label: 'Completion',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterBar extends StatelessWidget {
  final List<Widget> chips;
  final Widget progress;

  const _FooterBar({
    required this.chips,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 7,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.40),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.outlineVariant.withOpacity(0.35),
                ),
              ),
              child: progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const _ProgressStrip({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final percent = (value * 100).round();

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.6,
            fontWeight: FontWeight.w800,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 11,
                  backgroundColor: cs.surfaceContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            '$percent%',
            key: ValueKey(percent),
            style: TextStyle(
              fontSize: 13.6,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.6,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}