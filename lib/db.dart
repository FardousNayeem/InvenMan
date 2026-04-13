import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'package:invenman/models/item.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/models/history.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/installment_payment.dart';

class DBHelper {
  static sqflite.Database? _db;
  static bool _isInitialized = false;

  static const String _databaseName = 'inventory.db';
  static const int _databaseVersion = 9;

  static Future<void> _initPlatform() async {
    if (_isInitialized) return;

    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _isInitialized = true;
  }

  static Future<sqflite.Database> get db async {
    await _initPlatform();
    _db ??= await _initDB();
    return _db!;
  }

  static Future<sqflite.Database> _initDB() async {
    final path = join(await sqflite.getDatabasesPath(), _databaseName);

    final factory = (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)
        ? databaseFactory
        : sqflite.databaseFactory;

    return factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await db.execute('DROP TABLE IF EXISTS installment_payments');
          await db.execute('DROP TABLE IF EXISTS installment_plans');
          await db.execute('DROP TABLE IF EXISTS history_entries');
          await db.execute('DROP TABLE IF EXISTS sale_records');
          await db.execute('DROP TABLE IF EXISTS item_history');
          await db.execute('DROP TABLE IF EXISTS sold_items');
          await db.execute('DROP TABLE IF EXISTS items');
          await _createTables(db);
        },
      ),
    );
  }

  static Future<void> _createTables(sqflite.Database db) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL,
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
        warranties_json TEXT NOT NULL DEFAULT '{}',
        image_paths_json TEXT NOT NULL DEFAULT '[]',
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

    await db.execute('CREATE INDEX idx_items_name ON items(name)');
    await db.execute('CREATE INDEX idx_items_category ON items(category)');
    await db.execute('CREATE INDEX idx_items_supplier ON items(supplier)');
    await db.execute('CREATE INDEX idx_items_updated_at ON items(updated_at)');

    await db.execute('CREATE INDEX idx_sale_records_item_id ON sale_records(item_id)');
    await db.execute('CREATE INDEX idx_sale_records_category ON sale_records(category)');
    await db.execute('CREATE INDEX idx_sale_records_sold_at ON sale_records(sold_at)');

    await db.execute('CREATE INDEX idx_installment_plans_status ON installment_plans(status)');
    await db.execute('CREATE INDEX idx_installment_plans_next_due_date ON installment_plans(next_due_date)');
    await db.execute('CREATE INDEX idx_installment_plans_customer_name ON installment_plans(customer_name)');
    await db.execute('CREATE INDEX idx_installment_plans_sale_record_id ON installment_plans(sale_record_id)');

    await db.execute('CREATE INDEX idx_installment_payments_plan_id ON installment_payments(installment_plan_id)');
    await db.execute('CREATE INDEX idx_installment_payments_due_date ON installment_payments(due_date)');
    await db.execute('CREATE INDEX idx_installment_payments_status ON installment_payments(status)');

    await db.execute('CREATE INDEX idx_history_entries_created_at ON history_entries(created_at)');
  }

  static DateTime _nowUtc() => DateTime.now().toUtc();

  static double _roundMoney(double value) {
    return ((value * 100).round()) / 100.0;
  }

  static double _wholeMoney(double value) {
    if (value <= 0) return 0;
    return value.roundToDouble();
  }

  static DateTime _startOfTodayUtc() {
    final now = _nowUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = (date.year * 12 + date.month - 1) + monthsToAdd;
    final newYear = totalMonths ~/ 12;
    final newMonth = (totalMonths % 12) + 1;

    final lastDayOfTargetMonth = DateTime.utc(newYear, newMonth + 1, 0).day;
    final newDay = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime.utc(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static List<double> _buildWholeNumberScheduleAmounts(
    double totalAmount,
    int months,
  ) {
    if (months <= 0) return const [];

    final totalUnits = totalAmount <= 0 ? 0 : totalAmount.round();
    final base = totalUnits ~/ months;
    final remainder = totalUnits % months;

    return List<double>.generate(months, (index) {
      return (base + (index < remainder ? 1 : 0)).toDouble();
    });
  }

  static String _paymentRowStatus({
    required DateTime dueDate,
    required double amountDue,
    required double amountPaid,
  }) {
    const epsilon = 0.009;
    final today = _startOfTodayUtc();

    if (amountPaid >= amountDue - epsilon) return 'paid';
    if (amountPaid > epsilon) return 'partial';
    if (dueDate.isBefore(today)) return 'overdue';
    return 'pending';
  }

  static String _formatWarranties(Map<String, int> warranties) {
    if (warranties.isEmpty) return 'No warranty';

    return warranties.entries
        .map((e) => '${e.key}: ${e.value} month${e.value == 1 ? '' : 's'}')
        .join(', ');
  }

  static String _formatSupplier(String supplier) {
    final trimmed = supplier.trim();
    return trimmed.isEmpty ? 'Unknown' : trimmed;
  }

  static Future<void> insertItem(Item item) async {
    final dbClient = await db;

    await dbClient.insert('items', item.toMap());

    await logHistory(
      item.name,
      'Added',
      'Qty: ${item.quantity}, Cost: ${item.costPrice}, Sell: ${item.sellingPrice}, '
      'Supplier: ${_formatSupplier(item.supplier)}, '
      'Warranties: ${_formatWarranties(item.warranties)}, '
      'Images: ${item.imagePaths.length}',
    );
  }

  static Future<void> updateItem(Item item) async {
    final dbClient = await db;

    await dbClient.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    await logHistory(
      item.name,
      'Edited',
      'Qty: ${item.quantity}, Cost: ${item.costPrice}, Sell: ${item.sellingPrice}, '
      'Supplier: ${_formatSupplier(item.supplier)}, '
      'Warranties: ${_formatWarranties(item.warranties)}, '
      'Images: ${item.imagePaths.length}',
    );
  }

  static Future<void> deleteItem(int id, String name) async {
    final dbClient = await db;

    await dbClient.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );

    await logHistory(name, 'Deleted', 'Item deleted from inventory');
  }

  static Future<List<Item>> fetchItems({String sortBy = 'name'}) async {
    final dbClient = await db;

    String orderBy = 'name ASC';

    switch (sortBy) {
      case 'cost_price_asc':
        orderBy = 'cost_price ASC';
        break;
      case 'cost_price_desc':
        orderBy = 'cost_price DESC';
        break;
      case 'selling_price_asc':
        orderBy = 'selling_price ASC';
        break;
      case 'selling_price_desc':
        orderBy = 'selling_price DESC';
        break;
      case 'category':
        orderBy = 'category ASC';
        break;
      case 'quantity_asc':
        orderBy = 'quantity ASC';
        break;
      case 'quantity_desc':
        orderBy = 'quantity DESC';
        break;
      case 'updated_at_desc':
        orderBy = 'updated_at DESC';
        break;
      case 'created_at_desc':
        orderBy = 'created_at DESC';
        break;
      default:
        orderBy = 'name ASC';
    }

    final maps = await dbClient.query('items', orderBy: orderBy);
    return maps.map((map) => Item.fromMap(map)).toList();
  }

  static Future<Item?> fetchItemById(int id) async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  static Future<List<String>> fetchDistinctCategories() async {
    final dbClient = await db;

    final result = await dbClient.rawQuery('''
      SELECT DISTINCT category
      FROM items
      WHERE TRIM(category) != ''
      ORDER BY category COLLATE NOCASE ASC
    ''');

    return result
        .map((e) => (e['category'] as String?)?.trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future<void> insertSaleRecord(
    SaleRecord sale, {
    double? downPayment,
  }) async {
    final dbClient = await db;

    await dbClient.transaction((txn) async {
      final saleId = await txn.insert('sale_records', sale.toMap());

      if (sale.paymentType == 'installment' && sale.installmentMonths != null) {
        await _createInstallmentPlanForSaleTxn(
          txn,
          saleRecordId: saleId,
          sale: sale.copyWith(id: saleId),
          downPayment: downPayment ?? 0,
        );
      }

      final details = StringBuffer()
        ..write('Qty: ${sale.quantitySold}, Sell: ${sale.sellPrice}, Profit: ${sale.profit}');

      if ((sale.customerName ?? '').trim().isNotEmpty) {
        details.write(', Customer: ${sale.customerName}');
      }
      if ((sale.customerPhone ?? '').trim().isNotEmpty) {
        details.write(', Phone: ${sale.customerPhone}');
      }

      details.write(', Payment: ${sale.paymentType}');
      if (sale.paymentType == 'installment' && sale.installmentMonths != null) {
        details.write(', Installment: ${sale.installmentMonths} month(s)');
        details.write(', Down Payment: ${_roundMoney(downPayment ?? 0)}');
      }

      details.write(', Warranties: ${_formatWarranties(sale.warranties)}');

      await txn.insert('history_entries', {
        'item_name': sale.itemName,
        'action': 'Sold',
        'details': details.toString(),
        'created_at': _nowUtc().toIso8601String(),
      });
    });
  }

  static Future<List<SaleRecord>> fetchSaleRecords() async {
    final dbClient = await db;
    final maps = await dbClient.query('sale_records', orderBy: 'sold_at DESC');
    return maps.map((map) => SaleRecord.fromMap(map)).toList();
  }

  static Future<SaleRecord?> fetchSaleRecordById(int id) async {
    final dbClient = await db;

    final maps = await dbClient.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SaleRecord.fromMap(maps.first);
  }

  static Future<void> logHistory(
    String itemName,
    String action,
    String details,
  ) async {
    final dbClient = await db;
    await dbClient.insert('history_entries', {
      'item_name': itemName,
      'action': action,
      'details': details,
      'created_at': _nowUtc().toIso8601String(),
    });
  }

  static Future<List<HistoryEntry>> fetchHistoryEntries() async {
    final dbClient = await db;
    final maps = await dbClient.query('history_entries', orderBy: 'created_at DESC');
    return maps.map((map) => HistoryEntry.fromMap(map)).toList();
  }

  static Future<void> sellItem({
    required Item item,
    required int quantitySold,
    required double sellPricePerUnit,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    required String paymentType,
    int? installmentMonths,
    double? downPayment,
  }) async {
    final dbClient = await db;

    if (item.id == null) {
      throw Exception('Cannot sell an item without an id.');
    }

    if (quantitySold <= 0) {
      throw Exception('Quantity sold must be greater than zero.');
    }

    if (item.quantity < quantitySold) {
      throw Exception('Not enough stock available.');
    }

    if (paymentType != 'direct' && paymentType != 'installment') {
      throw Exception('Payment type must be either direct or installment.');
    }

    final totalSaleAmount = _roundMoney(sellPricePerUnit * quantitySold);

    if (paymentType == 'installment' &&
        (installmentMonths == null || installmentMonths <= 0)) {
      throw Exception('Installment duration must be greater than zero.');
    }

    if (paymentType == 'installment') {
      if (downPayment == null) {
        throw Exception('Down payment is required for installment sales.');
      }
      if (downPayment < 0) {
        throw Exception('Down payment cannot be negative.');
      }
      if (downPayment <= 0) {
        throw Exception('Down payment must be greater than zero.');
      }
      if (downPayment >= totalSaleAmount) {
        throw Exception('Down payment must be less than total sale amount.');
      }
    }

    if (paymentType == 'direct') {
      installmentMonths = null;
      downPayment = null;
    }

    final now = _nowUtc();

    final updatedItem = item.copyWith(
      quantity: item.quantity - quantitySold,
      updatedAt: now,
    );

    final profit = (sellPricePerUnit - item.costPrice) * quantitySold;

    final sale = SaleRecord(
      itemId: item.id!,
      itemName: item.name,
      category: item.category,
      quantitySold: quantitySold,
      costPrice: item.costPrice,
      sellPrice: sellPricePerUnit,
      profit: profit,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentType: paymentType,
      installmentMonths: installmentMonths,
      warranties: item.warranties,
      soldAt: now,
    );

    await dbClient.transaction((txn) async {
      await txn.update(
        'items',
        updatedItem.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      final saleId = await txn.insert('sale_records', sale.toMap());

      if (paymentType == 'installment' && installmentMonths != null) {
        await _createInstallmentPlanForSaleTxn(
          txn,
          saleRecordId: saleId,
          sale: sale.copyWith(id: saleId),
          downPayment: downPayment ?? 0,
        );
      }

      final details = StringBuffer()
        ..write('Qty: $quantitySold, Sell: $sellPricePerUnit, Profit: $profit');

      if ((customerName ?? '').trim().isNotEmpty) {
        details.write(', Customer: $customerName');
      }
      if ((customerPhone ?? '').trim().isNotEmpty) {
        details.write(', Phone: $customerPhone');
      }

      details.write(', Payment: $paymentType');
      if (paymentType == 'installment' && installmentMonths != null) {
        details.write(', Installment: $installmentMonths month(s)');
        details.write(', Down Payment: ${_roundMoney(downPayment ?? 0)}');
      }

      details.write(', Warranties: ${_formatWarranties(item.warranties)}');
      details.write(', Images: ${item.imagePaths.length}');

      await txn.insert('history_entries', {
        'item_name': item.name,
        'action': 'Sold',
        'details': details.toString(),
        'created_at': now.toIso8601String(),
      });
    });
  }

  static Future<int> _createInstallmentPlanForSaleTxn(
    sqflite.Transaction txn, {
    required int saleRecordId,
    required SaleRecord sale,
    required double downPayment,
  }) async {
    if (sale.installmentMonths == null || sale.installmentMonths! <= 0) {
      throw Exception('Installment duration is required for installment plans.');
    }

    final now = _nowUtc();
    final totalAmount = _roundMoney(sale.sellPrice * sale.quantitySold);
    final normalizedDownPayment = _roundMoney(downPayment);

    if (normalizedDownPayment <= 0) {
      throw Exception('Down payment must be greater than zero.');
    }
    if (normalizedDownPayment >= totalAmount) {
      throw Exception('Down payment must be less than total sale amount.');
    }

    final financedAmount = _roundMoney(totalAmount - normalizedDownPayment);
    final durationMonths = sale.installmentMonths!;
    final scheduleAmounts =
        _buildWholeNumberScheduleAmounts(financedAmount, durationMonths);
    final monthlyAmount =
        scheduleAmounts.isNotEmpty ? scheduleAmounts.first : 0.0;
    final nextDueDate = _addMonths(sale.soldAt, 1);

    final planId = await txn.insert('installment_plans', {
      'sale_record_id': saleRecordId,
      'item_name': sale.itemName,
      'category': sale.category,
      'customer_name': sale.customerName,
      'customer_phone': sale.customerPhone,
      'customer_address': sale.customerAddress,
      'total_amount': totalAmount,
      'down_payment': normalizedDownPayment,
      'financed_amount': financedAmount,
      'duration_months': durationMonths,
      'monthly_amount': monthlyAmount,
      'start_date': sale.soldAt.toIso8601String(),
      'next_due_date': nextDueDate.toIso8601String(),
      'paid_months': 0,
      'remaining_months': durationMonths,
      'total_paid': normalizedDownPayment,
      'remaining_balance': financedAmount,
      'status': 'active',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    for (int i = 0; i < durationMonths; i++) {
      final dueDate = _addMonths(sale.soldAt, i + 1);
      final amountDue = scheduleAmounts[i];
      final status = _paymentRowStatus(
        dueDate: dueDate,
        amountDue: amountDue,
        amountPaid: 0,
      );

      await txn.insert('installment_payments', {
        'installment_plan_id': planId,
        'installment_number': i + 1,
        'due_date': dueDate.toIso8601String(),
        'paid_date': null,
        'amount_due': amountDue,
        'amount_paid': 0.0,
        'status': status,
        'note': null,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    }

    await txn.insert('history_entries', {
      'item_name': sale.itemName,
      'action': 'Installment',
      'details':
          'Installment plan created: $durationMonths month(s), Total: ${totalAmount.toStringAsFixed(0)}, Down Payment: ${normalizedDownPayment.toStringAsFixed(0)}, Financed: ${financedAmount.toStringAsFixed(0)}, Monthly approx: ${monthlyAmount.toStringAsFixed(0)}',
      'created_at': now.toIso8601String(),
    });

    await _recalculateInstallmentPlanTxn(txn, planId);
    return planId;
  }

  static Future<void> _redistributeFuturePaymentsTxn(
    sqflite.Transaction txn,
    InstallmentPlan plan,
    int anchorInstallmentNumber,
  ) async {
    final paymentMaps = await txn.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [plan.id],
      orderBy: 'installment_number ASC',
    );

    if (paymentMaps.isEmpty) return;

    final payments = paymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    double totalPaidTowardInstallments = 0.0;
    for (final payment in payments) {
      totalPaidTowardInstallments += payment.amountPaid;
    }
    totalPaidTowardInstallments = _roundMoney(totalPaidTowardInstallments);

    double financedRemaining = _roundMoney(plan.financedAmount - totalPaidTowardInstallments);
    if (financedRemaining < 0) financedRemaining = 0;

    double lockedOutstanding = 0.0;
    final redistributable = <InstallmentPayment>[];

    for (final payment in payments) {
      final normalizedDue = payment.amountPaid > payment.amountDue
          ? payment.amountPaid
          : payment.amountDue;

      final computedStatus = _paymentRowStatus(
        dueDate: payment.dueDate,
        amountDue: normalizedDue,
        amountPaid: payment.amountPaid,
      );

      final isLocked = payment.installmentNumber <= anchorInstallmentNumber ||
          computedStatus == 'paid';

      if (isLocked) {
        final outstanding = normalizedDue - payment.amountPaid;
        if (outstanding > 0) {
          lockedOutstanding += outstanding;
        }

        if ((normalizedDue - payment.amountDue).abs() > 0.009) {
          await txn.update(
            'installment_payments',
            {
              'amount_due': _wholeMoney(normalizedDue),
              'updated_at': _nowUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.id],
          );
        }
      } else {
        redistributable.add(payment);
      }
    }

    lockedOutstanding = _roundMoney(lockedOutstanding);

    double outstandingToAllocate = _roundMoney(financedRemaining - lockedOutstanding);
    if (outstandingToAllocate < 0) {
      outstandingToAllocate = 0;
    }

    final redistributedOutstanding = _buildWholeNumberScheduleAmounts(
      outstandingToAllocate,
      redistributable.length,
    );

    for (int i = 0; i < redistributable.length; i++) {
      final payment = redistributable[i];
      final newAmountDue = _wholeMoney(payment.amountPaid + redistributedOutstanding[i]);

      await txn.update(
        'installment_payments',
        {
          'amount_due': newAmountDue,
          'updated_at': _nowUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [payment.id],
      );
    }
  }

  static Future<void> _recalculateInstallmentPlanTxn(
    sqflite.Transaction txn,
    int planId, {
    int? anchorInstallmentNumber,
  }) async {
    final planMaps = await txn.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );

    if (planMaps.isEmpty) return;

    final plan = InstallmentPlan.fromMap(planMaps.first);

    if (anchorInstallmentNumber != null) {
      await _redistributeFuturePaymentsTxn(
        txn,
        plan,
        anchorInstallmentNumber,
      );
    }

    final refreshedPaymentMaps = await txn.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [planId],
      orderBy: 'installment_number ASC',
    );

    if (refreshedPaymentMaps.isEmpty) return;

    final payments =
        refreshedPaymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    final now = _nowUtc();

    double paymentRowsTotalPaid = 0.0;
    for (final payment in payments) {
      paymentRowsTotalPaid += payment.amountPaid;
    }
    paymentRowsTotalPaid = _roundMoney(paymentRowsTotalPaid);

    final totalPaid = _roundMoney(plan.downPayment + paymentRowsTotalPaid);

    double remainingBalance = _roundMoney(plan.totalAmount - totalPaid);
    if (remainingBalance < 0) remainingBalance = 0;

    if (remainingBalance <= 0.009) {
      for (final payment in payments) {
        final settledDue = _wholeMoney(
          payment.amountPaid > payment.amountDue ? payment.amountPaid : payment.amountDue,
        );

        await txn.update(
          'installment_payments',
          {
            'amount_due': payment.amountPaid > 0
                ? _wholeMoney(payment.amountPaid)
                : 0.0,
            'status': 'paid',
            'updated_at': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [payment.id],
        );
      }
    } else {
      for (final payment in payments) {
        final normalizedDue = _wholeMoney(
          payment.amountPaid > payment.amountDue ? payment.amountPaid : payment.amountDue,
        );

        final computedStatus = _paymentRowStatus(
          dueDate: payment.dueDate,
          amountDue: normalizedDue,
          amountPaid: payment.amountPaid,
        );

        final shouldUpdateDue = (normalizedDue - payment.amountDue).abs() > 0.009;
        final shouldUpdateStatus = computedStatus != payment.status;

        if (shouldUpdateDue || shouldUpdateStatus) {
          await txn.update(
            'installment_payments',
            {
              'amount_due': normalizedDue,
              'status': computedStatus,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.id],
          );
        }
      }
    }

    final finalPaymentMaps = await txn.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [planId],
      orderBy: 'installment_number ASC',
    );

    final finalPayments =
        finalPaymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    int paidMonths = 0;
    int remainingMonths = 0;
    DateTime? nextDueDate;
    bool hasOverdue = false;
    double nextMonthlyAmount = 0.0;

    for (final payment in finalPayments) {
      if (payment.status == 'paid') {
        paidMonths++;
      } else {
        remainingMonths++;
        nextDueDate ??= payment.dueDate;
        nextMonthlyAmount = payment.amountDue;
      }

      if (payment.status == 'overdue') {
        hasOverdue = true;
      }
    }

    String planStatus;
    if (remainingBalance <= 0.009) {
      planStatus = 'completed';
      nextDueDate = null;
      remainingMonths = 0;
      paidMonths = plan.durationMonths;
      nextMonthlyAmount = 0.0;
    } else if (hasOverdue) {
      planStatus = 'overdue';
    } else {
      planStatus = 'active';
    }

    await txn.update(
      'installment_plans',
      {
        'paid_months': paidMonths,
        'remaining_months': remainingMonths,
        'total_paid': totalPaid,
        'remaining_balance': remainingBalance,
        'next_due_date': nextDueDate?.toIso8601String(),
        'monthly_amount': _wholeMoney(nextMonthlyAmount),
        'status': planStatus,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  static Future<void> _refreshInstallmentStatuses() async {
    final dbClient = await db;
    final planIds = await dbClient.query(
      'installment_plans',
      columns: ['id'],
    );

    if (planIds.isEmpty) return;

    await dbClient.transaction((txn) async {
      for (final row in planIds) {
        final id = row['id'] as int?;
        if (id != null) {
          await _recalculateInstallmentPlanTxn(txn, id);
        }
      }
    });
  }

  static Future<List<InstallmentPlan>> fetchInstallmentPlans({
    String sortBy = 'next_due_asc',
  }) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    String orderBy;
    switch (sortBy) {
      case 'next_due_desc':
        orderBy = 'next_due_date DESC, updated_at DESC';
        break;
      case 'customer':
        orderBy = 'customer_name COLLATE NOCASE ASC, updated_at DESC';
        break;
      case 'item':
        orderBy = 'item_name COLLATE NOCASE ASC, updated_at DESC';
        break;
      case 'status':
        orderBy = 'status ASC, next_due_date ASC';
        break;
      case 'latest':
        orderBy = 'created_at DESC';
        break;
      case 'next_due_asc':
      default:
        orderBy = 'next_due_date ASC, updated_at DESC';
        break;
    }

    final maps = await dbClient.query(
      'installment_plans',
      orderBy: orderBy,
    );

    return maps.map((map) => InstallmentPlan.fromMap(map)).toList();
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanById(int id) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    final maps = await dbClient.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return InstallmentPlan.fromMap(maps.first);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanBySaleRecordId(int saleRecordId) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    final maps = await dbClient.query(
      'installment_plans',
      where: 'sale_record_id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return InstallmentPlan.fromMap(maps.first);
  }

  static Future<List<InstallmentPayment>> fetchInstallmentPayments(
    int installmentPlanId,
  ) async {
    await _refreshInstallmentStatuses();
    final dbClient = await db;

    final maps = await dbClient.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [installmentPlanId],
      orderBy: 'installment_number ASC',
    );

    return maps.map((map) => InstallmentPayment.fromMap(map)).toList();
  }

  static Future<void> saveInstallmentPayment({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) async {
    final dbClient = await db;

    if (amountPaid < 0) {
      throw Exception('Amount paid cannot be negative.');
    }

    await dbClient.transaction((txn) async {
      final paymentMaps = await txn.query(
        'installment_payments',
        where: 'id = ?',
        whereArgs: [installmentPaymentId],
        limit: 1,
      );

      if (paymentMaps.isEmpty) {
        throw Exception('Installment payment entry not found.');
      }

      final payment = InstallmentPayment.fromMap(paymentMaps.first);

      final normalizedPaidDate = amountPaid > 0 ? (paidDate ?? _nowUtc()) : null;
      final normalizedNote = (note ?? '').trim().isEmpty ? null : note!.trim();
      final normalizedAmountDue = amountPaid > payment.amountDue
          ? _wholeMoney(amountPaid)
          : _wholeMoney(payment.amountDue);

      final newStatus = _paymentRowStatus(
        dueDate: payment.dueDate,
        amountDue: normalizedAmountDue,
        amountPaid: amountPaid,
      );

      await txn.update(
        'installment_payments',
        {
          'amount_due': normalizedAmountDue,
          'amount_paid': _roundMoney(amountPaid),
          'paid_date': normalizedPaidDate?.toIso8601String(),
          'status': newStatus,
          'note': normalizedNote,
          'updated_at': _nowUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentPaymentId],
      );

      await _recalculateInstallmentPlanTxn(
        txn,
        payment.installmentPlanId,
        anchorInstallmentNumber: payment.installmentNumber,
      );

      final planMaps = await txn.query(
        'installment_plans',
        where: 'id = ?',
        whereArgs: [payment.installmentPlanId],
        limit: 1,
      );

      if (planMaps.isNotEmpty) {
        final plan = InstallmentPlan.fromMap(planMaps.first);
        await txn.insert('history_entries', {
          'item_name': plan.itemName,
          'action': 'Installment Payment',
          'details':
              'Month ${payment.installmentNumber}: Paid ${_roundMoney(amountPaid).toStringAsFixed(0)}'
              '${normalizedPaidDate != null ? ' on ${normalizedPaidDate.toIso8601String()}' : ''}'
              '${normalizedNote != null ? ', Note: $normalizedNote' : ''}',
          'created_at': _nowUtc().toIso8601String(),
        });
      }
    });
  }

  static Future<void> clearAllData() async {
    final dbClient = await db;
    await dbClient.delete('installment_payments');
    await dbClient.delete('installment_plans');
    await dbClient.delete('history_entries');
    await dbClient.delete('sale_records');
    await dbClient.delete('items');
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}