class InstallmentPayment {
  final int? id;
  final int installmentPlanId;
  final int installmentNumber;
  final DateTime dueDate;
  final DateTime? paidDate;
  final double amountDue;
  final double amountPaid;
  final String status; // pending, partial, paid, overdue
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPayment({
    this.id,
    required this.installmentPlanId,
    required this.installmentNumber,
    required this.dueDate,
    this.paidDate,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';

  factory InstallmentPayment.fromMap(Map<String, dynamic> map) {
    return InstallmentPayment(
      id: map['id'] as int?,
      installmentPlanId: map['installment_plan_id'] as int,
      installmentNumber: map['installment_number'] as int,
      dueDate: DateTime.parse(map['due_date'] as String),
      paidDate: map['paid_date'] != null
          ? DateTime.parse(map['paid_date'] as String)
          : null,
      amountDue: (map['amount_due'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      status: map['status'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'installment_plan_id': installmentPlanId,
      'installment_number': installmentNumber,
      'due_date': dueDate.toIso8601String(),
      'paid_date': paidDate?.toIso8601String(),
      'amount_due': amountDue,
      'amount_paid': amountPaid,
      'status': status,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InstallmentPayment copyWith({
    int? id,
    int? installmentPlanId,
    int? installmentNumber,
    DateTime? dueDate,
    DateTime? paidDate,
    bool clearPaidDate = false,
    double? amountDue,
    double? amountPaid,
    String? status,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPayment(
      id: id ?? this.id,
      installmentPlanId: installmentPlanId ?? this.installmentPlanId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
      amountDue: amountDue ?? this.amountDue,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}