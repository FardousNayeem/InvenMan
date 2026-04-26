import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:invenman/app/core/privacy_fields.dart';
import 'package:invenman/app/core/date_time_utils.dart';
import 'package:invenman/app/providers/privacy_provider.dart';
import 'package:invenman/models/history.dart';

class HistoryDetailPresenter extends StatelessWidget {
  final HistoryEntry entry;

  const HistoryDetailPresenter({
    super.key,
    required this.entry,
  });

  static const Set<String> _dateLabels = {
    'date',
    'paid date',
    'due date',
    'next due',
    'started',
    'start date',
    'sold at date',
  };

  bool get _isStructured {
    return entry.details.contains(':') && entry.details.contains(',');
  }

  bool _isSensitiveLabel(String label) {
    return PrivacyFields.isSensitiveLabel(label);
  }

  bool _isDateLabel(String label) {
    return _dateLabels.contains(label.trim().toLowerCase());
  }

  String _formatDisplayValue({
    required String label,
    required String value,
  }) {
    final trimmedValue = value.trim();

    if (!_isDateLabel(label)) {
      return trimmedValue;
    }

    final parsed = DateTime.tryParse(trimmedValue);

    if (parsed == null) {
      return trimmedValue;
    }

    return DateTimeUtils.compactDate(parsed);
  }

  List<_HistoryDetailRow> _parseRows({
    required bool hideSensitive,
  }) {
    final parts = entry.details
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.map((part) {
      final index = part.indexOf(':');

      if (index == -1) {
        return _HistoryDetailRow(
          label: '',
          value: _maskLooseText(
            part,
            hideSensitive: hideSensitive,
          ),
          isSensitive: false,
          hideWholeField: false,
        );
      }

      final label = part.substring(0, index).trim();
      final rawValue = part.substring(index + 1).trim();
      final sensitive = _isSensitiveLabel(label);

      if (sensitive && hideSensitive) {
        return const _HistoryDetailRow(
          label: '',
          value: '••••',
          isSensitive: true,
          hideWholeField: true,
        );
      }

      return _HistoryDetailRow(
        label: label,
        value: _formatDisplayValue(
          label: label,
          value: rawValue,
        ),
        isSensitive: sensitive,
        hideWholeField: false,
      );
    }).toList();
  }

  String _maskLooseText(
    String text, {
    required bool hideSensitive,
  }) {
    if (!hideSensitive) return _formatLooseDates(text);

    var masked = _formatLooseDates(text);

    final patterns = [
      RegExp(r'\bprofit\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(r'\bcost\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(r'\bsell\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(r'\bsold at\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(r'\bpaid\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(
        r'\bdown payment\b\s*:?\s*[-]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
      RegExp(
        r'\bmonthly approx\b\s*:?\s*[-]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
      RegExp(r'\bmonthly\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(
        r'\btotal amount\b\s*:?\s*[-]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
      RegExp(r'\btotal\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(r'\bfinanced\b\s*:?\s*[-]?\d+(\.\d+)?', caseSensitive: false),
      RegExp(
        r'\bremaining balance\b\s*:?\s*[-]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
      RegExp(
        r'\bremaining\b\s*:?\s*[-]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
      RegExp(
        r'\bcollected\b\s*:?\s*[-]?\d+(\.\d+)?',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      masked = masked.replaceAllMapped(pattern, (_) => '••••');
    }

    return masked;
  }

  String _formatLooseDates(String text) {
    final isoDatePattern = RegExp(
      r'\b\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z)?\b',
    );

    return text.replaceAllMapped(isoDatePattern, (match) {
      final raw = match.group(0);
      if (raw == null) return match.group(0) ?? '';

      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return raw;

      return DateTimeUtils.compactDate(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hideSensitive = context.watch<PrivacyProvider>().hideSensitiveValues;

    final rows = _isStructured
        ? _parseRows(hideSensitive: hideSensitive)
        : const <_HistoryDetailRow>[];

    if (rows.isEmpty) {
      return Text(
        _maskLooseText(
          entry.details,
          hideSensitive: hideSensitive,
        ),
        style: TextStyle(
          fontSize: 14.0,
          height: 1.45,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;

        final double maxChipWidth = compact
            ? double.infinity
            : math.min(
                math.max(constraints.maxWidth * 0.34, 180),
                300,
              );

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rows.map((row) {
            return _HistoryInfoChip(
              row: row,
              compact: compact,
              maxWidth: maxChipWidth,
            );
          }).toList(),
        );
      },
    );
  }
}

class _HistoryInfoChip extends StatelessWidget {
  final _HistoryDetailRow row;
  final bool compact;
  final double? maxWidth;

  const _HistoryInfoChip({
    required this.row,
    required this.compact,
    this.maxWidth,
  });

  bool get _isLooseOnly => row.hideWholeField || row.label.isEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: _isLooseOnly ? 78 : 116,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _isLooseOnly
              ? Text(
                  row.value,
                  style: TextStyle(
                    fontSize: compact ? 12.8 : 13.2,
                    height: 1.35,
                    color: row.isSensitive ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight:
                        row.isSensitive ? FontWeight.w700 : FontWeight.w600,
                  ),
                )
              : _ChipDetailLine(
                  label: row.label,
                  value: row.value,
                  compact: compact,
                ),
        ),
      ),
    );
  }
}

class _HistoryDetailRow {
  final String label;
  final String value;
  final bool isSensitive;
  final bool hideWholeField;

  const _HistoryDetailRow({
    required this.label,
    required this.value,
    required this.isSensitive,
    required this.hideWholeField,
  });
}

class _ChipDetailLine extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _ChipDetailLine({
    required this.label,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final labelStyle = TextStyle(
      fontSize: compact ? 12.0 : 12.6,
      fontWeight: FontWeight.w800,
      color: cs.onSurfaceVariant,
      height: 1.3,
    );

    final valueStyle = TextStyle(
      fontSize: compact ? 12.6 : 13.2,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
      height: 1.35,
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label: ', style: labelStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
    );
  }
}