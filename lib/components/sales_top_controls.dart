import 'package:flutter/material.dart';

class SalesTopControls extends StatelessWidget {
  final String sortBy;
  final bool isSearchActive;
  final bool isSortExpanded;
  final TextEditingController searchController;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onActivateSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCancelSearch;

  const SalesTopControls({
    super.key,
    required this.sortBy,
    required this.isSearchActive,
    required this.isSortExpanded,
    required this.searchController,
    required this.onSortChanged,
    required this.onActivateSearch,
    required this.onSearchChanged,
    required this.onCancelSearch,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;
    final rowHeight = compact ? 64.0 : 72.0;
    final gap = compact ? 8.0 : 12.0;

    if (compact) {
      return Column(
        children: [
          if (!isSearchActive)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: rowHeight,
                    child: _SalesSortControl(
                      value: sortBy,
                      onChanged: onSortChanged,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  width: rowHeight,
                  child: IconButton.filledTonal(
                    onPressed: onActivateSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: rowHeight,
              child: _SalesSearchBarControl(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onCancelSearch,
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: rowHeight,
              child: _SalesSortControl(
                value: sortBy,
                onChanged: onSortChanged,
              ),
            ),
          ],
        ],
      );
    }

    final sortFlex = isSearchActive ? 2 : (isSortExpanded ? 8 : 5);
    final middleFlex = isSearchActive ? 7 : 1;

    return Row(
      children: [
        Expanded(
          flex: sortFlex,
          child: SizedBox(
            height: rowHeight,
            child: _SalesSortControl(
              value: sortBy,
              onChanged: onSortChanged,
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: middleFlex,
          child: SizedBox(
            height: rowHeight,
            child: isSearchActive
                ? _SalesSearchBarControl(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    onClear: onCancelSearch,
                  )
                : IconButton.filledTonal(
                    onPressed: onActivateSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SalesSortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _SalesSortControl({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Center(
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sort sales by',
            border: InputBorder.none,
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'sold_at_desc', child: Text('Newest Sale')),
            DropdownMenuItem(value: 'sold_at_asc', child: Text('Oldest Sale')),
            DropdownMenuItem(value: 'name', child: Text('Item Name')),
            DropdownMenuItem(value: 'sell_price_asc', child: Text('MRP: Low to High')),
            DropdownMenuItem(value: 'sell_price_desc', child: Text('MRP: High to Low')),
            DropdownMenuItem(value: 'profit_asc', child: Text('Profit: Low to High')),
            DropdownMenuItem(value: 'profit_desc', child: Text('Profit: High to Low')),
            DropdownMenuItem(value: 'category', child: Text('Category')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SalesSearchBarControl extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SalesSearchBarControl({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Search by item, customer, phone, address',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel search',
          ),
        ],
      ),
    );
  }
}