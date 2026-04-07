import 'package:flutter/material.dart';
import 'package:invenman/theme/app_sort_button.dart';
import 'package:invenman/theme/app_top_bar_buttons.dart';

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
                  child: AppTopBarIconButton(
                    onPressed: onActivateSearch,
                    icon: Icons.search_rounded,
                    tooltip: 'Search installments',
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
                : AppTopBarIconButton(
                    onPressed: onActivateSearch,
                    icon: Icons.search_rounded,
                    tooltip: 'Search installments',
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

  String _label(String value) {
    switch (value) {
      case 'next_due_desc':
        return 'Next Due Farthest';
      case 'customer':
        return 'Customer Name';
      case 'item':
        return 'Item Name';
      case 'status':
        return 'Plan Status';
      case 'latest':
        return 'Latest Created';
      case 'next_due_asc':
      default:
        return 'Next Due Soonest';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSortButton<String>(
      value: value,
      tooltip: 'Sort installment plans',
      labelBuilder: _label,
      onSelected: (selected) => onChanged(selected),
      items: const [
        PopupMenuItem(value: 'next_due_asc', child: Text('Next Due Soonest')),
        PopupMenuItem(value: 'next_due_desc', child: Text('Next Due Farthest')),
        PopupMenuItem(value: 'customer', child: Text('Customer Name')),
        PopupMenuItem(value: 'item', child: Text('Item Name')),
        PopupMenuItem(value: 'status', child: Text('Plan Status')),
        PopupMenuItem(value: 'latest', child: Text('Latest Created')),
      ],
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
                hintText: 'Search installments',
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