import 'package:invenman/models/installment_payment.dart';
import 'package:invenman/models/installment_plan.dart';
import 'package:invenman/services/database/app_database.dart';
import 'package:invenman/services/database/db_shared.dart';
import 'package:invenman/services/repositories/history_repository.dart';
import 'package:invenman/services/repositories/installment_repository.dart';

class RecordInstallmentPaymentAction {
  const RecordInstallmentPaymentAction._();

  static DateTime _nowUtc() => DbShared.nowUtc();

  static double _roundMoney(double value) => DbShared.roundMoney(value);

  static double _wholeMoney(double value) => DbShared.wholeMoney(value);

  static DateTime _startOfTodayUtc() => DbShared.startOfTodayUtc();

  static String _moneyText(double value) {
    return _roundMoney(value).toStringAsFixed(0);
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

  static Future<void> execute({
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
    
      if (amountPaid > payment.amountDue) {
        throw Exception('Payment cannot exceed due amount.');
      }

      final normalizedPaidDate = paidDate == null
        ? null
        : DateTime.utc(
            paidDate.year,
            paidDate.month,
            paidDate.day,
          );
      final normalizedNote = (note ?? '').trim().isEmpty ? null : note?.trim();

      final normalizedAmountDue = _wholeMoney(payment.amountDue);
      
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

      await InstallmentRepository.recalculateInstallmentPlanTxn(
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
}