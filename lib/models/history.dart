class HistoryEntry {
  final int? id;
  final String itemName;
  final String action;
  final String details;
  final DateTime createdAt;

  HistoryEntry({
    this.id,
    required this.itemName,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int?,
      itemName: map['item_name'] as String,
      action: map['action'] as String,
      details: map['details'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'action': action,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }
}