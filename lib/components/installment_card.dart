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

    return _InteractiveCardShell(
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
            children: [
              Expanded(
                child: _Panel(
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
                            ),
                          ),
                          _InlineBadge(
                            label: plan.category,
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
                                  label: 'Monthly',
                                  value: money(plan.monthlyAmount),
                                ),
                                const SizedBox(height: 8),
                                _DetailLine(
                                  label: 'Balance',
                                  value: money(plan.remainingBalance),
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
                                  value: plan.status == 'completed' ||
                                          plan.remainingBalance <= 0.009
                                      ? '${plan.durationMonths}/${plan.durationMonths} paid'
                                      : '${plan.paidMonths}/${plan.durationMonths} paid',
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
                      const SizedBox(height: 12),
                      _ProgressStrip(
                        value: progressValue,
                        color: planStatusColor,
                        label: 'Completion',
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
        _Panel(
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
                    ),
                  ),
                  _InlineBadge(
                    label: plan.category,
                    background: Theme.of(context).colorScheme.secondaryContainer,
                    foreground: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailLine(
                label: 'Monthly',
                value: money(plan.monthlyAmount),
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Balance',
                value: money(plan.remainingBalance),
              ),
              const SizedBox(height: 8),
              _DetailLine(
                label: 'Progress',
                value: plan.status == 'completed' || plan.remainingBalance <= 0.009
                    ? '${plan.durationMonths}/${plan.durationMonths} paid'
                    : '${plan.paidMonths}/${plan.durationMonths} paid',
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
              const SizedBox(height: 12),
              _ProgressStrip(
                value: progressValue,
                color: planStatusColor,
                label: 'Completion',
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
        const SizedBox(height: 12),
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
                border: Border.all(
                  color: _hovered ? cs.primary.withOpacity(0.22) : cs.outlineVariant,
                ),
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
              fontSize: 13.4,
              height: 1.4,
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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

    return Column(
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
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return LinearProgressIndicator(
                value: animatedValue,
                minHeight: 8,
                backgroundColor: cs.surfaceContainer,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
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