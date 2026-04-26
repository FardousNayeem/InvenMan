import 'package:flutter/material.dart';

import 'package:invenman/theme/app_ui.dart';

class HistoryInsightBar extends StatelessWidget {
  final int totalEvents;
  final int todayCount;
  final int soldCount;
  final int editedCount;
  final int deletedCount;
  final bool isSearching;
  final int resultCount;

  const HistoryInsightBar({
    super.key,
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