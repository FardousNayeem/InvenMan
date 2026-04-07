import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/db.dart';
import 'package:invenman/models/history.dart';

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

  late Future<List<HistoryEntry>> _historyFuture;

  String _sortBy = _defaultSort;
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

  bool get _isSortExpanded => !_isSearchActive && _sortBy != _defaultSort;

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
      case 'deleted':
        return Icons.delete_rounded;
      default:
        return Icons.history_rounded;
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

  List<HistoryEntry> _applySort(List<HistoryEntry> entries) {
    final sorted = [...entries];

    switch (_sortBy) {
      case 'oldest':
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'action':
        sorted.sort((a, b) {
          final byAction = a.action.toLowerCase().compareTo(b.action.toLowerCase());
          if (byAction != 0) return byAction;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'item':
        sorted.sort((a, b) {
          final byName = a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
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

  LinkedHashMap<String, List<HistoryEntry>> _groupEntries(List<HistoryEntry> entries) {
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: _HistoryTopControls(
            sortBy: _sortBy,
            isSearchActive: _isSearchActive,
            isSortExpanded: _isSortExpanded,
            searchController: _searchController,
            onSortChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
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
              final searched = _applySearch(allHistory);
              final history = _applySort(searched);
              final grouped = _groupEntries(history);

              final totalEvents = allHistory.length;
              final todayCount = _countToday(allHistory);
              final soldCount = _countAction(allHistory, 'sold');
              final editedCount = _countAction(allHistory, 'edited');
              final deletedCount = _countAction(allHistory, 'deleted');

              if (history.isEmpty) {
                final isSearching = _searchQuery.isNotEmpty;

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      const SizedBox(height: 70),
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSearching
                              ? Icons.search_off_rounded
                              : Icons.history_toggle_off_rounded,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isSearching ? 'No matching activity found' : 'No history yet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          isSearching
                              ? 'Try searching by item, event type, or activity details.'
                              : 'Sales, edits, additions, and deletions will appear here as a clean activity timeline.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSearching)
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _cancelSearch,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Clear search'),
                          ),
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
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                        child: _HistoryInsightBar(
                          totalEvents: totalEvents,
                          todayCount: todayCount,
                          soldCount: soldCount,
                          editedCount: editedCount,
                          deletedCount: deletedCount,
                          isSearching: _searchQuery.isNotEmpty,
                          resultCount: history.length,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                                  bottom: index == group.value.length - 1 ? 18 : 12,
                                ),
                                child: _HistoryEventCard(
                                  entry: entry,
                                  color: color,
                                  icon: _eventIcon(entry.action),
                                  formattedDate: _formatDate(entry.createdAt),
                                  formattedTime: _formatTime(entry.createdAt),
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
  final bool isSearchActive;
  final bool isSortExpanded;
  final TextEditingController searchController;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onActivateSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCancelSearch;

  const _HistoryTopControls({
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

class _HistorySortControl extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _HistorySortControl({
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
            labelText: 'Sort history by',
            border: InputBorder.none,
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'latest', child: Text('Latest First')),
            DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
            DropdownMenuItem(value: 'action', child: Text('Action Type')),
            DropdownMenuItem(value: 'item', child: Text('Item Name')),
          ],
          onChanged: onChanged,
        ),
      ),
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
                hintText: 'Search item, action, or details',
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
          if (isSearching)
            _HistoryInsightNotice(resultCount: resultCount),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  label: 'Events',
                  value: '$totalEvents',
                  icon: Icons.history_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightTile(
                  label: 'Today',
                  value: '$todayCount',
                  icon: Icons.today_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  label: 'Sold',
                  value: '$soldCount',
                  icon: Icons.point_of_sale_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InsightTile(
                  label: 'Edited',
                  value: '$editedCount',
                  icon: Icons.edit_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InsightTile(
                  label: 'Deleted',
                  value: '$deletedCount',
                  icon: Icons.delete_rounded,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _InsightTile(
            label: 'Events',
            value: '$totalEvents',
            icon: Icons.history_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            label: 'Today',
            value: '$todayCount',
            icon: Icons.today_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            label: 'Sold',
            value: '$soldCount',
            icon: Icons.point_of_sale_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightTile(
            label: isSearching ? 'Results' : 'Edited',
            value: isSearching ? '$resultCount' : '$editedCount',
            icon: isSearching ? Icons.search_rounded : Icons.edit_rounded,
          ),
        ),
        if (!isSearching) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
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

class _HistoryInsightNotice extends StatelessWidget {
  final int resultCount;

  const _HistoryInsightNotice({
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, size: 18, color: cs.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$resultCount result${resultCount == 1 ? '' : 's'} found',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InsightTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: Colors.black.withOpacity(0.035),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
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

  const _HistoryEventCard({
    required this.entry,
    required this.color,
    required this.icon,
    required this.formattedDate,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 760;

    if (compact) {
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.25,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
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
              Text(
                entry.details,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 2,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
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
                  Text(
                    entry.details,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 130, maxWidth: 170),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.8),
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
                        letterSpacing: 0.4,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('d MMM yyyy').format(entry.createdAt.toLocal()),
                      style: TextStyle(
                        fontSize: 12.5,
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
      ),
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