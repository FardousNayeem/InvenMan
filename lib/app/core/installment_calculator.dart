import 'package:invenman/services/database/db_shared.dart';

class InstallmentCalculator {
  const InstallmentCalculator._();

  static DateTime nowUtc() => DbShared.nowUtc();

  static DateTime addMonths(DateTime date, int monthsToAdd) {
    return DbShared.addMonths(date, monthsToAdd);
  }

  static List<double> buildWholeNumberScheduleAmounts(
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
}