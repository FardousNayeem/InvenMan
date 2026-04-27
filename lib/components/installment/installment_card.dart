import 'package:flutter/material.dart';

import 'package:invenman/components/common/card_panel.dart';
import 'package:invenman/components/common/detail_line.dart';
import 'package:invenman/components/common/inline_badge.dart';
import 'package:invenman/components/common/interactive_card_shell.dart';
import 'package:invenman/components/common/responsive_card_utils.dart';
import 'package:invenman/components/common/status_pill.dart';
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
    final compact = ResponsiveCardUtils.isCompact(context, breakpoint: 820);

    return InteractiveCardShell(
      onTap: onTap,
      borderRadius: compact ? 24 : 28,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: compact
            ? _InstallmentCardCompact(
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
            : _InstallmentCardWide(
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

class _InstallmentCardWide extends StatelessWidget {
  final InstallmentPlan plan;
  final String thisMonthStatus;
  final String formattedStartDate;
  final String formattedNextDueDate;
  final Color planStatusColor;
  final String planStatusLabel;
  final Color currentMonthColor;
  final double progressValue;
  final String Function(double) money;

  const _InstallmentCardWide({
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
    final details = _InstallmentCardDetails.fromPlan(
      plan: plan,
      formattedStartDate: formattedStartDate,
      formattedNextDueDate: formattedNextDueDate,
      money: money,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _InstallmentDetailsPanel(
                  plan: plan,
                  details: details,
                  compact: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InstallmentCustomerPanel(
                  details: details,
                  compact: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InstallmentStatusFooter(
          plan: plan,
          thisMonthStatus: thisMonthStatus,
          planStatusLabel: planStatusLabel,
          planStatusColor: planStatusColor,
          currentMonthColor: currentMonthColor,
          progressValue: progressValue,
          compact: false,
        ),
      ],
    );
  }
}

class _InstallmentCardCompact extends StatelessWidget {
  final InstallmentPlan plan;
  final String thisMonthStatus;
  final String formattedStartDate;
  final String formattedNextDueDate;
  final Color planStatusColor;
  final String planStatusLabel;
  final Color currentMonthColor;
  final double progressValue;
  final String Function(double) money;

  const _InstallmentCardCompact({
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
    final details = _InstallmentCardDetails.fromPlan(
      plan: plan,
      formattedStartDate: formattedStartDate,
      formattedNextDueDate: formattedNextDueDate,
      money: money,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InstallmentDetailsPanel(
          plan: plan,
          details: details,
          compact: true,
        ),
        const SizedBox(height: 12),
        _InstallmentCustomerPanel(
          details: details,
          compact: true,
        ),
        const SizedBox(height: 12),
        _InstallmentStatusFooter(
          plan: plan,
          thisMonthStatus: thisMonthStatus,
          planStatusLabel: planStatusLabel,
          planStatusColor: planStatusColor,
          currentMonthColor: currentMonthColor,
          progressValue: progressValue,
          compact: true,
        ),
      ],
    );
  }
}

class _InstallmentDetailsPanel extends StatelessWidget {
  final InstallmentPlan plan;
  final _InstallmentCardDetails details;
  final bool compact;

  const _InstallmentDetailsPanel({
    required this.plan,
    required this.details,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: 'Installment details',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InstallmentTitleRow(
            plan: plan,
            compact: compact,
          ),
          SizedBox(height: compact ? 12 : 16),
          compact
              ? _InstallmentDetailsCompact(details: details)
              : _InstallmentDetailsWide(details: details),
        ],
      ),
    );
  }
}

class _InstallmentTitleRow extends StatelessWidget {
  final InstallmentPlan plan;
  final bool compact;

  const _InstallmentTitleRow({
    required this.plan,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final itemName = plan.itemName.trim().isEmpty ? 'Unnamed item' : plan.itemName;
    final category = plan.category.trim();

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
            height: 1.15,
          ),
        ),
        InlineBadge(
          label: category.isEmpty ? 'Uncategorized' : category,
          background: cs.secondaryContainer,
          foreground: cs.onSecondaryContainer,
        ),
      ],
    );
  }
}

class _InstallmentDetailsWide extends StatelessWidget {
  final _InstallmentCardDetails details;

  const _InstallmentDetailsWide({
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              DetailLine(
                label: 'Monthly',
                sensitiveValue: details.monthlyAmount,
                isSensitive: true,
                labelMinWidth: 72,
              ),
              const SizedBox(height: 10),
              DetailLine(
                label: 'Balance',
                sensitiveValue: details.remainingBalance,
                isSensitive: true,
                labelMinWidth: 72,
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
                value: details.progressText,
                labelMinWidth: 72,
              ),
              const SizedBox(height: 10),
              DetailLine(
                label: 'Started',
                value: details.formattedStartDate,
                labelMinWidth: 72,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstallmentDetailsCompact extends StatelessWidget {
  final _InstallmentCardDetails details;

  const _InstallmentDetailsCompact({
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailLine(
          label: 'Monthly',
          sensitiveValue: details.monthlyAmount,
          isSensitive: true,
          labelMinWidth: 72,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Balance',
          sensitiveValue: details.remainingBalance,
          isSensitive: true,
          labelMinWidth: 72,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Progress',
          value: details.progressText,
          labelMinWidth: 72,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Started',
          value: details.formattedStartDate,
          labelMinWidth: 72,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Next due',
          value: details.formattedNextDueDate,
          labelMinWidth: 72,
        ),
        const SizedBox(height: 8),
        DetailLine(
          label: 'Docs',
          value: details.docsCount,
          labelMinWidth: 72,
        ),
      ],
    );
  }
}

class _InstallmentCustomerPanel extends StatelessWidget {
  final _InstallmentCardDetails details;
  final bool compact;

  const _InstallmentCustomerPanel({
    required this.details,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      title: 'Customer details',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailLine(
            label: 'Name',
            value: details.customerName,
            labelMinWidth: 72,
          ),
          SizedBox(height: compact ? 8 : 10),
          DetailLine(
            label: 'Phone',
            value: details.customerPhone,
            labelMinWidth: 72,
          ),
          SizedBox(height: compact ? 8 : 10),
          DetailLine(
            label: 'Address',
            value: details.customerAddress,
            multiline: true,
            labelMinWidth: 72,
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            DetailLine(
              label: 'Next due',
              value: details.formattedNextDueDate,
              labelMinWidth: 72,
            ),
          ],
        ],
      ),
    );
  }
}

class _InstallmentStatusFooter extends StatelessWidget {
  final InstallmentPlan plan;
  final String thisMonthStatus;
  final String planStatusLabel;
  final Color planStatusColor;
  final Color currentMonthColor;
  final double progressValue;
  final bool compact;

  const _InstallmentStatusFooter({
    required this.plan,
    required this.thisMonthStatus,
    required this.planStatusLabel,
    required this.planStatusColor,
    required this.currentMonthColor,
    required this.progressValue,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final statusChips = [
      StatusPill(
        label: 'This month: $thisMonthStatus',
        color: currentMonthColor,
      ),
      StatusPill(
        label: 'Plan: $planStatusLabel',
        color: planStatusColor,
      ),
      if (plan.installmentImagePaths.isNotEmpty)
        StatusPill(
          label: 'Docs: ${plan.installmentImagePaths.length}',
          color: Colors.teal.shade700,
        ),
    ];

    if (compact) {
      return CardPanel(
        title: 'Status',
        compact: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveChipWrap(
              spacing: 8,
              runSpacing: 8,
              children: statusChips,
            ),
            const SizedBox(height: 14),
            _ProgressStrip(
              value: progressValue,
              color: planStatusColor,
              label: 'Completion',
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 7,
          child: ResponsiveChipWrap(
            spacing: 10,
            runSpacing: 10,
            children: statusChips,
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          flex: 5,
          child: _ProgressPanel(
            child: _ProgressStrip(
              value: progressValue,
              color: planStatusColor,
              label: 'Completion',
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final Widget child;

  const _ProgressPanel({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha:0.40),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha:0.35),
        ),
      ),
      child: child,
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

class _InstallmentCardDetails {
  final String monthlyAmount;
  final String remainingBalance;
  final String progressText;
  final String formattedStartDate;
  final String formattedNextDueDate;
  final String docsCount;
  final String customerName;
  final String customerPhone;
  final String customerAddress;

  const _InstallmentCardDetails({
    required this.monthlyAmount,
    required this.remainingBalance,
    required this.progressText,
    required this.formattedStartDate,
    required this.formattedNextDueDate,
    required this.docsCount,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
  });

  factory _InstallmentCardDetails.fromPlan({
    required InstallmentPlan plan,
    required String formattedStartDate,
    required String formattedNextDueDate,
    required String Function(double) money,
  }) {
    final completed = plan.status == 'completed' || plan.remainingBalance <= 0.009;

    return _InstallmentCardDetails(
      monthlyAmount: money(plan.monthlyAmount),
      remainingBalance: money(plan.remainingBalance),
      progressText: completed
          ? '${plan.durationMonths}/${plan.durationMonths} paid'
          : '${plan.paidMonths}/${plan.durationMonths} paid',
      formattedStartDate: formattedStartDate,
      formattedNextDueDate: formattedNextDueDate,
      docsCount: '${plan.installmentImagePaths.length}',
      customerName: _fallbackText(plan.customerName),
      customerPhone: _fallbackText(plan.customerPhone),
      customerAddress: _fallbackText(plan.customerAddress),
    );
  }

  static String _fallbackText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Not provided' : trimmed;
  }
}