import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/models/history.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';

class HistoryRepository {
  const HistoryRepository._();

  static Future<void> logHistory({
    required String itemName,
    required String action,
    required String details,
    Map<String, dynamic>? meta,
    sqflite.DatabaseExecutor? executor,
  }) async {
    final dbClient = executor ?? await AppDatabase.db;

    await dbClient.insert(
      'history_entries',
      HistoryEntry(
        itemName: itemName,
        action: action,
        details: details,
        createdAt: DbShared.nowUtc(),
        meta: meta,
      ).toMap(),
    );
  }

  static Future<List<HistoryEntry>> fetchHistoryEntries() async {
    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'history_entries',
      orderBy: 'created_at DESC',
    );

    return maps.map(HistoryEntry.fromMap).toList();
  }
}