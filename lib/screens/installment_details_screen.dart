import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/components/installment/installment_file_editor.dart';
import 'package:invenman/services/db_services.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/theme/app_ui.dart';

class InstallmentDetailsScreen extends StatefulWidget {
  final InstallmentPlan plan;

  const InstallmentDetailsScreen({
    super.key,
    required this.plan,
  });

  @override
  State<InstallmentDetailsScreen> createState() =>
      _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  late Future<_InstallmentDetailData> _detailFuture;
  bool _didChange = false;

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

  String _money(double value) => value.toStringAsFixed(0);

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
      text: payment.amountPaid > 0 ? payment.amountPaid.toStringAsFixed(0) : '',
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
                        value: _money(payment.amountDue),
                      ),
                      const SizedBox(height: 8),
                      _DialogInfoLine(
                        label: 'Current paid',
                        value: _money(payment.amountPaid),
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
                        'You can record less or more than the original due. Future dues will automatically rebalance from the next remaining months.',
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

                    await DBHelper.saveInstallmentPayment(
                      installmentPaymentId: payment.id!,
                      amountPaid: amount,
                      paidDate:
                          amount > 0 ? (selectedPaidDate ?? DateTime.now()) : null,
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
      _didChange = true;
      setState(_loadData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installment payment updated successfully.'),
        ),
      );
    }
  }

  Future<void> _openInstallmentImageViewer({
    required List<String> imagePaths,
    required int initialIndex,
  }) async {
    if (imagePaths.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenInstallmentImageViewer(
          imagePaths: imagePaths,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _editDocuments(InstallmentPlan plan) async {
    if (plan.id == null) return;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => InstallmentDocumentEditorDialog(
        title: 'Edit installment documents',
        subtitle:
            'Add or remove installment images for this plan. The linked sale record will update too.',
        initialPaths: plan.installmentImagePaths,
        onSave: (paths) async {
          await DBHelper.updateInstallmentDocumentsByInstallmentPlanId(
            installmentPlanId: plan.id!,
            imagePaths: paths,
          );
        },
      ),
    );

    if (didSave == true && mounted) {
      _didChange = true;
      setState(_loadData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installment documents updated successfully.'),
        ),
      );
    }
  }

  Future<bool> _handleBack() async {
    Navigator.of(context).pop(_didChange);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 920;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
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
                    expandedHeight: 320,
                    backgroundColor: cs.surface,
                    surfaceTintColor: cs.surfaceTint,
                    leading: AppHeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: _handleBack,
                    ),
                    title: Text(
                      plan.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
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
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      plan.itemName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 34,
                                        height: 1.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      (plan.customerName ?? '').trim().isNotEmpty
                                          ? 'Installment plan for ${plan.customerName}'
                                          : 'Installment schedule and payment tracking',
                                      style: TextStyle(
                                        fontSize: 18,
                                        height: 1.2,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _HeaderChip(
                                      icon: Icons.category_rounded,
                                      label: plan.category,
                                    ),
                                    _HeaderChip(
                                      icon: Icons.flag_rounded,
                                      label: _planStatusLabel(plan.status),
                                      iconColor: planStatusColor,
                                    ),
                                    _HeaderChip(
                                      icon: Icons.calendar_month_rounded,
                                      label: '${plan.durationMonths} month(s)',
                                    ),
                                    if (plan.installmentImagePaths.isNotEmpty)
                                      _HeaderChip(
                                        icon: Icons.collections_outlined,
                                        label: '${plan.installmentImagePaths.length} docs',
                                      ),
                                  ],
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
                      padding: const EdgeInsets.fromLTRB(
                        AppUi.pageHPadding,
                        18,
                        AppUi.pageHPadding,
                        AppUi.pageBottomPadding,
                      ),
                      child: Column(
                        children: [
                          if (isCompact)
                            Column(
                              children: [
                                _SummaryCard(
                                  plan: plan,
                                  totalCollected: totalCollected,
                                  paidTowardInstallments: paidTowardInstallments,
                                  formatDateTime: _formatDateTime,
                                  planStatusColor: planStatusColor,
                                  planStatusLabel: _planStatusLabel(plan.status),
                                  money: _money,
                                ),
                                const SizedBox(height: AppUi.sectionGap),
                                _CustomerCard(plan: plan),
                                const SizedBox(height: AppUi.sectionGap),
                                _FinancialBreakdownCard(
                                  plan: plan,
                                  totalCollected: totalCollected,
                                  paidTowardInstallments: paidTowardInstallments,
                                  money: _money,
                                ),
                                const SizedBox(height: AppUi.sectionGap),
                                _InstallmentImageGallery(
                                  imagePaths: plan.installmentImagePaths,
                                  onOpenViewer: (index) {
                                    _openInstallmentImageViewer(
                                      imagePaths: plan.installmentImagePaths,
                                      initialIndex: index,
                                    );
                                  },
                                  onEditDocuments: () => _editDocuments(plan),
                                ),
                                const SizedBox(height: AppUi.sectionGap),
                                _ScheduleCard(
                                  payments: payments,
                                  formatDate: _formatDate,
                                  paymentStatusColor: _paymentStatusColor,
                                  paymentStatusLabel: _paymentStatusLabel,
                                  onEditPayment: (payment) =>
                                      _openPaymentDialog(plan, payment),
                                  money: _money,
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
                                        paidTowardInstallments:
                                            paidTowardInstallments,
                                        formatDateTime: _formatDateTime,
                                        planStatusColor: planStatusColor,
                                        planStatusLabel:
                                            _planStatusLabel(plan.status),
                                        money: _money,
                                      ),
                                      const SizedBox(height: AppUi.sectionGap),
                                      _ScheduleCard(
                                        payments: payments,
                                        formatDate: _formatDate,
                                        paymentStatusColor: _paymentStatusColor,
                                        paymentStatusLabel:
                                            _paymentStatusLabel,
                                        onEditPayment: (payment) =>
                                            _openPaymentDialog(plan, payment),
                                        money: _money,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppUi.sectionGap),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      _CustomerCard(plan: plan),
                                      const SizedBox(height: AppUi.sectionGap),
                                      _FinancialBreakdownCard(
                                        plan: plan,
                                        totalCollected: totalCollected,
                                        paidTowardInstallments:
                                            paidTowardInstallments,
                                        money: _money,
                                      ),
                                      const SizedBox(height: AppUi.sectionGap),
                                      _InstallmentImageGallery(
                                        imagePaths: plan.installmentImagePaths,
                                        onOpenViewer: (index) {
                                          _openInstallmentImageViewer(
                                            imagePaths: plan.installmentImagePaths,
                                            initialIndex: index,
                                          );
                                        },
                                        onEditDocuments: () => _editDocuments(plan),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InstallmentImageGallery extends StatelessWidget {
  final List<String> imagePaths;
  final ValueChanged<int> onOpenViewer;
  final Future<void> Function() onEditDocuments;

  const _InstallmentImageGallery({
    required this.imagePaths,
    required this.onOpenViewer,
    required this.onEditDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: AppSectionCard(
        title: 'Installment Files',
        subtitle: 'Installment Agreement Images',
        trailing: FilledButton.tonalIcon(
          onPressed: onEditDocuments,
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Edit documents'),
        ),
        child: imagePaths.isEmpty
            ? SizedBox(
                width: double.infinity,
                child: Text(
                  'No installment images added.',
                  style: TextStyle(
                    fontSize: 14.25,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final hasTwoColumns = constraints.maxWidth >= 360;
                  final thumbWidth = hasTwoColumns
                      ? (constraints.maxWidth - spacing) / 2
                      : constraints.maxWidth;

                  return SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(imagePaths.length, (index) {
                        final path = imagePaths[index];

                        return GestureDetector(
                          onTap: () => onOpenViewer(index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: thumbWidth,
                              height: 150,
                              color: cs.surfaceContainerHighest,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(path),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image_rounded,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _FullscreenInstallmentImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const _FullscreenInstallmentImageViewer({
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<_FullscreenInstallmentImageViewer> createState() =>
      _FullscreenInstallmentImageViewerState();
}

class _FullscreenInstallmentImageViewerState
    extends State<_FullscreenInstallmentImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goPrevious() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _goNext() {
    if (_currentIndex >= widget.imagePaths.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Document ${_currentIndex + 1} of ${widget.imagePaths.length}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (_, index) {
              final path = widget.imagePaths[index];

              return InteractiveViewer(
                minScale: 0.9,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    File(path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.imagePaths.length > 1) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed: _currentIndex > 0 ? _goPrevious : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.42),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withOpacity(0.16),
                    disabledForegroundColor: Colors.white38,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton.filledTonal(
                  onPressed:
                      _currentIndex < widget.imagePaths.length - 1 ? _goNext : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.42),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withOpacity(0.16),
                    disabledForegroundColor: Colors.white38,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
            ),
          ],
        ],
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

class _SummaryCard extends StatelessWidget {
  final InstallmentPlan plan;
  final double totalCollected;
  final double paidTowardInstallments;
  final String Function(DateTime) formatDateTime;
  final Color planStatusColor;
  final String planStatusLabel;
  final String Function(double) money;

  const _SummaryCard({
    required this.plan,
    required this.totalCollected,
    required this.paidTowardInstallments,
    required this.formatDateTime,
    required this.planStatusColor,
    required this.planStatusLabel,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Plan summary',
      subtitle: 'Overall contract, status, and progress snapshot',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Monthly',
                  valueText: money(plan.monthlyAmount),
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Progress',
                  valueText:
                      plan.status == 'completed' || plan.remainingBalance <= 0.009
                          ? '${plan.durationMonths}/${plan.durationMonths}'
                          : '${plan.paidMonths}/${plan.durationMonths}',
                  icon: Icons.stacked_line_chart_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Remaining',
                  valueText: money(plan.remainingBalance),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Status',
                  valueText: planStatusLabel,
                  icon: Icons.flag_rounded,
                  valueColor: planStatusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppLineItem(
            label: 'Started',
            value: formatDateTime(plan.startDate),
            labelWidth: 108,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Next due',
            value: plan.nextDueDate == null
                ? 'No remaining dues'
                : formatDateTime(plan.nextDueDate!),
            labelWidth: 108,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Paid',
            value: money(paidTowardInstallments),
            labelWidth: 108,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Collected',
            value: money(totalCollected),
            labelWidth: 108,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Documents',
            value: '${plan.installmentImagePaths.length}',
            labelWidth: 108,
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
    return AppSectionCard(
      title: 'Customer Details',
      subtitle: 'Buyer information connected to this installment plan',
      child: Column(
        children: [
          AppLineItem(
            label: 'Name',
            value: (plan.customerName ?? '').trim().isEmpty
                ? 'Not provided'
                : plan.customerName!,
            labelWidth: 108,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Phone',
            value: (plan.customerPhone ?? '').trim().isEmpty
                ? 'Not provided'
                : plan.customerPhone!,
            labelWidth: 108,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Address',
            value: (plan.customerAddress ?? '').trim().isEmpty
                ? 'Not provided'
                : plan.customerAddress!,
            labelWidth: 108,
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
  final String Function(double) money;

  const _FinancialBreakdownCard({
    required this.plan,
    required this.totalCollected,
    required this.paidTowardInstallments,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Financial Breakdown',
      subtitle: 'Down payment, financed balance, and collection progress',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Total amount',
                  valueText: money(plan.totalAmount),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Down payment',
                  valueText: money(plan.downPayment),
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Financed',
                  valueText: money(plan.financedAmount),
                  icon: Icons.credit_score_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Collected',
                  valueText: money(totalCollected),
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppLineItem(
            label: 'Installments paid',
            value: money(paidTowardInstallments),
            labelWidth: 128,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Remaining balance',
            value: money(plan.remainingBalance),
            labelWidth: 128,
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
  final String Function(double) money;

  const _ScheduleCard({
    required this.payments,
    required this.formatDate,
    required this.paymentStatusColor,
    required this.paymentStatusLabel,
    required this.onEditPayment,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const AppSectionCard(
        title: 'Payment Schedule',
        subtitle: 'Generated monthly payment entries',
        child: Text('No installment payment rows found.'),
      );
    }

    return AppSectionCard(
      title: 'Payment Schedule',
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
                borderRadius: BorderRadius.circular(18),
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
                            letterSpacing: -0.15,
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
                          borderRadius:
                              BorderRadius.circular(AppUi.pillRadius),
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
                          value: money(payment.amountDue),
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
                          value: money(payment.amountPaid),
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
                    AppLineItem(
                      label: 'Note',
                      value: payment.note!,
                      labelWidth: 70,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => onEditPayment(payment),
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: Text(
                        payment.amountPaid > 0
                            ? 'Edit payment'
                            : 'Record payment',
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

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? cs.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              height: 1,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
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