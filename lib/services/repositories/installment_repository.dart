import 'dart:convert';

import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/models/sale_record.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/repositories/history_repository.dart';

class InstallmentDocumentSyncResult {
  final int saleRecordId;
  final int? installmentPlanId;
  final List<String> imagePaths;

  const InstallmentDocumentSyncResult({
    required this.saleRecordId,
    required this.installmentPlanId,
    required this.imagePaths,
  });
}

class InstallmentRepository {
  const InstallmentRepository._();

  static DateTime _nowUtc() => DbShared.nowUtc();
  static double _roundMoney(double value) => DbShared.roundMoney(value);
  static double _wholeMoney(double value) => DbShared.wholeMoney(value);
  static DateTime _startOfTodayUtc() => DbShared.startOfTodayUtc();

  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    return DbShared.addMonths(date, monthsToAdd);
  }

  static String _moneyText(double value) {
    return _roundMoney(value).toStringAsFixed(0);
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

  static List<String> normalizeInstallmentImages(List<String> paths) {
    final seen = <String>{};
    final cleaned = <String>[];

    for (final raw in paths) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      if (seen.contains(trimmed)) continue;

      seen.add(trimmed);
      cleaned.add(trimmed);
    }

    if (cleaned.length > 5) {
      return cleaned.take(5).toList();
    }

    return cleaned;
  }

  static Future<int> createInstallmentPlanForSaleTxn(
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
    final normalizedImages =
        normalizeInstallmentImages(sale.installmentImagePaths);

    final planId = await txn.insert('installment_plans', {
      'sale_record_id': saleRecordId,
      'item_name': sale.itemName,
      'category': sale.category,
      'customer_name': sale.customerName,
      'customer_phone': sale.customerPhone,
      'customer_address': sale.customerAddress,
      'image_paths_json': jsonEncode(normalizedImages),
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

    await HistoryRepository.logHistory(
      itemName: sale.itemName,
      action: 'Installment',
      details:
          'Plan created: $durationMonths month(s), Total: ${_moneyText(totalAmount)}, Down Payment: ${_moneyText(normalizedDownPayment)}, Financed: ${_moneyText(financedAmount)}, Monthly approx: ${_moneyText(monthlyAmount)}, Installment Docs: ${normalizedImages.length}',
      executor: txn,
    );

    await recalculateInstallmentPlanTxn(txn, planId);
    return planId;
  }

  static Future<void> redistributeFuturePaymentsTxn(
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

    final payments =
        paymentMaps.map((map) => InstallmentPayment.fromMap(map)).toList();

    double totalPaidTowardInstallments = 0.0;
    for (final payment in payments) {
      totalPaidTowardInstallments += payment.amountPaid;
    }
    totalPaidTowardInstallments = _roundMoney(totalPaidTowardInstallments);

    double financedRemaining =
        _roundMoney(plan.financedAmount - totalPaidTowardInstallments);
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

    double outstandingToAllocate =
        _roundMoney(financedRemaining - lockedOutstanding);

    if (outstandingToAllocate < 0) {
      outstandingToAllocate = 0;
    }

    final redistributedOutstanding = _buildWholeNumberScheduleAmounts(
      outstandingToAllocate,
      redistributable.length,
    );

    for (int i = 0; i < redistributable.length; i++) {
      final payment = redistributable[i];
      final newAmountDue =
          _wholeMoney(payment.amountPaid + redistributedOutstanding[i]);

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

  static Future<void> recalculateInstallmentPlanTxn(
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
      await redistributeFuturePaymentsTxn(
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

    final payments = refreshedPaymentMaps
        .map((map) => InstallmentPayment.fromMap(map))
        .toList();

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
          payment.amountPaid > payment.amountDue
              ? payment.amountPaid
              : payment.amountDue,
        );

        final computedStatus = _paymentRowStatus(
          dueDate: payment.dueDate,
          amountDue: normalizedDue,
          amountPaid: payment.amountPaid,
        );

        final shouldUpdateDue =
            (normalizedDue - payment.amountDue).abs() > 0.009;
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

    final finalPayments = finalPaymentMaps
        .map((map) => InstallmentPayment.fromMap(map))
        .toList();

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

  static Future<void> refreshInstallmentStatuses() async {
    final dbClient = await AppDatabase.db;

    final planIds = await dbClient.query(
      'installment_plans',
      columns: ['id'],
    );

    if (planIds.isEmpty) return;

    await dbClient.transaction((txn) async {
      for (final row in planIds) {
        final id = row['id'] as int?;
        if (id != null) {
          await recalculateInstallmentPlanTxn(txn, id);
        }
      }
    });
  }

  static Future<List<InstallmentPlan>> fetchInstallmentPlans({
    String sortBy = 'next_due_asc',
  }) async {
    await refreshInstallmentStatuses();

    final dbClient = await AppDatabase.db;

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

    return maps.map(InstallmentPlan.fromMap).toList();
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanById(int id) async {
    await refreshInstallmentStatuses();

    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'installment_plans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return InstallmentPlan.fromMap(maps.first);
  }

  static Future<InstallmentPlan?> fetchInstallmentPlanBySaleRecordId(
    int saleRecordId,
  ) async {
    await refreshInstallmentStatuses();

    final dbClient = await AppDatabase.db;

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
    await refreshInstallmentStatuses();

    final dbClient = await AppDatabase.db;

    final maps = await dbClient.query(
      'installment_payments',
      where: 'installment_plan_id = ?',
      whereArgs: [installmentPlanId],
      orderBy: 'installment_number ASC',
    );

    return maps.map(InstallmentPayment.fromMap).toList();
  }

  static Future<void> saveInstallmentPayment({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) async {
    final dbClient = await AppDatabase.db;

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
      final normalizedNote = (note ?? '').trim().isEmpty ? null : note?.trim();

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

      await recalculateInstallmentPlanTxn(
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
        final details = StringBuffer()
          ..write('Month ${payment.installmentNumber}')
          ..write(', Paid: ${_moneyText(amountPaid)}');

        if (normalizedPaidDate != null) {
          details.write(', Date: ${normalizedPaidDate.toIso8601String()}');
        }

        if (normalizedNote != null) {
          details.write(', Note: $normalizedNote');
        }

        await HistoryRepository.logHistory(
          itemName: plan.itemName,
          action: 'Installment Payment',
          details: details.toString(),
          executor: txn,
        );
      }
    });
  }

  static Future<InstallmentDocumentSyncResult> syncInstallmentDocumentsTxn(
    sqflite.Transaction txn, {
    required int saleRecordId,
    required List<String> imagePaths,
  }) async {
    final nowIso = _nowUtc().toIso8601String();
    final normalizedImages = normalizeInstallmentImages(imagePaths);
    final encodedImages = jsonEncode(normalizedImages);

    final saleMaps = await txn.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    if (saleMaps.isEmpty) {
      throw Exception('Sale record not found.');
    }

    final sale = SaleRecord.fromMap(saleMaps.first);

    if (!sale.isInstallment) {
      throw Exception('Only installment sales can have installment documents.');
    }

    await txn.update(
      'sale_records',
      {
        'installment_image_paths_json': encodedImages,
      },
      where: 'id = ?',
      whereArgs: [saleRecordId],
    );

    final planMaps = await txn.query(
      'installment_plans',
      columns: ['id'],
      where: 'sale_record_id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    int? installmentPlanId;

    if (planMaps.isNotEmpty) {
      installmentPlanId = planMaps.first['id'] as int?;
      if (installmentPlanId != null) {
        await txn.update(
          'installment_plans',
          {
            'image_paths_json': encodedImages,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [installmentPlanId],
        );
      }
    }

    await HistoryRepository.logHistory(
      itemName: sale.itemName,
      action: 'Installment Documents Updated',
      details: 'Installment Documents Updated. Count: ${normalizedImages.length}',
      executor: txn,
    );

    return InstallmentDocumentSyncResult(
      saleRecordId: saleRecordId,
      installmentPlanId: installmentPlanId,
      imagePaths: normalizedImages,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      updateInstallmentDocumentsBySaleRecordId({
    required int saleRecordId,
    required List<String> imagePaths,
  }) async {
    final dbClient = await AppDatabase.db;

    return dbClient.transaction((txn) async {
      return syncInstallmentDocumentsTxn(
        txn,
        saleRecordId: saleRecordId,
        imagePaths: imagePaths,
      );
    });
  }

  static Future<InstallmentDocumentSyncResult>
      updateInstallmentDocumentsByInstallmentPlanId({
    required int installmentPlanId,
    required List<String> imagePaths,
  }) async {
    final dbClient = await AppDatabase.db;

    return dbClient.transaction((txn) async {
      final planMaps = await txn.query(
        'installment_plans',
        columns: ['sale_record_id'],
        where: 'id = ?',
        whereArgs: [installmentPlanId],
        limit: 1,
      );

      if (planMaps.isEmpty) {
        throw Exception('Installment plan not found.');
      }

      final saleRecordId = planMaps.first['sale_record_id'] as int?;

      if (saleRecordId == null) {
        throw Exception('Linked sale record not found.');
      }

      return syncInstallmentDocumentsTxn(
        txn,
        saleRecordId: saleRecordId,
        imagePaths: imagePaths,
      );
    });
  }

  static Future<InstallmentDocumentSyncResult>
      removeInstallmentDocumentBySaleRecordId({
    required int saleRecordId,
    required String imagePath,
  }) async {
    final dbClient = await AppDatabase.db;

    final saleMaps = await dbClient.query(
      'sale_records',
      where: 'id = ?',
      whereArgs: [saleRecordId],
      limit: 1,
    );

    if (saleMaps.isEmpty) {
      throw Exception('Sale record not found.');
    }

    final sale = SaleRecord.fromMap(saleMaps.first);
    final updatedPaths = List<String>.from(sale.installmentImagePaths)
      ..removeWhere((e) => e == imagePath);

    return updateInstallmentDocumentsBySaleRecordId(
      saleRecordId: saleRecordId,
      imagePaths: updatedPaths,
    );
  }

  static Future<InstallmentDocumentSyncResult>
      removeInstallmentDocumentByInstallmentPlanId({
    required int installmentPlanId,
    required String imagePath,
  }) async {
    final plan = await fetchInstallmentPlanById(installmentPlanId);

    if (plan == null) {
      throw Exception('Installment plan not found.');
    }

    final updatedPaths = List<String>.from(plan.installmentImagePaths)
      ..removeWhere((e) => e == imagePath);

    return updateInstallmentDocumentsByInstallmentPlanId(
      installmentPlanId: installmentPlanId,
      imagePaths: updatedPaths,
    );
  }

  static Future<void> normalizeExistingInstallmentValues(
    sqflite.DatabaseExecutor db,
  ) async {
    final planMaps = await db.query(
      'installment_plans',
      columns: ['id'],
    );

    if (planMaps.isEmpty) return;

    for (final row in planMaps) {
      final id = row['id'] as int?;
      if (id == null) continue;

      final paymentMaps = await db.query(
        'installment_payments',
        where: 'installment_plan_id = ?',
        whereArgs: [id],
        orderBy: 'installment_number ASC',
      );

      for (final paymentMap in paymentMaps) {
        final payment = InstallmentPayment.fromMap(paymentMap);

        final normalizedDue = _wholeMoney(
          payment.amountPaid > payment.amountDue
              ? payment.amountPaid
              : payment.amountDue,
        );

        final normalizedPaid = _roundMoney(payment.amountPaid);

        if ((normalizedDue - payment.amountDue).abs() > 0.009 ||
            (normalizedPaid - payment.amountPaid).abs() > 0.009) {
          await db.update(
            'installment_payments',
            {
              'amount_due': normalizedDue,
              'amount_paid': normalizedPaid,
              'updated_at': _nowUtc().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [payment.id],
          );
        }
      }

      if (db is sqflite.Transaction) {
        await recalculateInstallmentPlanTxn(db, id);
      }
    }
  }
}