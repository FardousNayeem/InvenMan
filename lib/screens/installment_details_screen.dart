import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';

class InstallmentDetailsScreen extends StatefulWidget {
  final InstallmentPlan plan;

  const InstallmentDetailsScreen({
    super.key,
    required this.plan,
  });

  @override
  State<InstallmentDetailsScreen> createState() => _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  late Future<_InstallmentDetailData> _detailFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _detailFuture = _fetchData();
  }

  Future<_InstallmentDetailData> _fetchData() async {
    final freshPlan = widget.plan.id != null
        ? await DBHelper.fetchInstallmentPlanById(widget.plan.id!)
        : null;

    final plan = freshPlan ?? widget.plan;

    final payments = plan.id == null
        ? <InstallmentPayment>[]
        : await DBHelper.fetchInstallmentPayments(plan.id!);

    return _InstallmentDetailData(
      plan: plan,
      payments: payments,
    );
  }

  Future<void> _refresh() async {
    setState(_loadData);
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date.toLocal());
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  Color _planStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade700;
      case 'overdue':
        return Colors.red.shade700;
      case 'active':
      default:
        return Colors.blue.shade700;
    }
  }

  String _planStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      case 'active':
      default:
        return 'Active';
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green.shade700;
      case 'partial':
        return Colors.orange.shade700;
      case 'overdue':
        return Colors.red.shade700;
      case 'pending':
      default:
        return Colors.blue.shade700;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      case 'pending':
      default:
        return 'Due';
    }
  }

  Future<void> _openPaymentDialog(
    InstallmentPlan plan,
    InstallmentPayment payment,
  ) async {
    final amountController = TextEditingController(
      text: payment.amountPaid > 0 ? payment.amountPaid.toStringAsFixed(2) : '',
    );
    final noteController = TextEditingController(
      text: payment.note ?? '',
    );

    DateTime? selectedPaidDate = payment.paidDate?.toLocal();

    final didSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record payment',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Month ${payment.installmentNumber} • Due ${_formatDate(payment.dueDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DialogInfoLine(
                        label: 'Amount due',
                        value: payment.amountDue.toStringAsFixed(2),
                      ),
                      const SizedBox(height: 8),
                      _DialogInfoLine(
                        label: 'Current paid',
                        value: payment.amountPaid.toStringAsFixed(2),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount paid',
                          hintText: 'Enter payment amount',
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedPaidDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setLocalState(() {
                              selectedPaidDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedPaidDate == null
                                      ? 'Select paid date'
                                      : 'Paid date: ${DateFormat('d MMM yyyy').format(selectedPaidDate!)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: selectedPaidDate == null
                                        ? cs.onSurfaceVariant
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Note',
                          hintText: 'Optional note for this payment',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tip: full payment marks the month as paid, partial payment keeps it visible as partial.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim());

                    if (amount == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid payment amount.'),
                        ),
                      );
                      return;
                    }

                    if (amount < 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Payment amount cannot be negative.'),
                        ),
                      );
                      return;
                    }

                    if (amount > payment.amountDue) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment cannot exceed ${payment.amountDue.toStringAsFixed(2)}.',
                          ),
                        ),
                      );
                      return;
                    }

                    await DBHelper.saveInstallmentPayment(
                      installmentPaymentId: payment.id!,
                      amountPaid: amount,
                      paidDate: amount > 0 ? (selectedPaidDate ?? DateTime.now()) : null,
                      note: noteController.text.trim(),
                    );

                    if (!mounted) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save payment'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (didSave == true && mounted) {
      setState(_loadData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Installment payment updated successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 920;

    return Scaffold(
      backgroundColor: cs.surface,
      body: FutureBuilder<_InstallmentDetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                'Something went wrong.',
                style: TextStyle(color: cs.error),
              ),
            );
          }

          final detail = snapshot.data!;
          final plan = detail.plan;
          final payments = detail.payments;
          final planStatusColor = _planStatusColor(plan.status);

          final fullyPaidAmount = payments.fold<double>(
            0,
            (sum, payment) => sum + payment.amountPaid,
          );

          final paidTowardInstallments = fullyPaidAmount;
          final totalCollected = plan.downPayment + paidTowardInstallments;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  expandedHeight: 330,
                  backgroundColor: cs.surface,
                  surfaceTintColor: cs.surfaceTint,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 20,
                      end: 20,
                      bottom: 18,
                    ),
                    title: Text(
                      plan.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primary.withOpacity(0.22),
                            cs.secondaryContainer.withOpacity(0.55),
                            cs.surfaceContainerHighest,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 94),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _HeroPill(
                                    icon: Icons.category_rounded,
                                    label: plan.category,
                                  ),
                                  _HeroPill(
                                    icon: Icons.flag_rounded,
                                    label: _planStatusLabel(plan.status),
                                    accentColor: planStatusColor,
                                  ),
                                  _HeroPill(
                                    icon: Icons.calendar_month_rounded,
                                    label: '${plan.durationMonths} month(s)',
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                (plan.customerName ?? '').trim().isNotEmpty
                                    ? 'Installment plan for ${plan.customerName}'
                                    : 'Installment schedule and payment tracking',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    child: Column(
                      children: [
                        if (isCompact)
                          Column(
                            children: [
                              _SummaryCard(
                                plan: plan,
                                totalCollected: totalCollected,
                                paidTowardInstallments: paidTowardInstallments,
                                formatDate: _formatDate,
                                formatDateTime: _formatDateTime,
                                planStatusColor: planStatusColor,
                                planStatusLabel: _planStatusLabel(plan.status),
                              ),
                              const SizedBox(height: 14),
                              _CustomerCard(plan: plan),
                              const SizedBox(height: 14),
                              _FinancialBreakdownCard(
                                plan: plan,
                                totalCollected: totalCollected,
                                paidTowardInstallments: paidTowardInstallments,
                              ),
                              const SizedBox(height: 14),
                              _ScheduleCard(
                                payments: payments,
                                formatDate: _formatDate,
                                paymentStatusColor: _paymentStatusColor,
                                paymentStatusLabel: _paymentStatusLabel,
                                onEditPayment: (payment) =>
                                    _openPaymentDialog(plan, payment),
                              ),
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
                                    _SummaryCard(
                                      plan: plan,
                                      totalCollected: totalCollected,
                                      paidTowardInstallments: paidTowardInstallments,
                                      formatDate: _formatDate,
                                      formatDateTime: _formatDateTime,
                                      planStatusColor: planStatusColor,
                                      planStatusLabel: _planStatusLabel(plan.status),
                                    ),
                                    const SizedBox(height: 14),
                                    _FinancialBreakdownCard(
                                      plan: plan,
                                      totalCollected: totalCollected,
                                      paidTowardInstallments: paidTowardInstallments,
                                    ),
                                    const SizedBox(height: 14),
                                    _ScheduleCard(
                                      payments: payments,
                                      formatDate: _formatDate,
                                      paymentStatusColor: _paymentStatusColor,
                                      paymentStatusLabel: _paymentStatusLabel,
                                      onEditPayment: (payment) =>
                                          _openPaymentDialog(plan, payment),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 4,
                                child: _CustomerCard(plan: plan),
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
        },
      ),
    );
  }
}

class _InstallmentDetailData {
  final InstallmentPlan plan;
  final List<InstallmentPayment> payments;

  const _InstallmentDetailData({
    required this.plan,
    required this.payments,
  });
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;

  const _HeroPill({
    required this.icon,
    required this.label,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class _SummaryCard extends StatelessWidget {
  final InstallmentPlan plan;
  final double totalCollected;
  final double paidTowardInstallments;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatDateTime;
  final Color planStatusColor;
  final String planStatusLabel;

  const _SummaryCard({
    required this.plan,
    required this.totalCollected,
    required this.paidTowardInstallments,
    required this.formatDate,
    required this.formatDateTime,
    required this.planStatusColor,
    required this.planStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Plan summary',
      subtitle: 'Overall contract, status, and progress snapshot',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Monthly',
                  value: plan.monthlyAmount.toStringAsFixed(2),
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Progress',
                  value: '${plan.paidMonths}/${plan.durationMonths}',
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Remaining',
                  value: plan.remainingBalance.toStringAsFixed(2),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Status',
                  value: planStatusLabel,
                  icon: Icons.flag_rounded,
                  valueColor: planStatusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LineItem(label: 'Started', value: formatDateTime(plan.startDate)),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Next due',
            value: plan.nextDueDate == null
                ? 'No remaining dues'
                : formatDateTime(plan.nextDueDate!),
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Paid',
            value: paidTowardInstallments.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Collected',
            value: totalCollected.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final InstallmentPlan plan;

  const _CustomerCard({
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Customer details',
      subtitle: 'Buyer information connected to this installment plan',
      child: Column(
        children: [
          _LineItem(
            label: 'Name',
            value: (plan.customerName ?? '').trim().isEmpty
                ? 'Not provided'
                : plan.customerName!,
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Phone',
            value: (plan.customerPhone ?? '').trim().isEmpty
                ? 'Not provided'
                : plan.customerPhone!,
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Address',
            value: (plan.customerAddress ?? '').trim().isEmpty
                ? 'Not provided'
                : plan.customerAddress!,
          ),
        ],
      ),
    );
  }
}

class _FinancialBreakdownCard extends StatelessWidget {
  final InstallmentPlan plan;
  final double totalCollected;
  final double paidTowardInstallments;

  const _FinancialBreakdownCard({
    required this.plan,
    required this.totalCollected,
    required this.paidTowardInstallments,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      title: 'Financial breakdown',
      subtitle: 'Down payment, financed balance, and collection progress',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Total amount',
                  value: plan.totalAmount.toStringAsFixed(2),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Down payment',
                  value: plan.downPayment.toStringAsFixed(2),
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Financed',
                  value: plan.financedAmount.toStringAsFixed(2),
                  icon: Icons.credit_score_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  label: 'Collected',
                  value: totalCollected.toStringAsFixed(2),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LineItem(
            label: 'Paid in installments',
            value: paidTowardInstallments.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          _LineItem(
            label: 'Remaining balance',
            value: plan.remainingBalance.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final List<InstallmentPayment> payments;
  final String Function(DateTime) formatDate;
  final Color Function(String) paymentStatusColor;
  final String Function(String) paymentStatusLabel;
  final ValueChanged<InstallmentPayment> onEditPayment;

  const _ScheduleCard({
    required this.payments,
    required this.formatDate,
    required this.paymentStatusColor,
    required this.paymentStatusLabel,
    required this.onEditPayment,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const _GlassSection(
        title: 'Payment schedule',
        subtitle: 'Generated monthly payment entries',
        child: Text('No installment payment rows found.'),
      );
    }

    return _GlassSection(
      title: 'Payment schedule',
      subtitle: 'Record, edit, and monitor each monthly payment',
      child: Column(
        children: payments.map((payment) {
          final statusColor = paymentStatusColor(payment.status);
          final statusLabel = paymentStatusLabel(payment.status);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Month ${payment.installmentNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfo(
                          label: 'Due date',
                          value: formatDate(payment.dueDate),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniInfo(
                          label: 'Amount due',
                          value: payment.amountDue.toStringAsFixed(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfo(
                          label: 'Amount paid',
                          value: payment.amountPaid.toStringAsFixed(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniInfo(
                          label: 'Paid date',
                          value: payment.paidDate == null
                              ? 'Not recorded'
                              : formatDate(payment.paidDate!),
                        ),
                      ),
                    ],
                  ),
                  if ((payment.note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 84,
                          child: Text(
                            'Note:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            payment.note!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => onEditPayment(payment),
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: Text(
                        payment.amountPaid > 0 ? 'Edit payment' : 'Record payment',
                      ),
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

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
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
                Text(
                  value,
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
          width: 110,
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

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfo({
    required this.label,
    required this.value,
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
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DialogInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 96,
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
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}