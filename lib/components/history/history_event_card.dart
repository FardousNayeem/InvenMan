import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:invenman/models/history.dart';
import 'package:invenman/theme/app_ui.dart';

class HistoryEventCard extends StatefulWidget {
  final HistoryEntry entry;
  final IconData icon;
  final Color color;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final Widget details;
  final VoidCallback? onTap;

  const HistoryEventCard({
    super.key,
    required this.entry,
    required this.icon,
    required this.color,
    required this.dateFormat,
    required this.timeFormat,
    required this.details,
    this.onTap,
  });

  @override
  State<HistoryEventCard> createState() => _HistoryEventCardState();
}

class _HistoryEventCardState extends State<HistoryEventCard> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _isDangerAction {
    final action = widget.entry.action.toLowerCase();
    return action.contains('delete') || action.contains('removed');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final compact = MediaQuery.of(context).size.width < 720;
    final radius = compact ? 24.0 : 28.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.992 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(compact ? 14 : 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: _hovered
                      ? widget.color.withValues(alpha:0.35)
                      : cs.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: _hovered ? 24 : 18,
                    offset: Offset(0, _hovered ? 12 : 8),
                    color: Colors.black.withValues(alpha:_hovered ? 0.075 : 0.05),
                  ),
                ],
              ),
              child: compact
                  ? _buildCompactLayout(context)
                  : _buildWideLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _HistoryTimelineRail(
          icon: widget.icon,
          color: widget.color,
          isDangerAction: _isDangerAction,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HistoryCardHeader(
                entry: widget.entry,
                color: widget.color,
              ),
              const SizedBox(height: 12),
              widget.details,
            ],
          ),
        ),
        const SizedBox(width: 14),
        _HistoryTimestampPanel(
          createdAt: widget.entry.createdAt,
          dateFormat: widget.dateFormat,
          timeFormat: widget.timeFormat,
        ),
      ],
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _HistoryTimelineRail(
              icon: widget.icon,
              color: widget.color,
              isDangerAction: _isDangerAction,
              compact: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HistoryCardHeader(
                entry: widget.entry,
                color: widget.color,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        widget.details,
        const SizedBox(height: 12),
        _HistoryTimestampPanel(
          createdAt: widget.entry.createdAt,
          dateFormat: widget.dateFormat,
          timeFormat: widget.timeFormat,
          compact: true,
        ),
      ],
    );
  }
}

class _HistoryCardHeader extends StatelessWidget {
  final HistoryEntry entry;
  final Color color;
  final bool compact;

  const _HistoryCardHeader({
    required this.entry,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actionLabel = entry.action.trim().isEmpty ? 'Event' : entry.action;
    final itemName =
        entry.itemName.trim().isEmpty ? 'Unknown item' : entry.itemName;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.13),
            borderRadius: BorderRadius.circular(AppUi.pillRadius),
          ),
          child: Text(
            actionLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 12.5 : 13,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppUi.pillRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: compact ? 220 : 340,
                ),
                child: Text(
                  itemName,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13 : 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTimelineRail extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDangerAction;
  final bool compact;

  const _HistoryTimelineRail({
    required this.icon,
    required this.color,
    required this.isDangerAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 52.0;
    final iconSize = compact ? 22.0 : 24.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha:0.24),
            color.withValues(alpha:isDangerAction ? 0.17 : 0.12),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha:0.35),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: iconSize,
      ),
    );
  }
}

class _HistoryTimestampPanel extends StatelessWidget {
  final DateTime createdAt;
  final DateFormat dateFormat;
  final DateFormat timeFormat;
  final bool compact;

  const _HistoryTimestampPanel({
    required this.createdAt,
    required this.dateFormat,
    required this.timeFormat,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dateText = dateFormat.format(createdAt);
    final timeText = timeFormat.format(createdAt);

    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _TimeChip(
            icon: Icons.calendar_today_rounded,
            text: dateText,
          ),
          _TimeChip(
            icon: Icons.schedule_rounded,
            text: timeText,
          ),
        ],
      );
    }

    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha:0.78),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            dateText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TimeChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.1,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}