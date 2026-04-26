import 'package:flutter/material.dart';
import 'package:invenman/theme/app_sort_button.dart';
import 'package:invenman/theme/app_top_bar_buttons.dart';

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
    final rowHeight = compact ? 46.0 : 52.0;
    final gap = compact ? 8.0 : 10.0;

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
                  child: AppTopBarIconButton(
                    onPressed: onActivateSearch,
                    icon: Icons.search_rounded,
                    tooltip: 'Search sales',
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
                : AppTopBarIconButton(
                    onPressed: onActivateSearch,
                    icon: Icons.search_rounded,
                    tooltip: 'Search sales',
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

  String _label(String value) {
    switch (value) {
      case 'sold_at_asc':
        return 'Oldest Sale';
      case 'name':
        return 'Item Name';
      case 'sell_price_asc':
        return 'MRP: Low to High';
      case 'sell_price_desc':
        return 'MRP: High to Low';
      case 'profit_asc':
        return 'Profit: Low to High';
      case 'profit_desc':
        return 'Profit: High to Low';
      case 'category':
        return 'Category';
      case 'sold_at_desc':
      default:
        return 'Newest Sale';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSortButton<String>(
      value: value,
      tooltip: 'Sort sales',
      labelBuilder: _label,
      onSelected: (selected) => onChanged(selected),
      items: const [
        PopupMenuItem(value: 'sold_at_desc', child: Text('Newest Sale')),
        PopupMenuItem(value: 'sold_at_asc', child: Text('Oldest Sale')),
        PopupMenuItem(value: 'name', child: Text('Item Name')),
        PopupMenuItem(value: 'sell_price_asc', child: Text('MRP: Low to High')),
        PopupMenuItem(value: 'sell_price_desc', child: Text('MRP: High to Low')),
        PopupMenuItem(value: 'profit_asc', child: Text('Profit: Low to High')),
        PopupMenuItem(value: 'profit_desc', child: Text('Profit: High to Low')),
        PopupMenuItem(value: 'category', child: Text('Category')),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: true,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search sales',
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
                isDense: true,
                isCollapsed: true,
                filled: false,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onClear,
            tooltip: 'Cancel search',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}