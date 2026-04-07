import 'package:flutter/material.dart';
import 'package:invenman/theme/app_sort_button.dart';
import 'package:invenman/theme/app_top_bar_buttons.dart';

class InventoryTopControls extends StatelessWidget {
  final String sortBy;
  final bool isSearchActive;
  final bool isSortExpanded;
  final TextEditingController searchController;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onActivateSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCancelSearch;
  final VoidCallback onAddItem;

  const InventoryTopControls({
    super.key,
    required this.sortBy,
    required this.isSearchActive,
    required this.isSortExpanded,
    required this.searchController,
    required this.onSortChanged,
    required this.onActivateSearch,
    required this.onSearchChanged,
    required this.onCancelSearch,
    required this.onAddItem,
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
                    child: _InventorySortControl(
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
                    tooltip: 'Search inventory',
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  child: AppTopBarAddButton(
                    onPressed: onAddItem,
                    label: 'Add',
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: rowHeight,
              child: _InventorySearchBar(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onCancelSearch,
              ),
            ),
            SizedBox(height: gap),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: rowHeight,
                    child: _InventorySortControl(
                      value: sortBy,
                      onChanged: onSortChanged,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  child: AppTopBarAddButton(
                    onPressed: onAddItem,
                    label: 'Add',
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    final sortFlex = isSearchActive ? 2 : (isSortExpanded ? 8 : 4);
    final middleFlex = isSearchActive ? 7 : 1;
    final addFlex = isSearchActive ? 2 : (isSortExpanded ? 2 : 3);

    return Row(
      children: [
        Expanded(
          flex: sortFlex,
          child: SizedBox(
            height: rowHeight,
            child: _InventorySortControl(
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
                ? _InventorySearchBar(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    onClear: onCancelSearch,
                  )
                : AppTopBarIconButton(
                    onPressed: onActivateSearch,
                    icon: Icons.search_rounded,
                    tooltip: 'Search inventory',
                  ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: addFlex,
          child: SizedBox(
            height: rowHeight,
            child: AppTopBarAddButton(
              onPressed: onAddItem,
              label: isSearchActive ? 'Add' : 'Add Item',
            ),
          ),
        ),
      ],
    );
  }
}

class _InventorySortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _InventorySortControl({
    required this.value,
    required this.onChanged,
  });

  String _label(String value) {
    switch (value) {
      case 'cost_price_asc':
        return 'Cost: Low to High';
      case 'cost_price_desc':
        return 'Cost: High to Low';
      case 'selling_price_asc':
        return 'MRP: Low to High';
      case 'selling_price_desc':
        return 'MRP: High to Low';
      case 'quantity_desc':
        return 'Stock: High to Low';
      case 'quantity_asc':
        return 'Stock: Low to High';
      case 'category':
        return 'Category';
      case 'updated_at_desc':
        return 'Recently Updated';
      case 'created_at_desc':
        return 'Recently Added';
      case 'name':
      default:
        return 'Name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSortButton<String>(
      value: value,
      tooltip: 'Sort inventory',
      labelBuilder: _label,
      onSelected: (selected) => onChanged(selected),
      items: const [
        PopupMenuItem(value: 'name', child: Text('Name')),
        PopupMenuItem(value: 'cost_price_asc', child: Text('Cost: Low to High')),
        PopupMenuItem(value: 'cost_price_desc', child: Text('Cost: High to Low')),
        PopupMenuItem(value: 'selling_price_asc', child: Text('MRP: Low to High')),
        PopupMenuItem(value: 'selling_price_desc', child: Text('MRP: High to Low')),
        PopupMenuItem(value: 'quantity_desc', child: Text('Stock: High to Low')),
        PopupMenuItem(value: 'quantity_asc', child: Text('Stock: Low to High')),
        PopupMenuItem(value: 'category', child: Text('Category')),
        PopupMenuItem(value: 'updated_at_desc', child: Text('Recently Updated')),
        PopupMenuItem(value: 'created_at_desc', child: Text('Recently Added')),
      ],
    );
  }
}

class _InventorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _InventorySearchBar({
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
                hintText: 'Search inventory',
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