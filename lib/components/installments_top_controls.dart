import 'package:flutter/material.dart';

class InstallmentsTopControls extends StatelessWidget {
  final String sortBy;
  final bool isSearchActive;
  final bool isSortExpanded;
  final TextEditingController searchController;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onActivateSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCancelSearch;

  const InstallmentsTopControls({
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
                    child: _InstallmentsSortControl(
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
              child: _InstallmentsSearchBarControl(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onCancelSearch,
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: rowHeight,
              child: _InstallmentsSortControl(
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
            child: _InstallmentsSortControl(
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
                ? _InstallmentsSearchBarControl(
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

class _InstallmentsSortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _InstallmentsSortControl({
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
            labelText: 'Sort installments by',
            border: InputBorder.none,
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: 'next_due_asc',
              child: Text('Next Due Soonest'),
            ),
            DropdownMenuItem(
              value: 'next_due_desc',
              child: Text('Next Due Farthest'),
            ),
            DropdownMenuItem(
              value: 'customer',
              child: Text('Customer Name'),
            ),
            DropdownMenuItem(
              value: 'item',
              child: Text('Item Name'),
            ),
            DropdownMenuItem(
              value: 'status',
              child: Text('Plan Status'),
            ),
            DropdownMenuItem(
              value: 'latest',
              child: Text('Latest Created'),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _InstallmentsSearchBarControl extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _InstallmentsSearchBarControl({
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