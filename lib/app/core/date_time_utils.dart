class DateTimeUtils {
  const DateTimeUtils._();

  static DateTime nowUtc() => DateTime.now().toUtc();

  static DateTime dateOnlyUtc(DateTime value) {
    return DateTime.utc(value.year, value.month, value.day);
  }

  static DateTime startOfTodayUtc() {
    final now = nowUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }

  static DateTime addMonths(DateTime date, int months) {
    final totalMonths = date.month + months;
    final year = date.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final day = date.day;

    final lastDay = DateTime.utc(year, month + 1, 0).day;

    return DateTime.utc(
      year,
      month,
      day > lastDay ? lastDay : day,
    );
  }

  static DateTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String compactDate(DateTime? value) {
    if (value == null) return '-';

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    return '$day/$month/$year';
  }

  static String compactDateTime(DateTime? value) {
    if (value == null) return '-';

    final local = value.toLocal();
    final date = compactDate(local);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$date $hour:$minute';
  }
}