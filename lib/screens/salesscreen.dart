import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/components/sale_card.dart';
import 'package:invenman/components/sales_top_controls.dart';
import 'package:invenman/screens/sale_details_screen.dart';

class SalesPage extends StatefulWidget {
  final int refreshToken;

  const SalesPage({
    super.key,
    required this.refreshToken,
  });

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  static const String _defaultSort = 'sold_at_desc';

  late Future<List<SaleRecord>> _salesFuture;

  String _sortBy = _defaultSort;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SalesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(_loadSales);
    }
  }

  void _loadSales() {
    _salesFuture = DBHelper.fetchSaleRecords();
  }

  Future<void> _refresh() async {
    setState(_loadSales);
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
      _loadSales();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  List<SaleRecord> _applySearch(List<SaleRecord> allSales) {
    if (_searchQuery.isEmpty) return allSales;

    return allSales.where((sale) {
      return sale.itemName.toLowerCase().contains(_searchQuery) ||
          sale.category.toLowerCase().contains(_searchQuery) ||
          (sale.customerName ?? '').toLowerCase().contains(_searchQuery) ||
          (sale.customerPhone ?? '').toLowerCase().contains(_searchQuery) ||
          (sale.customerAddress ?? '').toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<SaleRecord> _applySort(List<SaleRecord> sales) {
    final sorted = [...sales];

    switch (_sortBy) {
      case 'sold_at_asc':
        sorted.sort((a, b) => a.soldAt.compareTo(b.soldAt));
        break;
      case 'sold_at_desc':
        sorted.sort((a, b) => b.soldAt.compareTo(a.soldAt));
        break;
      case 'name':
        sorted.sort(
          (a, b) => a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
        );
        break;
      case 'sell_price_asc':
        sorted.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
        break;
      case 'sell_price_desc':
        sorted.sort((a, b) => b.sellPrice.compareTo(a.sellPrice));
        break;
      case 'profit_asc':
        sorted.sort((a, b) => a.profit.compareTo(b.profit));
        break;
      case 'profit_desc':
        sorted.sort((a, b) => b.profit.compareTo(a.profit));
        break;
      case 'category':
        sorted.sort(
          (a, b) => a.category.toLowerCase().compareTo(b.category.toLowerCase()),
        );
        break;
      default:
        sorted.sort((a, b) => b.soldAt.compareTo(a.soldAt));
    }

    return sorted;
  }

  void _openSaleDetails(SaleRecord sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaleDetailsScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: SalesTopControls(
            sortBy: _sortBy,
            isSearchActive: _isSearchActive,
            isSortExpanded: _isSortExpanded,
            searchController: _searchController,
            onSortChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
              });
            },
            onActivateSearch: _activateSearch,
            onSearchChanged: (_) => setState(() {}),
            onCancelSearch: _cancelSearch,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<SaleRecord>>(
            future: _salesFuture,
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

              final allSales = snapshot.data ?? [];
              final searched = _applySearch(allSales);
              final sales = _applySort(searched);

              final totalSales = allSales.length;
              final totalUnitsSold = allSales.fold<int>(
                0,
                (sum, sale) => sum + sale.quantitySold,
              );
              final installmentCount = allSales
                  .where((sale) => sale.paymentType == 'installment')
                  .length;
              final directCount = allSales.length - installmentCount;

              if (sales.isEmpty) {
                final isSearching = _searchQuery.isNotEmpty;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const SizedBox(height: 70),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSearching
                              ? Icons.search_off_rounded
                              : Icons.point_of_sale_outlined,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isSearching ? 'No matching sales found' : 'No sales yet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          isSearching
                              ? 'Try searching by item, category, customer, phone, or address.'
                              : 'Completed sales will appear here with payment type, customer details, warranties, and product image snapshots.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSearching)
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _cancelSearch,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Clear search'),
                          ),
                        ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  key: const PageStorageKey('sales_list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                        child: _SalesInsightBar(
                          totalSales: totalSales,
                          totalUnitsSold: totalUnitsSold,
                          directCount: directCount,
                          installmentCount: installmentCount,
                          isSearching: _searchQuery.isNotEmpty,
                          resultCount: sales.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) {
                          final sale = sales[i];

                          return SaleCard(
                            sale: sale,
                            formattedDate: _formatDate(sale.soldAt),
                            onTap: () => _openSaleDetails(sale),
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

class _SalesInsightBar extends StatelessWidget {
  final int totalSales;
  final int totalUnitsSold;
  final int directCount;
  final int installmentCount;
  final bool isSearching;
  final int resultCount;

  const _SalesInsightBar({
    required this.totalSales,
    required this.totalUnitsSold,
    required this.directCount,
    required this.installmentCount,
    required this.isSearching,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 760;

    if (compact) {
      return Column(
        children: [
          if (isSearching)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt_rounded, size: 18, color: cs.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$resultCount result${resultCount == 1 ? '' : 's'} found',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  label: 'Sales',
                  value: '$totalSales',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightTile(
                  label: 'Units',
                  value: '$totalUnitsSold',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  label: 'Direct',
                  value: '$directCount',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightTile(
                  label: 'Installment',
                  value: '$installmentCount',
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
          child: _InsightTile(
            label: 'Sales',
            value: '$totalSales',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            label: 'Units',
            value: '$totalUnitsSold',
            icon: Icons.inventory_2_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            label: 'Direct',
            value: '$directCount',
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            label: isSearching ? 'Results' : 'Installment',
            value: isSearching ? '$resultCount' : '$installmentCount',
            icon: isSearching
                ? Icons.search_rounded
                : Icons.calendar_month_outlined,
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.035),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
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