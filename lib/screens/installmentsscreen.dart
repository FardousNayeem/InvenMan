import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/services/db_services.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/components/installment_card.dart';
import 'package:invenman/components/installments_top_controls.dart';
import 'package:invenman/screens/installment_details_screen.dart';
import 'package:invenman/theme/app_ui.dart';

class InstallmentsPage extends StatefulWidget {
  final int refreshToken;
  final VoidCallback? onDataChanged;

  const InstallmentsPage({
    super.key,
    required this.refreshToken,
    this.onDataChanged,
  });

  @override
  State<InstallmentsPage> createState() => _InstallmentsPageState();
}

class _InstallmentsPageState extends State<InstallmentsPage> {
  static const String _defaultSort = 'next_due_asc';

  late Future<List<_InstallmentListItem>> _installmentsFuture;

  String _sortBy = _defaultSort;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InstallmentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(_loadInstallments);
    }
  }

  void _loadInstallments() {
    _installmentsFuture = _fetchInstallmentItems();
  }

  Future<List<_InstallmentListItem>> _fetchInstallmentItems() async {
    final plans = await DBHelper.fetchInstallmentPlans(sortBy: _sortBy);

    return Future.wait(
      plans.map((plan) async {
        final payments = plan.id == null
            ? <InstallmentPayment>[]
            : await DBHelper.fetchInstallmentPayments(plan.id!);

        return _InstallmentListItem(
          plan: plan,
          thisMonthStatus: _resolveThisMonthStatus(plan, payments),
        );
      }),
    );
  }

  Future<void> _refresh() async {
    setState(_loadInstallments);
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  bool get _isSortExpanded => !_isSearchActive && _sortBy != _defaultSort;

  void _activateSearch() {
    setState(() {
      _isSearchActive = true;
    });
  }

  void _cancelSearch() {
    setState(() {
      _searchController.clear();
      _isSearchActive = false;
      _sortBy = _defaultSort;
      _loadInstallments();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date.toLocal());
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  String _resolveThisMonthStatus(
    InstallmentPlan plan,
    List<InstallmentPayment> payments,
  ) {
    final now = DateTime.now();

    InstallmentPayment? currentMonthPayment;
    for (final payment in payments) {
      final due = payment.dueDate.toLocal();
      if (due.year == now.year && due.month == now.month) {
        currentMonthPayment = payment;
        break;
      }
    }

    if (currentMonthPayment != null) {
      switch (currentMonthPayment.status) {
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

    if (plan.isCompleted) return 'Paid';
    if (plan.isOverdue) return 'Overdue';
    return 'Not due';
  }

  List<_InstallmentListItem> _applySearch(List<_InstallmentListItem> items) {
    if (_searchQuery.isEmpty) return items;

    return items.where((entry) {
      final plan = entry.plan;
      return plan.itemName.toLowerCase().contains(_searchQuery) ||
          plan.category.toLowerCase().contains(_searchQuery) ||
          (plan.customerName ?? '').toLowerCase().contains(_searchQuery) ||
          (plan.customerPhone ?? '').toLowerCase().contains(_searchQuery) ||
          (plan.customerAddress ?? '').toLowerCase().contains(_searchQuery) ||
          plan.status.toLowerCase().contains(_searchQuery) ||
          entry.thisMonthStatus.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _openInstallmentDetails(InstallmentPlan plan) async {
    final didChange = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InstallmentDetailsScreen(plan: plan),
      ),
    );

    if (!mounted) return;

    if (didChange == true) {
      widget.onDataChanged?.call();
    }

    setState(_loadInstallments);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppUi.pageHPadding,
            AppUi.pageTopPadding,
            AppUi.pageHPadding,
            8,
          ),
          child: InstallmentsTopControls(
            sortBy: _sortBy,
            isSearchActive: _isSearchActive,
            isSortExpanded: _isSortExpanded,
            searchController: _searchController,
            onSortChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
                _loadInstallments();
              });
            },
            onActivateSearch: _activateSearch,
            onSearchChanged: (_) => setState(() {}),
            onCancelSearch: _cancelSearch,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<_InstallmentListItem>>(
            future: _installmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Something went wrong.',
                    style: TextStyle(color: cs.error),
                  ),
                );
              }

              final allItems = snapshot.data ?? [];
              final items = _applySearch(allItems);

              final totalPlans = allItems.length;
              final activeCount =
                  allItems.where((e) => e.plan.status == 'active').length;
              final overdueCount =
                  allItems.where((e) => e.plan.status == 'overdue').length;
              final dueNowCount = allItems
                  .where((e) =>
                      e.thisMonthStatus == 'Due' ||
                      e.thisMonthStatus == 'Partial' ||
                      e.thisMonthStatus == 'Overdue')
                  .length;

              if (items.isEmpty) {
                final isSearching = _searchQuery.isNotEmpty;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppUi.pageHPadding,
                      8,
                      AppUi.pageHPadding,
                      AppUi.pageBottomPadding,
                    ),
                    children: [
                      AppEmptyState(
                        icon: isSearching
                            ? Icons.search_off_rounded
                            : Icons.calendar_month_outlined,
                        title: isSearching
                            ? 'No matching installment plans found'
                            : 'No installment plans yet',
                        message: isSearching
                            ? 'Try searching by item, customer, phone, address, or status.'
                            : 'When an item is sold using installment payment, its plan will appear here with progress, balance, and due tracking.',
                        action: isSearching
                            ? OutlinedButton.icon(
                                onPressed: _cancelSearch,
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Clear search'),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  key: const PageStorageKey('installments_list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppUi.pageHPadding,
                          2,
                          AppUi.pageHPadding,
                          12,
                        ),
                        child: _InstallmentsInsightBar(
                          totalPlans: totalPlans,
                          activeCount: activeCount,
                          overdueCount: overdueCount,
                          dueNowCount: dueNowCount,
                          isSearching: _searchQuery.isNotEmpty,
                          resultCount: items.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppUi.pageHPadding,
                        0,
                        AppUi.pageHPadding,
                        AppUi.pageBottomPadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppUi.listGap),
                        itemBuilder: (_, i) {
                          final entry = items[i];
                          final plan = entry.plan;

                          return InstallmentCard(
                            plan: plan,
                            thisMonthStatus: entry.thisMonthStatus,
                            formattedStartDate: _formatDate(plan.startDate),
                            formattedNextDueDate: plan.nextDueDate != null
                                ? _formatDateTime(plan.nextDueDate!)
                                : 'No remaining dues',
                            onTap: () => _openInstallmentDetails(plan),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InstallmentsInsightBar extends StatelessWidget {
  final int totalPlans;
  final int activeCount;
  final int overdueCount;
  final int dueNowCount;
  final bool isSearching;
  final int resultCount;

  const _InstallmentsInsightBar({
    required this.totalPlans,
    required this.activeCount,
    required this.overdueCount,
    required this.dueNowCount,
    required this.isSearching,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;

    if (compact) {
      return Column(
        children: [
          if (isSearching) AppSearchNotice(resultCount: resultCount),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Plans',
                  value: '$totalPlans',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppInsightTile(
                  label: 'Active',
                  value: '$activeCount',
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Overdue',
                  value: '$overdueCount',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppInsightTile(
                  label: 'Due now',
                  value: '$dueNowCount',
                  icon: Icons.calendar_month_outlined,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppInsightTile(
            label: 'Plans',
            value: '$totalPlans',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: 'Active',
            value: '$activeCount',
            icon: Icons.play_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: 'Overdue',
            value: '$overdueCount',
            icon: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: isSearching ? 'Results' : 'Due now',
            value: isSearching ? '$resultCount' : '$dueNowCount',
            icon: isSearching
                ? Icons.search_rounded
                : Icons.calendar_month_outlined,
          ),
        ),
      ],
    );
  }
}

class _InstallmentListItem {
  final InstallmentPlan plan;
  final String thisMonthStatus;

  const _InstallmentListItem({
    required this.plan,
    required this.thisMonthStatus,
  });
}