class PrivacyFields {
  const PrivacyFields._();

  static const sensitiveLabels = {
    'cost',
    'sell',
    'selling',
    'mrp',
    'profit',
    'paid',
    'payment',
    'down payment',
    'remaining',
    'balance',
    'monthly',
    'amount',
    'due',
    'customer',
    'phone',
    'address',
    'supplier',
  };

  static bool isSensitiveLabel(String label) {
    final normalized = label.trim().toLowerCase();

    if (normalized.isEmpty) return false;

    return sensitiveLabels.any(
      (sensitive) => normalized.contains(sensitive),
    );
  }
}