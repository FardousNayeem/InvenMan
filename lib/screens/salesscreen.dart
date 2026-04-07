import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/components/sale_card.dart';
import 'package:invenman/components/sales_top_controls.dart';

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

              if (sales.isEmpty) {
                final emptyText =
                    _searchQuery.isNotEmpty ? 'No matching sales found' : 'No sales yet';

                final emptySubText = _searchQuery.isNotEmpty
                    ? 'Try searching by item, category, customer, phone, or address.'
                    : 'Completed sales will appear here.';

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 90),
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.point_of_sale_outlined,
                        size: 72,
                        color: cs.outline,
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'Sales',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          emptyText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            emptySubText,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final sale = sales[i];

                    return SaleCard(
                      sale: sale,
                      formattedDate: _formatDate(sale.soldAt),
                      onTap: () {
                        // later: sale details page
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}