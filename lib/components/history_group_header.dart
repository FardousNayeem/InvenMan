import 'package:flutter/material.dart';

import 'package:invenman/theme/app_ui.dart';

class HistoryGroupHeader extends StatelessWidget {
  final String title;

  const HistoryGroupHeader({
    super.key,
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