class PaymentTypes {
  const PaymentTypes._();

  static const direct = 'direct';
  static const installment = 'installment';

  static bool isValid(String value) {
    return value == direct || value == installment;
  }
}

class InstallmentPlanStatuses {
  const InstallmentPlanStatuses._();

  static const active = 'active';
  static const completed = 'completed';
  static const overdue = 'overdue';
}

class InstallmentPaymentStatuses {
  const InstallmentPaymentStatuses._();

  static const pending = 'pending';
  static const partial = 'partial';
  static const paid = 'paid';
  static const overdue = 'overdue';
}