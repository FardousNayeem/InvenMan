import 'package:invenman/app/core/app_exception.dart';
import 'package:invenman/app/core/installment_calculator.dart';
import 'package:invenman/app/core/money_utils.dart';

import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';

import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class RecordInstallmentPaymentAction {
  const RecordInstallmentPaymentAction._();

  static Future<void> execute({
    required int installmentPaymentId,
    required double amountPaid,
    required DateTime? paidDate,
    String? note,
  }) async {
    final dbClient = await AppDatabase.db;

    final paymentAmount = MoneyUtils.round(amountPaid);

    if (paymentAmount < 0) {
      throw const AppException.validation(
        code: 'installment_payment_negative_amount',
        message: 'Amount paid cannot be negative.',
      );
    }

    await dbClient.transaction((txn) async {
      final paymentMaps = await txn.query(
        'installment_payments',
        where: 'id = ?',
        whereArgs: [installmentPaymentId],
        limit: 1,
      );

      if (paymentMaps.isEmpty) {
        throw const AppException.notFound(
          code: 'installment_payment_not_found',
          message: 'Installment payment entry not found.',
        );
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

      final futurePaymentMaps = await txn.query(
        'installment_payments',
        where: 'installment_plan_id = ? AND installment_number >= ?',
        whereArgs: [
          selectedPayment.installmentPlanId,
          selectedPayment.installmentNumber,
        ],
        orderBy: 'installment_number ASC',
      );

      final futurePayments = futurePaymentMaps
          .map((map) => InstallmentPayment.fromMap(map))
          .toList();

      final totalRemaining = MoneyUtils.round(
        futurePayments.fold<double>(0, (sum, row) {
          final amountDue = MoneyUtils.whole(row.amountDue);
          final alreadyPaid = MoneyUtils.round(row.amountPaid);
          final remaining = amountDue - alreadyPaid;

          return sum + (remaining > 0 ? remaining : 0);
        }),
      );

      if (paymentAmount > totalRemaining) {
        throw const AppException.validation(
          code: 'installment_payment_exceeds_remaining_balance',
          message: 'Payment cannot exceed remaining installment balance.',
        );
      }

      final selectedAmountDue = MoneyUtils.whole(selectedPayment.amountDue);

      final newSelectedAmountPaid = MoneyUtils.round(
        selectedPayment.amountPaid + paymentAmount,
      );

      final selectedStatus = InstallmentRepository.resolvePaymentRowStatus(
        dueDate: selectedPayment.dueDate,
        amountDue: selectedAmountDue,
        amountPaid: newSelectedAmountPaid,
      );

      await txn.update(
        'installment_payments',
        {
          'amount_due': selectedAmountDue,
          'amount_paid': newSelectedAmountPaid,
          'paid_date': newSelectedAmountPaid > 0
              ? normalizedPaidDate?.toIso8601String()
              : null,
          'status': selectedStatus,
          'note': normalizedNote,
          'updated_at': InstallmentCalculator.nowUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [selectedPayment.id],
      );

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
          ..write('Month ${selectedPayment.installmentNumber}')
          ..write(', Paid: ${MoneyUtils.text(paymentAmount)}');

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
          meta: {
            'eventType': 'installment_payment',
            'installmentPlanId': plan.id,
            'installmentPaymentId': selectedPayment.id,
            'installmentNumber': selectedPayment.installmentNumber,
            'amountDueBefore': selectedPayment.amountDue,
            'amountPaidBefore': selectedPayment.amountPaid,
            'amountPaidNow': paymentAmount,
            'amountPaidAfter': newSelectedAmountPaid,
            'statusAfter': selectedStatus,
            'paidDate': normalizedPaidDate?.toIso8601String(),
            'note': normalizedNote,
            'itemName': plan.itemName,
            'customerName': plan.customerName,
            'customerPhone': plan.customerPhone,
          },
          executor: txn,
        );
      }
    });
  }
}