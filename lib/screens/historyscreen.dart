import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:invenman/db.dart';
import 'package:invenman/main.dart';
import 'package:invenman/models/history.dart';
import 'package:invenman/theme/app_sort_button.dart';
import 'package:invenman/theme/app_top_bar_buttons.dart';
import 'package:invenman/theme/app_ui.dart';

class HistoryPage extends StatefulWidget {
  final int refreshToken;

  const HistoryPage({
    super.key,
    required this.refreshToken,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const String _defaultSort = 'latest';
  static const String _defaultFilter = 'all';

  late Future<List<HistoryEntry>> _historyFuture;

  String _sortBy = _defaultSort;
  String _filterBy = _defaultFilter;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      setState(_loadHistory);
    }
  }

  void _loadHistory() {
    _historyFuture = DBHelper.fetchHistoryEntries();
  }

  Future<void> _refresh() async {
    setState(_loadHistory);
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  bool get _isSortExpanded =>
      !_isSearchActive && (_sortBy != _defaultSort || _filterBy != _defaultFilter);

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
      _filterBy = _defaultFilter;
      _loadHistory();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy • h:mm a').format(date.toLocal());
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date.toLocal());
  }

  String _dayLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(thatDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE • d MMM yyyy').format(local);
  }

  Color _eventColor(String action) {
    switch (action.toLowerCase()) {
      case 'added':
        return Colors.green.shade700;
      case 'edited':
        return Colors.orange.shade700;
      case 'sold':
        return Colors.blue.shade700;
      case 'installment':
      case 'installment payment':
        return Colors.purple.shade700;
      case 'deleted':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _eventIcon(String action) {
    switch (action.toLowerCase()) {
      case 'added':
        return Icons.add_box_rounded;
      case 'edited':
        return Icons.edit_rounded;
      case 'sold':
        return Icons.point_of_sale_rounded;
      case 'installment':
        return Icons.calendar_month_rounded;
      case 'installment payment':
        return Icons.payments_rounded;
      case 'deleted':
        return Icons.delete_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String _actionFilterValue(String action) {
    switch (action.toLowerCase()) {
      case 'added':
        return 'added';
      case 'edited':
        return 'edited';
      case 'sold':
        return 'sold';
      case 'installment':
        return 'installment';
      case 'installment payment':
        return 'payment';
      case 'deleted':
        return 'deleted';
      default:
        return 'other';
    }
  }

  List<HistoryEntry> _applySearch(List<HistoryEntry> entries) {
    if (_searchQuery.isEmpty) return entries;

    return entries.where((entry) {
      return entry.itemName.toLowerCase().contains(_searchQuery) ||
          entry.action.toLowerCase().contains(_searchQuery) ||
          entry.details.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<HistoryEntry> _applyFilter(List<HistoryEntry> entries) {
    if (_filterBy == _defaultFilter) return entries;

    return entries.where((entry) {
      return _actionFilterValue(entry.action) == _filterBy;
    }).toList();
  }

  List<HistoryEntry> _applySort(List<HistoryEntry> entries) {
    final sorted = [...entries];

    switch (_sortBy) {
      case 'oldest':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'action':
        sorted.sort((a, b) {
          final byAction =
              a.action.toLowerCase().compareTo(b.action.toLowerCase());
          if (byAction != 0) return byAction;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'item':
        sorted.sort((a, b) {
          final byName =
              a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
          if (byName != 0) return byName;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'latest':
      default:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sorted;
  }

  LinkedHashMap<String, List<HistoryEntry>> _groupEntries(
    List<HistoryEntry> entries,
  ) {
    final grouped = LinkedHashMap<String, List<HistoryEntry>>();

    for (final entry in entries) {
      final key = _dayLabel(entry.createdAt);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(entry);
    }

    return grouped;
  }

  int _countAction(List<HistoryEntry> history, String action) {
    return history.where((entry) => entry.action.toLowerCase() == action).length;
  }

  int _countToday(List<HistoryEntry> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return history.where((entry) {
      final local = entry.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      return day == today;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final privacyProvider = context.watch<PrivacyProvider>();
    final hideSensitive = privacyProvider.hideSensitiveValues;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppUi.pageHPadding,
            AppUi.pageTopPadding,
            AppUi.pageHPadding,
            8,
          ),
          child: _HistoryTopControls(
            sortBy: _sortBy,
            filterBy: _filterBy,
            isSearchActive: _isSearchActive,
            isSortExpanded: _isSortExpanded,
            searchController: _searchController,
            onSortChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
              });
            },
            onFilterChanged: (value) {
              setState(() {
                _filterBy = value;
              });
            },
            onActivateSearch: _activateSearch,
            onSearchChanged: (_) => setState(() {}),
            onCancelSearch: _cancelSearch,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<HistoryEntry>>(
            future: _historyFuture,
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

              final allHistory = snapshot.data ?? [];
              final filtered = _applyFilter(allHistory);
              final searched = _applySearch(filtered);
              final history = _applySort(searched);
              final grouped = _groupEntries(history);

              final totalEvents = allHistory.length;
              final todayCount = _countToday(allHistory);
              final soldCount = _countAction(allHistory, 'sold');
              final editedCount = _countAction(allHistory, 'edited');
              final deletedCount = _countAction(allHistory, 'deleted');

              if (history.isEmpty) {
                final isSearching = _searchQuery.isNotEmpty || _filterBy != _defaultFilter;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppUi.pageHPadding,
                      8,
                      AppUi.pageHPadding,
                      AppUi.pageBottomPadding,
                    ),
                    children: [
                      AppEmptyState(
                        icon: isSearching
                            ? Icons.search_off_rounded
                            : Icons.history_toggle_off_rounded,
                        title: isSearching
                            ? 'No matching activity found'
                            : 'No history yet',
                        message: isSearching
                            ? 'Try another event type, item name, or search phrase.'
                            : 'Sales, edits, additions, deletions, and installment updates will appear here as one clean timeline.',
                        action: isSearching
                            ? OutlinedButton.icon(
                                onPressed: _cancelSearch,
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Clear filters'),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  key: const PageStorageKey('history_list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppUi.pageHPadding,
                          2,
                          AppUi.pageHPadding,
                          12,
                        ),
                        child: _HistoryInsightBar(
                          totalEvents: totalEvents,
                          todayCount: todayCount,
                          soldCount: soldCount,
                          editedCount: editedCount,
                          deletedCount: deletedCount,
                          isSearching:
                              _searchQuery.isNotEmpty || _filterBy != _defaultFilter,
                          resultCount: history.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppUi.pageHPadding,
                        0,
                        AppUi.pageHPadding,
                        AppUi.pageBottomPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          for (final group in grouped.entries) ...[
                            _HistoryGroupHeader(title: group.key),
                            const SizedBox(height: 10),
                            ...List.generate(group.value.length, (index) {
                              final entry = group.value[index];
                              final color = _eventColor(entry.action);

                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == group.value.length - 1
                                      ? 18
                                      : AppUi.listGap,
                                ),
                                child: _HistoryEventCard(
                                  entry: entry,
                                  color: color,
                                  icon: _eventIcon(entry.action),
                                  formattedDate: _formatDate(entry.createdAt),
                                  formattedTime: _formatTime(entry.createdAt),
                                  hideSensitive: hideSensitive,
                                ),
                              );
                            }),
                          ],
                        ]),
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

class _HistoryTopControls extends StatelessWidget {
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

  const _HistoryTopControls({
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
                    child: _HistorySortControl(
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
              child: _HistorySearchBar(
                controller: searchController,
                onChanged: onSearchChanged,
                onClear: onCancelSearch,
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: rowHeight,
              child: _HistorySortControl(
                value: sortBy,
                onChanged: onSortChanged,
              ),
            ),
          ],
          SizedBox(height: gap),
          _HistoryFilterBar(
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
                child: _HistorySortControl(
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
                    ? _HistorySearchBar(
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
        _HistoryFilterBar(
          selectedValue: filterBy,
          onChanged: onFilterChanged,
        ),
      ],
    );
  }
}

class _HistorySortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _HistorySortControl({
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

class _HistorySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _HistorySearchBar({
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

class _HistoryFilterBar extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _HistoryFilterBar({
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

class _HistoryInsightBar extends StatelessWidget {
  final int totalEvents;
  final int todayCount;
  final int soldCount;
  final int editedCount;
  final int deletedCount;
  final bool isSearching;
  final int resultCount;

  const _HistoryInsightBar({
    required this.totalEvents,
    required this.todayCount,
    required this.soldCount,
    required this.editedCount,
    required this.deletedCount,
    required this.isSearching,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;

    if (compact) {
      return Column(
        children: [
          if (isSearching) AppSearchNotice(resultCount: resultCount),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Events',
                  value: '$totalEvents',
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppInsightTile(
                  label: 'Today',
                  value: '$todayCount',
                  icon: Icons.today_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Sold',
                  value: '$soldCount',
                  icon: Icons.point_of_sale_rounded,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              Expanded(
                child: AppInsightTile(
                  label: 'Edited',
                  value: '$editedCount',
                  icon: Icons.edit_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppUi.tileGap),
          Row(
            children: [
              Expanded(
                child: AppInsightTile(
                  label: 'Deleted',
                  value: '$deletedCount',
                  icon: Icons.delete_rounded,
                ),
              ),
              const SizedBox(width: AppUi.tileGap),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppInsightTile(
            label: 'Events',
            value: '$totalEvents',
            icon: Icons.history_rounded,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: 'Today',
            value: '$todayCount',
            icon: Icons.today_rounded,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: 'Sold',
            value: '$soldCount',
            icon: Icons.point_of_sale_rounded,
          ),
        ),
        const SizedBox(width: AppUi.tileGap),
        Expanded(
          child: AppInsightTile(
            label: isSearching ? 'Results' : 'Edited',
            value: isSearching ? '$resultCount' : '$editedCount',
            icon: isSearching ? Icons.search_rounded : Icons.edit_rounded,
          ),
        ),
        if (!isSearching) ...[
          const SizedBox(width: AppUi.tileGap),
          Expanded(
            child: AppInsightTile(
              label: 'Deleted',
              value: '$deletedCount',
              icon: Icons.delete_rounded,
            ),
          ),
        ],
      ],
    );
  }
}

class _HistoryGroupHeader extends StatelessWidget {
  final String title;

  const _HistoryGroupHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppUi.pillRadius),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.3,
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  final HistoryEntry entry;
  final Color color;
  final IconData icon;
  final String formattedDate;
  final String formattedTime;
  final bool hideSensitive;

  const _HistoryEventCard({
    required this.entry,
    required this.color,
    required this.icon,
    required this.formattedDate,
    required this.formattedTime,
    required this.hideSensitive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 760;

    final detailPresenter = _HistoryDetailPresenter(
      entry: entry,
      hideSensitive: hideSensitive,
    );

    if (compact) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Text(
                        entry.itemName,
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppUi.pillRadius),
                        ),
                        child: Text(
                          entry.action,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            detailPresenter.buildCompact(context),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _MetaPill(
                  icon: Icons.access_time_rounded,
                  label: formattedTime,
                ),
                _MetaPill(
                  icon: Icons.event_outlined,
                  label: formattedDate,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Container(
                width: 2,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.outlineVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(AppUi.pillRadius),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      entry.itemName,
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppUi.pillRadius),
                      ),
                      child: Text(
                        entry.action,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                detailPresenter.buildWide(context),
              ],
            ),
          ),
          const SizedBox(width: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 126, maxWidth: 164),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.82),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event time',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('d MMM yyyy').format(entry.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 12.3,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDetailPresenter {
  final HistoryEntry entry;
  final bool hideSensitive;

  const _HistoryDetailPresenter({
    required this.entry,
    required this.hideSensitive,
  });

  static const Set<String> _sensitiveLabels = {
    'cost',
    'sell',
    'profit',
    'down payment',
    'paid',
    'financed',
    'monthly approx',
    'total',
  };

  bool get _isStructured {
    return entry.details.contains(':') && entry.details.contains(',');
  }

  List<_HistoryDetailRow> _parseRows() {
    final parts = entry.details
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return parts.map((part) {
      final index = part.indexOf(':');
      if (index == -1) {
        return _HistoryDetailRow(
          label: '',
          value: _maskLooseText(part),
          isSensitive: false,
        );
      }

      final label = part.substring(0, index).trim();
      final rawValue = part.substring(index + 1).trim();
      final sensitive = _sensitiveLabels.contains(label.toLowerCase());

      return _HistoryDetailRow(
        label: label,
        value: sensitive && hideSensitive ? '••••' : rawValue,
        isSensitive: sensitive,
      );
    }).toList();
  }

  String _maskLooseText(String text) {
    if (!hideSensitive) return text;

    var masked = text;
    final patterns = [
      RegExp(r'(?i)\bprofit\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\bcost\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\bsell\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\bpaid\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\bdown payment\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\bmonthly approx\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\btotal\b\s*:?\s*\d+(\.\d+)?'),
      RegExp(r'(?i)\bfinanced\b\s*:?\s*\d+(\.\d+)?'),
    ];

    for (final pattern in patterns) {
      masked = masked.replaceAllMapped(pattern, (m) {
        final matched = m.group(0)!;
        final colonIndex = matched.indexOf(':');
        if (colonIndex == -1) return matched;
        return '${matched.substring(0, colonIndex + 1)} ••••';
      });
    }

    return masked;
  }

  Widget buildCompact(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = _isStructured ? _parseRows() : const <_HistoryDetailRow>[];

    if (rows.isEmpty) {
      return Text(
        _maskLooseText(entry.details),
        style: TextStyle(
          fontSize: 14.25,
          height: 1.5,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      children: rows.map((row) {
        if (row.label.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                row.value,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _StructuredDetailLine(
            label: row.label,
            value: row.value,
          ),
        );
      }).toList(),
    );
  }

  Widget buildWide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = _isStructured ? _parseRows() : const <_HistoryDetailRow>[];

    if (rows.isEmpty) {
      return Text(
        _maskLooseText(entry.details),
        style: TextStyle(
          fontSize: 14.25,
          height: 1.5,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: rows.map((row) {
        if (row.label.isEmpty) {
          return Container(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              row.value,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final width = row.label.length > 10 ? 280.0 : 220.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: math.min(width, 220),
            maxWidth: math.max(width, 220),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _StructuredDetailLine(
              label: row.label,
              value: row.value,
              compactTypography: true,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _HistoryDetailRow {
  final String label;
  final String value;
  final bool isSensitive;

  const _HistoryDetailRow({
    required this.label,
    required this.value,
    required this.isSensitive,
  });
}

class _StructuredDetailLine extends StatelessWidget {
  final String label;
  final String value;
  final bool compactTypography;

  const _StructuredDetailLine({
    required this.label,
    required this.value,
    this.compactTypography = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelWidth = compactTypography ? 110.0 : 120.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: compactTypography ? 12.0 : 13.0,
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: compactTypography ? 12.8 : 13.6,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}