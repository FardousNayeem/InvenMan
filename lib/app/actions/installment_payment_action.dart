import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';

import 'package:invenman/app/core/money_utils.dart';
import 'package:invenman/app/core/domain_constants.dart';

import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/installment_repository.dart';


class RecordInstallmentPaymentAction {
  const RecordInstallmentPaymentAction._();

  static DateTime _nowUtc() => DbShared.nowUtc();

  static DateTime _startOfTodayUtc() => DbShared.startOfTodayUtc();

  static String _paymentRowStatus({
    required DateTime dueDate,
    required double amountDue,
    required double amountPaid,
  }) {
    const epsilon = MoneyUtils.epsilon;
    final today = _startOfTodayUtc();

    if (amountPaid >= amountDue - epsilon) return InstallmentPaymentStatuses.paid;
    if (amountPaid > epsilon) return InstallmentPaymentStatuses.partial;
    if (dueDate.isBefore(today)) return InstallmentPaymentStatuses.overdue;

    return InstallmentPaymentStatuses.pending;
  }

  static Future<void> execute({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) async {
    final dbClient = await AppDatabase.db;

    final paymentAmount = MoneyUtils.round(amountPaid);

    if (paymentAmount < 0) {
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

      final selectedPayment = InstallmentPayment.fromMap(paymentMaps.first);

      final normalizedPaidDate = paidDate == null
          ? null
          : DateTime.utc(
              paidDate.year,
              paidDate.month,
              paidDate.day,
            );

      final normalizedNote =
          (note ?? '').trim().isEmpty ? null : note?.trim();

      final installmentMaps = await txn.query(
        'installment_payments',
        where: 'installment_plan_id = ? AND installment_number >= ?',
        whereArgs: [
          selectedPayment.installmentPlanId,
          selectedPayment.installmentNumber,
        ],
        orderBy: 'installment_number ASC',
      );

      final installments = installmentMaps
          .map((map) => InstallmentPayment.fromMap(map))
          .toList();

      final totalRemaining = MoneyUtils.round(
        installments.fold<double>(0, (sum, row) {
          final amountDue = MoneyUtils.whole(row.amountDue);
          final alreadyPaid = MoneyUtils.round(row.amountPaid);
          final remaining = amountDue - alreadyPaid;

          return sum + (remaining > 0 ? remaining : 0);
        }),
      );

      if (paymentAmount > totalRemaining) {
        throw Exception('Payment cannot exceed remaining installment balance.');
      }

      double remainingPayment = paymentAmount;
      double totalApplied = 0;

      for (final row in installments) {
        final amountDue = MoneyUtils.whole(row.amountDue);
        final alreadyPaid = MoneyUtils.round(row.amountPaid);
        final rowRemaining = MoneyUtils.round(amountDue - alreadyPaid);

        if (rowRemaining <= 0) {
          continue;
        }

        final appliedAmount = remainingPayment >= rowRemaining
            ? rowRemaining
            : remainingPayment;

        final newAmountPaid = MoneyUtils.round(alreadyPaid + appliedAmount);

        final newStatus = _paymentRowStatus(
          dueDate: row.dueDate,
          amountDue: amountDue,
          amountPaid: newAmountPaid,
        );

        await txn.update(
          'installment_payments',
          {
            'amount_due': amountDue,
            'amount_paid': newAmountPaid,
            'paid_date': newAmountPaid > 0
                ? normalizedPaidDate?.toIso8601String()
                : null,
            'status': newStatus,
            'note': row.id == installmentPaymentId ? normalizedNote : row.note,
            'updated_at': _nowUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [row.id],
        );

        remainingPayment = MoneyUtils.round(remainingPayment - appliedAmount);
        totalApplied = MoneyUtils.round(totalApplied + appliedAmount);

        if (remainingPayment <= 0) {
          break;
        }
      }

      await InstallmentRepository.recalculateInstallmentPlanTxn(
        txn,
        selectedPayment.installmentPlanId,
        anchorInstallmentNumber: selectedPayment.installmentNumber,
      );

      final planMaps = await txn.query(
        'installment_plans',
        where: 'id = ?',
        whereArgs: [selectedPayment.installmentPlanId],
        limit: 1,
      );

      if (planMaps.isNotEmpty) {
        final plan = InstallmentPlan.fromMap(planMaps.first);

        final details = StringBuffer()
          ..write('From month ${selectedPayment.installmentNumber}')
          ..write(', Paid: ${MoneyUtils.text(totalApplied)}');

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
}