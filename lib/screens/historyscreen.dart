import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/components/history_top_controls.dart';
import 'package:invenman/components/history_group_header.dart';
import 'package:invenman/components/history_event_card.dart';
import 'package:invenman/components/history_insight_bar.dart';
import 'package:invenman/components/history_detail_presenter.dart';

import 'package:invenman/models/history.dart';
import 'package:invenman/services/db_services.dart';
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

  final DateFormat _dateFormat = DateFormat('d MMM yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

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

  bool get _isSortExpanded {
    return !_isSearchActive &&
        (_sortBy != _defaultSort || _filterBy != _defaultFilter);
  }

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

  String _dayLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(entryDay).inDays;

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
        return Colors.purple.shade700;
      case 'installment payment':
        return Colors.teal.shade700;
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
    }

    return sorted;
  }

  Map<String, List<HistoryEntry>> _groupEntries(
    List<HistoryEntry> entries,
  ) {
    final grouped = <String, List<HistoryEntry>>{};

    for (final entry in entries) {
      final key = _dayLabel(entry.createdAt);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(entry);
    }

    return grouped;
  }

  int _countAction(List<HistoryEntry> history, String action) {
    return history.where((entry) {
      return entry.action.toLowerCase() == action;
    }).length;
  }

  int _countToday(List<HistoryEntry> history) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return history.where((entry) {
      final local = entry.createdAt.toLocal();
      final entryDay = DateTime(local.year, local.month, local.day);

      return entryDay == today;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppUi.pageHPadding,
            AppUi.pageTopPadding,
            AppUi.pageHPadding,
            8,
          ),
          child: HistoryTopControls(
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

              final isSearching =
                  _searchQuery.isNotEmpty || _filterBy != _defaultFilter;

              if (history.isEmpty) {
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
                        child: HistoryInsightBar(
                          totalEvents: totalEvents,
                          todayCount: todayCount,
                          soldCount: soldCount,
                          editedCount: editedCount,
                          deletedCount: deletedCount,
                          isSearching: isSearching,
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
                            HistoryGroupHeader(title: group.key),
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
                                child: HistoryEventCard(
                                  entry: entry,
                                  icon: _eventIcon(entry.action),
                                  color: color,
                                  dateFormat: _dateFormat,
                                  timeFormat: _timeFormat,
                                  details: HistoryDetailPresenter(
                                    entry: entry,
                                  ),
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