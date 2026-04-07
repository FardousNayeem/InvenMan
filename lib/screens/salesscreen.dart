import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/components/sale_card.dart';

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
  late Future<List<SaleRecord>> _salesFuture;

  @override
  void initState() {
    super.initState();
    _loadSales();
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

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<List<SaleRecord>>(
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

        final sales = snapshot.data ?? [];

        if (sales.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 90),
                Icon(
                  Icons.point_of_sale_outlined,
                  size: 68,
                  color: cs.outline,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'No sales yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Completed sales will appear here.',
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final sale = sales[i];

              return SaleCard(
                sale: sale,
                formattedDate: _formatDate(sale.soldAt),
                onTap: () {
                  // later: open sale details page
                },
              );
            },
          ),
        );
      },
    );
  }
}