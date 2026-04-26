import 'package:flutter/material.dart';

import 'package:invenman/theme/app_sort_button.dart';
import 'package:invenman/theme/app_top_bar_buttons.dart';

class HistoryTopControls extends StatelessWidget {
  final String sortBy;
  final String filterBy;
  final bool isSearchActive;
  final bool isSortExpanded;
  final TextEditingController searchController;
  final ValueChanged<String?> onSortChanged;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onActivateSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCancelSearch;

  const HistoryTopControls({
    super.key,
    required this.sortBy,
    required this.filterBy,
    required this.isSearchActive,
    required this.isSortExpanded,
    required this.searchController,
    required this.onSortChanged,
    required this.onFilterChanged,
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
                    child: HistorySortControl(
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
                    tooltip: 'Search history',
                  ),
                ),
              ],
            )
          else ...[
            SizedBox(
              height: rowHeight,
              child: HistorySearchBar(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onCancelSearch,
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: rowHeight,
              child: HistorySortControl(
                value: sortBy,
                onChanged: onSortChanged,
              ),
            ),
          ],
          SizedBox(height: gap),
          HistoryFilterBar(
            selectedValue: filterBy,
            onChanged: onFilterChanged,
          ),
        ],
      );
    }

    final sortFlex = isSearchActive ? 2 : (isSortExpanded ? 7 : 5);
    final middleFlex = isSearchActive ? 5 : 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: sortFlex,
              child: SizedBox(
                height: rowHeight,
                child: HistorySortControl(
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
                    ? HistorySearchBar(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onClear: onCancelSearch,
                      )
                    : AppTopBarIconButton(
                        onPressed: onActivateSearch,
                        icon: Icons.search_rounded,
                        tooltip: 'Search history',
                      ),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        HistoryFilterBar(
          selectedValue: filterBy,
          onChanged: onFilterChanged,
        ),
      ],
    );
  }
}

class HistorySortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const HistorySortControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _label(String value) {
    switch (value) {
      case 'oldest':
        return 'Oldest First';
      case 'action':
        return 'Action Type';
      case 'item':
        return 'Item Name';
      case 'latest':
      default:
        return 'Latest First';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSortButton<String>(
      value: value,
      tooltip: 'Sort history',
      labelBuilder: _label,
      onSelected: (selected) => onChanged(selected),
      items: const [
        PopupMenuItem(value: 'latest', child: Text('Latest First')),
        PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
        PopupMenuItem(value: 'action', child: Text('Action Type')),
        PopupMenuItem(value: 'item', child: Text('Item Name')),
      ],
    );
  }
}

class HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const HistorySearchBar({
    super.key,
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
                hintText: 'Search history',
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

class HistoryFilterBar extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const HistoryFilterBar({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  static const _filters = <(String, String)>[
    ('all', 'All'),
    ('added', 'Added'),
    ('edited', 'Edited'),
    ('sold', 'Sold'),
    ('installment', 'Installments'),
    ('payment', 'Payments'),
    ('deleted', 'Deleted'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = _filters[index];
          final value = filter.$1;
          final label = filter.$2;
          final selected = selectedValue == value;

          return ChoiceChip(
            selected: selected,
            label: Text(label),
            onSelected: (_) => onChanged(value),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? cs.onSecondaryContainer : cs.onSurface,
            ),
            backgroundColor: cs.surfaceContainerLow,
            selectedColor: cs.secondaryContainer,
            side: BorderSide(
              color: selected ? cs.secondaryContainer : cs.outlineVariant,
            ),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }
}