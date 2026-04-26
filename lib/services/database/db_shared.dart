import 'package:invenman/app/core/money_utils.dart';
import 'package:invenman/app/core/date_time_utils.dart';

class DbShared {
  const DbShared._();

  static DateTime nowUtc() {
    return DateTimeUtils.nowUtc();
  }

  static DateTime startOfTodayUtc() {
    return DateTimeUtils.startOfTodayUtc();
  }

  static DateTime addMonths(DateTime date, int months) {
    return DateTimeUtils.addMonths(date, months);
  }

  static double roundMoney(double value) {
    return MoneyUtils.round(value);
  }

  static double wholeMoney(double value) {
    return MoneyUtils.whole(value);
  }
}