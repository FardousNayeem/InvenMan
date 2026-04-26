import 'package:sqflite/sqflite.dart' as sqflite;

typedef NowIsoString = String Function();
typedef NormalizeExistingInstallmentValues = Future<void> Function(
  sqflite.DatabaseExecutor db,
);

Future<void> createDbTables(sqflite.Database db) async {
  await db.execute('''
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL,
      brand TEXT NOT NULL DEFAULT '',
      colors_json TEXT NOT NULL DEFAULT '[]',
      cost_price REAL NOT NULL,
      selling_price REAL NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity >= 0),
      supplier TEXT NOT NULL DEFAULT '',
      warranties_json TEXT NOT NULL DEFAULT '{}',
      image_paths_json TEXT NOT NULL DEFAULT '[]',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE sale_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_id INTEGER,
      item_name TEXT NOT NULL,
      category TEXT NOT NULL,
      quantity_sold INTEGER NOT NULL CHECK (quantity_sold > 0),
      cost_price REAL NOT NULL,
      sell_price REAL NOT NULL,
      profit REAL NOT NULL,
      customer_name TEXT,
      customer_phone TEXT,
      customer_address TEXT,
      payment_type TEXT NOT NULL DEFAULT 'direct'
        CHECK (payment_type IN ('direct', 'installment')),
      installment_months INTEGER
        CHECK (installment_months IS NULL OR installment_months > 0),
      sold_colors_json TEXT NOT NULL DEFAULT '[]',
      installment_image_paths_json TEXT NOT NULL DEFAULT '[]',
      warranties_json TEXT NOT NULL DEFAULT '{}',
      sold_at TEXT NOT NULL,
      CHECK (
        (payment_type = 'direct' AND installment_months IS NULL) OR
        (payment_type = 'installment' AND installment_months IS NOT NULL)
      ),
      FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE installment_plans (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sale_record_id INTEGER NOT NULL,
      item_name TEXT NOT NULL,
      category TEXT NOT NULL,
      customer_name TEXT,
      customer_phone TEXT,
      customer_address TEXT,
      image_paths_json TEXT NOT NULL DEFAULT '[]',
      total_amount REAL NOT NULL CHECK (total_amount >= 0),
      down_payment REAL NOT NULL CHECK (down_payment >= 0),
      financed_amount REAL NOT NULL CHECK (financed_amount >= 0),
      duration_months INTEGER NOT NULL CHECK (duration_months > 0),
      monthly_amount REAL NOT NULL CHECK (monthly_amount >= 0),
      start_date TEXT NOT NULL,
      next_due_date TEXT,
      paid_months INTEGER NOT NULL DEFAULT 0 CHECK (paid_months >= 0),
      remaining_months INTEGER NOT NULL CHECK (remaining_months >= 0),
      total_paid REAL NOT NULL DEFAULT 0 CHECK (total_paid >= 0),
      remaining_balance REAL NOT NULL CHECK (remaining_balance >= 0),
      status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'overdue')),
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (sale_record_id) REFERENCES sale_records(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE installment_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      installment_plan_id INTEGER NOT NULL,
      installment_number INTEGER NOT NULL CHECK (installment_number > 0),
      due_date TEXT NOT NULL,
      paid_date TEXT,
      amount_due REAL NOT NULL CHECK (amount_due >= 0),
      amount_paid REAL NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
      status TEXT NOT NULL CHECK (status IN ('pending', 'partial', 'paid', 'overdue')),
      note TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (installment_plan_id) REFERENCES installment_plans(id) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE history_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_name TEXT NOT NULL,
      action TEXT NOT NULL,
      details TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
}

Future<void> ensureDbIndexes(sqflite.DatabaseExecutor db) async {
  await _ensureIndex(
    db,
    'idx_items_name',
    'CREATE INDEX idx_items_name ON items(name)',
  );
  await _ensureIndex(
    db,
    'idx_items_category',
    'CREATE INDEX idx_items_category ON items(category)',
  );
  await _ensureIndex(
    db,
    'idx_items_brand',
    'CREATE INDEX idx_items_brand ON items(brand)',
  );
  await _ensureIndex(
    db,
    'idx_items_supplier',
    'CREATE INDEX idx_items_supplier ON items(supplier)',
  );
  await _ensureIndex(
    db,
    'idx_items_updated_at',
    'CREATE INDEX idx_items_updated_at ON items(updated_at)',
  );

  await _ensureIndex(
    db,
    'idx_sale_records_item_id',
    'CREATE INDEX idx_sale_records_item_id ON sale_records(item_id)',
  );
  await _ensureIndex(
    db,
    'idx_sale_records_category',
    'CREATE INDEX idx_sale_records_category ON sale_records(category)',
  );
  await _ensureIndex(
    db,
    'idx_sale_records_sold_at',
    'CREATE INDEX idx_sale_records_sold_at ON sale_records(sold_at)',
  );

  await _ensureIndex(
    db,
    'idx_installment_plans_status',
    'CREATE INDEX idx_installment_plans_status ON installment_plans(status)',
  );
  await _ensureIndex(
    db,
    'idx_installment_plans_next_due_date',
    'CREATE INDEX idx_installment_plans_next_due_date ON installment_plans(next_due_date)',
  );
  await _ensureIndex(
    db,
    'idx_installment_plans_customer_name',
    'CREATE INDEX idx_installment_plans_customer_name ON installment_plans(customer_name)',
  );
  await _ensureIndex(
    db,
    'idx_installment_plans_sale_record_id',
    'CREATE INDEX idx_installment_plans_sale_record_id ON installment_plans(sale_record_id)',
  );

  await _ensureIndex(
    db,
    'idx_installment_payments_plan_id',
    'CREATE INDEX idx_installment_payments_plan_id ON installment_payments(installment_plan_id)',
  );
  await _ensureIndex(
    db,
    'idx_installment_payments_due_date',
    'CREATE INDEX idx_installment_payments_due_date ON installment_payments(due_date)',
  );
  await _ensureIndex(
    db,
    'idx_installment_payments_status',
    'CREATE INDEX idx_installment_payments_status ON installment_payments(status)',
  );

  await _ensureIndex(
    db,
    'idx_history_entries_created_at',
    'CREATE INDEX idx_history_entries_created_at ON history_entries(created_at)',
  );
}

Future<void> runDbMigrations(
  sqflite.Database db,
  int oldVersion,
  int newVersion, {
  required NowIsoString nowIsoString,
  required NormalizeExistingInstallmentValues normalizeExistingInstallmentValues,
}) async {
  if (oldVersion < 10) {
    await _migrateToV10(
      db,
      nowIsoString: nowIsoString,
      normalizeExistingInstallmentValues: normalizeExistingInstallmentValues,
    );
  }

  if (oldVersion < 11) {
    await _migrateToV11(
      db,
      nowIsoString: nowIsoString,
      normalizeExistingInstallmentValues: normalizeExistingInstallmentValues,
    );
  }

  if (oldVersion < 12) {
    await _migrateToV12(db);
  }

  await ensureDbIndexes(db);
}

Future<void> _migrateToV10(
  sqflite.Database db, {
  required NowIsoString nowIsoString,
  required NormalizeExistingInstallmentValues normalizeExistingInstallmentValues,
}) async {
  await db.transaction((txn) async {
    final hasItems = await _tableExists(txn, 'items');
    if (!hasItems) {
      await txn.execute('''
        CREATE TABLE items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          category TEXT NOT NULL,
          brand TEXT NOT NULL DEFAULT '',
          colors_json TEXT NOT NULL DEFAULT '[]',
          cost_price REAL NOT NULL,
          selling_price REAL NOT NULL,
          quantity INTEGER NOT NULL CHECK (quantity >= 0),
          supplier TEXT NOT NULL DEFAULT '',
          warranties_json TEXT NOT NULL DEFAULT '{}',
          image_paths_json TEXT NOT NULL DEFAULT '[]',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    } else {
      await _ensureColumn(txn, 'items', 'description', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(txn, 'items', 'brand', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(txn, 'items', 'colors_json', "TEXT NOT NULL DEFAULT '[]'");
      await _ensureColumn(txn, 'items', 'supplier', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(txn, 'items', 'warranties_json', "TEXT NOT NULL DEFAULT '{}'");
      await _ensureColumn(txn, 'items', 'image_paths_json', "TEXT NOT NULL DEFAULT '[]'");
      await _ensureColumn(txn, 'items', 'created_at', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(txn, 'items', 'updated_at', "TEXT NOT NULL DEFAULT ''");
    }

    final hasSaleRecords = await _tableExists(txn, 'sale_records');
    if (!hasSaleRecords) {
      await txn.execute('''
        CREATE TABLE sale_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER,
          item_name TEXT NOT NULL,
          category TEXT NOT NULL,
          quantity_sold INTEGER NOT NULL CHECK (quantity_sold > 0),
          cost_price REAL NOT NULL,
          sell_price REAL NOT NULL,
          profit REAL NOT NULL,
          customer_name TEXT,
          customer_phone TEXT,
          customer_address TEXT,
          payment_type TEXT NOT NULL DEFAULT 'direct'
            CHECK (payment_type IN ('direct', 'installment')),
          installment_months INTEGER
            CHECK (installment_months IS NULL OR installment_months > 0),
          sold_colors_json TEXT NOT NULL DEFAULT '[]',
          installment_image_paths_json TEXT NOT NULL DEFAULT '[]',
          warranties_json TEXT NOT NULL DEFAULT '{}',
          sold_at TEXT NOT NULL,
          CHECK (
            (payment_type = 'direct' AND installment_months IS NULL) OR
            (payment_type = 'installment' AND installment_months IS NOT NULL)
          ),
          FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE SET NULL
        )
      ''');
    } else {
      await _ensureColumn(txn, 'sale_records', 'item_id', 'INTEGER');
      await _ensureColumn(txn, 'sale_records', 'customer_name', 'TEXT');
      await _ensureColumn(txn, 'sale_records', 'customer_phone', 'TEXT');
      await _ensureColumn(txn, 'sale_records', 'customer_address', 'TEXT');
      await _ensureColumn(
        txn,
        'sale_records',
        'payment_type',
        "TEXT NOT NULL DEFAULT 'direct'",
      );
      await _ensureColumn(txn, 'sale_records', 'installment_months', 'INTEGER');
      await _ensureColumn(
        txn,
        'sale_records',
        'sold_colors_json',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _ensureColumn(
        txn,
        'sale_records',
        'installment_image_paths_json',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _ensureColumn(
        txn,
        'sale_records',
        'warranties_json',
        "TEXT NOT NULL DEFAULT '{}'",
      );
      await _ensureColumn(txn, 'sale_records', 'sold_at', "TEXT NOT NULL DEFAULT ''");
    }

    final hasInstallmentPlans = await _tableExists(txn, 'installment_plans');
    if (!hasInstallmentPlans) {
      await txn.execute('''
        CREATE TABLE installment_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_record_id INTEGER NOT NULL,
          item_name TEXT NOT NULL,
          category TEXT NOT NULL,
          customer_name TEXT,
          customer_phone TEXT,
          customer_address TEXT,
          image_paths_json TEXT NOT NULL DEFAULT '[]',
          total_amount REAL NOT NULL CHECK (total_amount >= 0),
          down_payment REAL NOT NULL CHECK (down_payment >= 0),
          financed_amount REAL NOT NULL CHECK (financed_amount >= 0),
          duration_months INTEGER NOT NULL CHECK (duration_months > 0),
          monthly_amount REAL NOT NULL CHECK (monthly_amount >= 0),
          start_date TEXT NOT NULL,
          next_due_date TEXT,
          paid_months INTEGER NOT NULL DEFAULT 0 CHECK (paid_months >= 0),
          remaining_months INTEGER NOT NULL CHECK (remaining_months >= 0),
          total_paid REAL NOT NULL DEFAULT 0 CHECK (total_paid >= 0),
          remaining_balance REAL NOT NULL CHECK (remaining_balance >= 0),
          status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'overdue')),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (sale_record_id) REFERENCES sale_records(id) ON DELETE CASCADE
        )
      ''');
    } else {
      await _ensureColumn(txn, 'installment_plans', 'customer_name', 'TEXT');
      await _ensureColumn(txn, 'installment_plans', 'customer_phone', 'TEXT');
      await _ensureColumn(txn, 'installment_plans', 'customer_address', 'TEXT');
      await _ensureColumn(
        txn,
        'installment_plans',
        'image_paths_json',
        "TEXT NOT NULL DEFAULT '[]'",
      );
      await _ensureColumn(txn, 'installment_plans', 'next_due_date', 'TEXT');
      await _ensureColumn(
        txn,
        'installment_plans',
        'paid_months',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _ensureColumn(
        txn,
        'installment_plans',
        'total_paid',
        'REAL NOT NULL DEFAULT 0',
      );
      await _ensureColumn(txn, 'installment_plans', 'created_at', "TEXT NOT NULL DEFAULT ''");
      await _ensureColumn(txn, 'installment_plans', 'updated_at', "TEXT NOT NULL DEFAULT ''");
    }

    final hasInstallmentPayments = await _tableExists(txn, 'installment_payments');
    if (!hasInstallmentPayments) {
      await txn.execute('''
        CREATE TABLE installment_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          installment_plan_id INTEGER NOT NULL,
          installment_number INTEGER NOT NULL CHECK (installment_number > 0),
          due_date TEXT NOT NULL,
          paid_date TEXT,
          amount_due REAL NOT NULL CHECK (amount_due >= 0),
          amount_paid REAL NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
          status TEXT NOT NULL CHECK (status IN ('pending', 'partial', 'paid', 'overdue')),
          note TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (installment_plan_id) REFERENCES installment_plans(id) ON DELETE CASCADE
        )
      ''');
    } else {
      await _ensureColumn(txn, 'installment_payments', 'paid_date', 'TEXT');
      await _ensureColumn(
        txn,
        'installment_payments',
        'amount_paid',
        'REAL NOT NULL DEFAULT 0',
      );
      await _ensureColumn(txn, 'installment_payments', 'note', 'TEXT');
      await _ensureColumn(
        txn,
        'installment_payments',
        'created_at',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _ensureColumn(
        txn,
        'installment_payments',
        'updated_at',
        "TEXT NOT NULL DEFAULT ''",
      );
    }

    final hasHistoryEntries = await _tableExists(txn, 'history_entries');
    if (!hasHistoryEntries) {
      await txn.execute('''
        CREATE TABLE history_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_name TEXT NOT NULL,
          action TEXT NOT NULL,
          details TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    await _backfillMissingTimestamps(txn, nowIsoString);
    await normalizeExistingInstallmentValues(txn);
  });
}

Future<void> _migrateToV11(
  sqflite.Database db, {
  required NowIsoString nowIsoString,
  required NormalizeExistingInstallmentValues normalizeExistingInstallmentValues,
}) async {
  await db.transaction((txn) async {
    await _ensureColumn(txn, 'items', 'brand', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(txn, 'items', 'colors_json', "TEXT NOT NULL DEFAULT '[]'");
    await _ensureColumn(
      txn,
      'sale_records',
      'installment_image_paths_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );

    await _backfillMissingTimestamps(txn, nowIsoString);

    await txn.execute("""
      UPDATE items
      SET brand = COALESCE(brand, '')
      WHERE brand IS NULL
    """);

    await txn.execute("""
      UPDATE items
      SET colors_json = '[]'
      WHERE colors_json IS NULL OR colors_json = ''
    """);

    await txn.execute("""
      UPDATE sale_records
      SET installment_image_paths_json = '[]'
      WHERE installment_image_paths_json IS NULL OR installment_image_paths_json = ''
    """);

    await txn.execute("""
      UPDATE installment_plans
      SET image_paths_json = '[]'
      WHERE image_paths_json IS NULL OR image_paths_json = ''
    """);

    final saleMaps = await txn.query(
      'sale_records',
      columns: ['id', 'installment_image_paths_json'],
      where: "payment_type = 'installment'",
    );

    for (final saleMap in saleMaps) {
      final saleId = saleMap['id'] as int?;
      if (saleId == null) continue;

      final imagesJson =
          saleMap['installment_image_paths_json'] as String? ?? '[]';

      final planMaps = await txn.query(
        'installment_plans',
        columns: ['id', 'image_paths_json'],
        where: 'sale_record_id = ?',
        whereArgs: [saleId],
        limit: 1,
      );

      if (planMaps.isEmpty) continue;

      final planId = planMaps.first['id'] as int?;
      if (planId == null) continue;

      final existingPlanImages =
          planMaps.first['image_paths_json'] as String? ?? '[]';

      if ((existingPlanImages.isEmpty || existingPlanImages == '[]') &&
          imagesJson.isNotEmpty) {
        await txn.update(
          'installment_plans',
          {
            'image_paths_json': imagesJson,
            'updated_at': nowIsoString(),
          },
          where: 'id = ?',
          whereArgs: [planId],
        );
      }
    }

    await normalizeExistingInstallmentValues(txn);
  });
}

Future<void> _migrateToV12(sqflite.Database db) async {
  await db.transaction((txn) async {
    await _ensureColumn(
      txn,
      'sale_records',
      'sold_colors_json',
      "TEXT NOT NULL DEFAULT '[]'",
    );

    await txn.execute("""
      UPDATE sale_records
      SET sold_colors_json = '[]'
      WHERE sold_colors_json IS NULL OR sold_colors_json = ''
    """);
  });
}

Future<void> _backfillMissingTimestamps(
  sqflite.DatabaseExecutor db,
  NowIsoString nowIsoString,
) async {
  final nowIso = nowIsoString();

  await db.execute("""
    UPDATE items
    SET created_at = COALESCE(NULLIF(created_at, ''), ?),
        updated_at = COALESCE(NULLIF(updated_at, ''), COALESCE(NULLIF(created_at, ''), ?))
    WHERE created_at IS NULL OR created_at = '' OR updated_at IS NULL OR updated_at = ''
  """, [nowIso, nowIso]);

  await db.execute("""
    UPDATE sale_records
    SET sold_at = COALESCE(NULLIF(sold_at, ''), ?)
    WHERE sold_at IS NULL OR sold_at = ''
  """, [nowIso]);

  await db.execute("""
    UPDATE installment_plans
    SET created_at = COALESCE(NULLIF(created_at, ''), ?),
        updated_at = COALESCE(NULLIF(updated_at, ''), COALESCE(NULLIF(created_at, ''), ?)),
        start_date = COALESCE(NULLIF(start_date, ''), ?)
    WHERE created_at IS NULL OR created_at = ''
       OR updated_at IS NULL OR updated_at = ''
       OR start_date IS NULL OR start_date = ''
  """, [nowIso, nowIso, nowIso]);

  await db.execute("""
    UPDATE installment_payments
    SET created_at = COALESCE(NULLIF(created_at, ''), ?),
        updated_at = COALESCE(NULLIF(updated_at, ''), COALESCE(NULLIF(created_at, ''), ?))
    WHERE created_at IS NULL OR created_at = '' OR updated_at IS NULL OR updated_at = ''
  """, [nowIso, nowIso]);

  await db.execute("""
    UPDATE history_entries
    SET created_at = COALESCE(NULLIF(created_at, ''), ?)
    WHERE created_at IS NULL OR created_at = ''
  """, [nowIso]);
}

Future<bool> _tableExists(
  sqflite.DatabaseExecutor db,
  String tableName,
) async {
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
    [tableName],
  );
  return result.isNotEmpty;
}

Future<bool> _columnExists(
  sqflite.DatabaseExecutor db,
  String tableName,
  String columnName,
) async {
  final pragma = await db.rawQuery("PRAGMA table_info($tableName)");
  return pragma.any((row) => row['name'] == columnName);
}

Future<void> _ensureColumn(
  sqflite.DatabaseExecutor db,
  String tableName,
  String columnName,
  String columnDefinition,
) async {
  final exists = await _columnExists(db, tableName, columnName);
  if (!exists) {
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
    );
  }
}

Future<bool> _indexExists(
  sqflite.DatabaseExecutor db,
  String indexName,
) async {
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ? LIMIT 1",
    [indexName],
  );
  return result.isNotEmpty;
}

Future<void> _ensureIndex(
  sqflite.DatabaseExecutor db,
  String indexName,
  String createSql,
) async {
  final exists = await _indexExists(db, indexName);
  if (!exists) {
    await db.execute(createSql);
  }
}