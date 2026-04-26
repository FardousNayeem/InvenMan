import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/database/app_database.dart';

class SaleRepository {
  const SaleRepository._();

  // ---------------------------------------------------------------------------
  // Transaction-scoped writes. Business workflows in actions.
  // ---------------------------------------------------------------------------

  static Future<int> insertSaleRecordTxn(
    sqflite.DatabaseExecutor executor,
    SaleRecord sale,
  ) {
    return executor.insert(
      'sale_records',
      sale.toMap(),
    );
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  static Future<List<SaleRecord>> fetchSaleRecords() async {
    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'sale_records',
      orderBy: 'sold_at DESC',
    );

    return maps.map(SaleRecord.fromMap).toList();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) async {
    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    return SaleRecord.fromMap(maps.first);
  }
}