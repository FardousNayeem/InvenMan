import 'dart:convert';

class HistoryEntry {
  final int? id;
  final String itemName;
  final String action;
  final String details;
  final DateTime createdAt;
  final Map<String, dynamic>? meta;

  HistoryEntry({
    this.id,
    required this.itemName,
    required this.action,
    required this.details,
    required this.createdAt,
    this.meta,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawMeta = map['meta'] as String?;

    Map<String, dynamic>? parsedMeta;
    if (rawMeta != null && rawMeta.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMeta);
        if (decoded is Map<String, dynamic>) {
          parsedMeta = decoded;
        }
      } catch (_) {
        parsedMeta = null;
      }
    }

    return HistoryEntry(
      id: map['id'] as int?,
      itemName: map['item_name'] as String,
      action: map['action'] as String,
      details: map['details'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      meta: parsedMeta,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'action': action,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'meta': meta == null ? null : jsonEncode(meta),
    };
  }

  HistoryEntry copyWith({
    int? id,
    String? itemName,
    String? action,
    String? details,
    DateTime? createdAt,
    Map<String, dynamic>? meta,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      action: action ?? this.action,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      meta: meta ?? this.meta,
    );
  }
}