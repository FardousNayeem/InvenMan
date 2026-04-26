import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/database/db_services.dart';
import 'package:invenman/theme/app_ui.dart';
import 'package:invenman/components/installment/installment_file_editor.dart';

class SaleDetailsScreen extends StatefulWidget {
  final SaleRecord sale;

  const SaleDetailsScreen({
    super.key,
    required this.sale,
  });

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  late SaleRecord _sale;
  bool _isRefreshing = false;

  SaleRecord get sale => _sale;

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
  }

  Future<void> _reloadSale() async {
    if (_isRefreshing) return;
    if (sale.id == null) return;

    _isRefreshing = true;
    try {
      final freshSale = await DBHelper.fetchSaleRecordById(sale.id!);
      if (!mounted || freshSale == null) return;

      setState(() {
        _sale = freshSale;
      });
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _refresh() async {
    await _reloadSale();
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  String get _paymentLabel {
    if (sale.isInstallment) {
      return 'Installment (${sale.installmentMonths ?? '-'} months)';
    }
    return 'Direct';
  }

  Color _profitColor() {
    return sale.profit >= 0 ? Colors.green.shade700 : Colors.red.shade700;
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

  Future<void> _editDocuments() async {
    if (!sale.isInstallment || sale.id == null) return;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (_) => InstallmentDocumentEditorDialog(
        title: 'Edit installment documents',
        subtitle:
            'Add or remove installment images for this sale. The linked installment plan will update too.',
        initialPaths: sale.installmentImagePaths,
        onSave: (paths) async {
          await DBHelper.updateInstallmentDocumentsBySaleRecordId(
            saleRecordId: sale.id!,
            imagePaths: paths,
          );
        },
      ),
    );

    if (didSave == true && mounted) {
      await _reloadSale();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installment documents updated successfully.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 900;
    final profitColor = _profitColor();

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 360,
              backgroundColor: cs.surface,
              surfaceTintColor: cs.surfaceTint,
              leading: AppHeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 20,
                  end: 20,
                  bottom: 18,
                ),
                title: Text(
                  sale.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.65,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _HeroPlaceholder(
                      icon: Icons.receipt_long_rounded,
                      label: sale.category,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.08),
                            Colors.black.withOpacity(0.58),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              AppHeroPill(
                                icon: Icons.category_rounded,
                                label: sale.category,
                              ),
                              AppHeroPill(
                                icon: sale.isInstallment
                                    ? Icons.calendar_month_rounded
                                    : Icons.payments_rounded,
                                label: _paymentLabel,
                              ),
                              AppHeroPill(
                                icon: Icons.trending_up_rounded,
                                label: 'Profit',
                                accentColor: profitColor,
                              ),
                              AppHeroPill(
                                icon: Icons.schedule_rounded,
                                label: _formatDate(sale.soldAt),
                              ),
                              if (sale.soldColors.isNotEmpty)
                                AppHeroPill(
                                  icon: Icons.palette_outlined,
                                  label: sale.soldColors.join(', '),
                                  accentColor: Colors.indigo.shade700,
                                ),
                              if (sale.isInstallment &&
                                  sale.installmentImagePaths.isNotEmpty)
                                AppHeroPill(
                                  icon: Icons.collections_outlined,
                                  label: '${sale.installmentImagePaths.length} docs',
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            (sale.customerName ?? '').trim().isNotEmpty
                                ? 'Sold to ${sale.customerName}'
                                : 'Transaction details, sold colors, warranty coverage, and installment documents for this sale.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact)
                      Column(
                        children: [
                          _SaleOverviewCard(
                            sale: sale,
                            formattedDate: _formatDate(sale.soldAt),
                            profitColor: profitColor,
                          ),
                          const SizedBox(height: AppUi.sectionGap),
                          _CustomerCard(sale: sale),
                          const SizedBox(height: AppUi.sectionGap),
                          _PaymentCard(sale: sale),
                          const SizedBox(height: AppUi.sectionGap),
                          _SaleWarrantyCard(sale: sale),
                          if (sale.isInstallment) ...[
                            const SizedBox(height: AppUi.sectionGap),
                            _SaleInstallmentImageGallery(
                              imagePaths: sale.installmentImagePaths,
                              onOpenViewer: (index) {
                                _openInstallmentImageViewer(
                                  imagePaths: sale.installmentImagePaths,
                                  initialIndex: index,
                                );
                              },
                              onEditDocuments: _editDocuments,
                            ),
                          ],
                        ],
                      )
                    else
                      Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _StretchHeightCard(
                                    child: _SaleOverviewCard(
                                      sale: sale,
                                      formattedDate: _formatDate(sale.soldAt),
                                      profitColor: profitColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppUi.sectionGap),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _CustomerCard(sale: sale),
                                      const SizedBox(height: AppUi.sectionGap),
                                      _PaymentCard(sale: sale),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppUi.sectionGap),
                          _SaleWarrantyCard(sale: sale),
                          if (sale.isInstallment) ...[
                            const SizedBox(height: AppUi.sectionGap),
                            _SaleInstallmentImageGallery(
                              imagePaths: sale.installmentImagePaths,
                              onOpenViewer: (index) {
                                _openInstallmentImageViewer(
                                  imagePaths: sale.installmentImagePaths,
                                  initialIndex: index,
                                );
                              },
                              onEditDocuments: _editDocuments,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StretchHeightCard extends StatelessWidget {
  final Widget child;

  const _StretchHeightCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.infinity,
      child: child,
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPlaceholder({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHighest,
            cs.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleInstallmentImageGallery extends StatelessWidget {
  final List<String> imagePaths;
  final ValueChanged<int> onOpenViewer;
  final Future<void> Function() onEditDocuments;

  const _SaleInstallmentImageGallery({
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
            : SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(imagePaths.length, (index) {
                    final path = imagePaths[index];

                    return GestureDetector(
                      onTap: () => onOpenViewer(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 104,
                          height: 104,
                          color: cs.surfaceContainerHighest,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(path),
                                fit: BoxFit.cover,
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
                                    borderRadius: BorderRadius.circular(999),
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
              ),
      ),
    );
  }
}

class _SaleOverviewCard extends StatelessWidget {
  final SaleRecord sale;
  final String formattedDate;
  final Color profitColor;

  const _SaleOverviewCard({
    required this.sale,
    required this.formattedDate,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Purchase details',
      subtitle: 'Transaction pricing, quantity, colors, and outcome',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Cost',
                  sensitiveText: sale.costPrice.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Sold At',
                  valueText: sale.sellPrice.toStringAsFixed(0),
                  icon: Icons.sell_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Qty',
                  valueText: '${sale.quantitySold}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppMetricTile(
                  label: 'Profit',
                  sensitiveText: sale.profit.toStringAsFixed(0),
                  isSensitive: true,
                  icon: Icons.trending_up_rounded,
                  valueColor: profitColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppLineItem(label: 'Date', value: formattedDate),
          const SizedBox(height: 8),
          AppLineItem(label: 'Category', value: sale.category),
          if (sale.soldColors.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppLineItem(
              label: 'Colors',
              value: sale.soldColors.join(', '),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final SaleRecord sale;

  const _CustomerCard({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Customer details',
      subtitle: 'Buyer information captured at the time of sale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLineItem(
            label: 'Name',
            value: (sale.customerName ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerName!,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Phone',
            value: (sale.customerPhone ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerPhone!,
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Address',
            value: (sale.customerAddress ?? '').trim().isEmpty
                ? 'Not provided'
                : sale.customerAddress!,
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final SaleRecord sale;

  const _PaymentCard({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'Payment details',
      subtitle: 'Settlement mode, sold colors, and installment terms',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppLineItem(
            label: 'Type',
            value: sale.isInstallment ? 'Installment' : 'Direct',
          ),
          const SizedBox(height: 8),
          AppLineItem(
            label: 'Duration',
            value: sale.isInstallment
                ? '${sale.installmentMonths ?? '-'} month(s)'
                : 'Not applicable',
          ),
          if (sale.soldColors.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppLineItem(
              label: 'Colors',
              value: sale.soldColors.join(', '),
            ),
          ],
          if (sale.isInstallment) ...[
            const SizedBox(height: 8),
            AppLineItem(
              label: 'Documents',
              value: '${sale.installmentImagePaths.length}',
            ),
          ],
        ],
      ),
    );
  }
}

class _SaleWarrantyCard extends StatelessWidget {
  final SaleRecord sale;

  const _SaleWarrantyCard({
    required this.sale,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppSectionCard(
      title: 'Warranty remaining',
      subtitle: 'Current coverage left from the purchase date',
      child: sale.warranties.isEmpty
          ? ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No warranty included.',
                        style: TextStyle(
                          fontSize: 14.25,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: sale.warranties.entries.map((entry) {
                final remaining =
                    _remainingWarrantyLabel(sale.soldAt, entry.value);
                final expired = remaining == 'Expired';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          expired
                              ? Icons.gpp_bad_outlined
                              : Icons.verified_outlined,
                          size: 18,
                          color: expired ? Colors.red.shade700 : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.4,
                            ),
                          ),
                        ),
                        Text(
                          remaining,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: expired
                                ? Colors.red.shade700
                                : cs.onSurfaceVariant,
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

  void _goToPrevious() {
    if (_currentIndex <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNext() {
    if (_currentIndex >= widget.imagePaths.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: cs.onSurfaceVariant,
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
                  onPressed: _currentIndex > 0 ? _goToPrevious : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.45),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withOpacity(0.18),
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
                  onPressed: _currentIndex < widget.imagePaths.length - 1
                      ? _goToNext
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.45),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black.withOpacity(0.18),
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