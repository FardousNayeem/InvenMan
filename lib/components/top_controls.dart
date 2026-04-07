import 'package:flutter/material.dart';

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
                    child: _SortControl(
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
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  child: FilledButton.icon(
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: rowHeight,
              child: _SearchBarControl(
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
                    child: _SortControl(
                      value: sortBy,
                      onChanged: onSortChanged,
                    ),
                  ),
                ),
                SizedBox(width: gap),
                SizedBox(
                  height: rowHeight,
                  child: FilledButton.icon(
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
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
            child: _SortControl(
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
                ? _SearchBarControl(
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
        SizedBox(width: gap),
        Expanded(
          flex: addFlex,
          child: SizedBox(
            height: rowHeight,
            child: FilledButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add_rounded),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(isSearchActive ? 'Add' : 'Add Item'),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _SortControl({
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
            labelText: 'Sort by',
            border: InputBorder.none,
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'name', child: Text('Name')),
            DropdownMenuItem(
              value: 'cost_price_asc',
              child: Text('Cost: Low to High'),
            ),
            DropdownMenuItem(
              value: 'cost_price_desc',
              child: Text('Cost: High to Low'),
            ),
            DropdownMenuItem(
              value: 'selling_price_asc',
              child: Text('Selling: Low to High'),
            ),
            DropdownMenuItem(
              value: 'selling_price_desc',
              child: Text('Selling: High to Low'),
            ),
            DropdownMenuItem(
              value: 'quantity_desc',
              child: Text('Stock: High to Low'),
            ),
            DropdownMenuItem(
              value: 'quantity_asc',
              child: Text('Stock: Low to High'),
            ),
            DropdownMenuItem(value: 'category', child: Text('Category')),
            DropdownMenuItem(value: 'updated_at_desc', child: Text('Recently Updated')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SearchBarControl extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBarControl({
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
              decoration: const InputDecoration(
                hintText: 'Search inventory',
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