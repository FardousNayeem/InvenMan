class DbShared {
  const DbShared._();

  static DateTime nowUtc() => DateTime.now().toUtc();

  static double roundMoney(double value) {
    return ((value * 100).round()) / 100.0;
  }

  static double wholeMoney(double value) {
    if (value <= 0) return 0;
    return value.roundToDouble();
  }

  static DateTime startOfTodayUtc() {
    final now = nowUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  static DateTime addMonths(DateTime date, int monthsToAdd) {
    final totalMonths = (date.year * 12 + date.month - 1) + monthsToAdd;
    final newYear = totalMonths ~/ 12;
    final newMonth = (totalMonths % 12) + 1;

    final lastDayOfTargetMonth = DateTime.utc(newYear, newMonth + 1, 0).day;
    final newDay =
        date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

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
}