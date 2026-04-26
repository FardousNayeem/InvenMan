import 'dart:convert';
import 'package:invenman/app/core/domain_constants.dart';

class InstallmentPlan {
  final int? id;
  final int saleRecordId;
  final String itemName;
  final String category;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final List<String> installmentImagePaths;

  final double totalAmount;
  final double downPayment;
  final double financedAmount;
  final int durationMonths;
  final double monthlyAmount;

  final DateTime startDate;
  final DateTime? nextDueDate;

  final int paidMonths;
  final int remainingMonths;
  final double totalPaid;
  final double remainingBalance;

  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InstallmentPlan({
    this.id,
    required this.saleRecordId,
    required this.itemName,
    required this.category,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.installmentImagePaths = const [],
    required this.totalAmount,
    required this.downPayment,
    required this.financedAmount,
    required this.durationMonths,
    required this.monthlyAmount,
    required this.startDate,
    this.nextDueDate,
    required this.paidMonths,
    required this.remainingMonths,
    required this.totalPaid,
    required this.remainingBalance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == InstallmentPlanStatuses.completed;
  bool get isOverdue => status == InstallmentPlanStatuses.overdue;
  bool get isActive => status == InstallmentPlanStatuses.active;

  factory InstallmentPlan.fromMap(Map<String, dynamic> map) {
    final installmentImagesJson = map['image_paths_json'] as String? ?? '[]';
    final decodedInstallmentImages =
        jsonDecode(installmentImagesJson) as List<dynamic>;

    return InstallmentPlan(
      id: map['id'] as int?,
      saleRecordId: map['sale_record_id'] as int,
      itemName: map['item_name'] as String,
      category: map['category'] as String,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerAddress: map['customer_address'] as String?,
      installmentImagePaths:
          decodedInstallmentImages.map((e) => e.toString()).toList(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      downPayment: (map['down_payment'] as num).toDouble(),
      financedAmount: (map['financed_amount'] as num).toDouble(),
      durationMonths: map['duration_months'] as int,
      monthlyAmount: (map['monthly_amount'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      nextDueDate: map['next_due_date'] != null
          ? DateTime.parse(map['next_due_date'] as String)
          : null,
      paidMonths: map['paid_months'] as int,
      remainingMonths: map['remaining_months'] as int,
      totalPaid: (map['total_paid'] as num).toDouble(),
      remainingBalance: (map['remaining_balance'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_record_id': saleRecordId,
      'item_name': itemName,
      'category': category,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'image_paths_json': jsonEncode(installmentImagePaths),
      'total_amount': totalAmount,
      'down_payment': downPayment,
      'financed_amount': financedAmount,
      'duration_months': durationMonths,
      'monthly_amount': monthlyAmount,
      'start_date': startDate.toIso8601String(),
      'next_due_date': nextDueDate?.toIso8601String(),
      'paid_months': paidMonths,
      'remaining_months': remainingMonths,
      'total_paid': totalPaid,
      'remaining_balance': remainingBalance,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InstallmentPlan copyWith({
    int? id,
    int? saleRecordId,
    String? itemName,
    String? category,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    List<String>? installmentImagePaths,
    double? totalAmount,
    double? downPayment,
    double? financedAmount,
    int? durationMonths,
    double? monthlyAmount,
    DateTime? startDate,
    DateTime? nextDueDate,
    bool clearNextDueDate = false,
    int? paidMonths,
    int? remainingMonths,
    double? totalPaid,
    double? remainingBalance,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InstallmentPlan(
      id: id ?? this.id,
      saleRecordId: saleRecordId ?? this.saleRecordId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      installmentImagePaths:
          installmentImagePaths ?? this.installmentImagePaths,
      totalAmount: totalAmount ?? this.totalAmount,
      downPayment: downPayment ?? this.downPayment,
      financedAmount: financedAmount ?? this.financedAmount,
      durationMonths: durationMonths ?? this.durationMonths,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      startDate: startDate ?? this.startDate,
      nextDueDate: clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      paidMonths: paidMonths ?? this.paidMonths,
      remainingMonths: remainingMonths ?? this.remainingMonths,
      totalPaid: totalPaid ?? this.totalPaid,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}