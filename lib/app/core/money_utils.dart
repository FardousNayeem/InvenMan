class MoneyUtils {
  const MoneyUtils._();

  static const double epsilon = 0.009;

  static double round(double value) {
    return ((value * 100).round()) / 100.0;
  }

  static double whole(double value) {
    if (value <= 0) return 0;
    return value.roundToDouble();
  }

  static bool same(double a, double b) {
    return (round(a) - round(b)).abs() < epsilon;
  }

  static String text(num value) {
    return round(value.toDouble()).toStringAsFixed(0);
  }

  static bool isPositive(num value) {
    return value > epsilon;
  }

  static bool isNegative(num value) {
    return value < -epsilon;
  }

  static bool isZero(num value) {
    return value.abs() < epsilon;
  }
}