import 'dart:convert';

class SaleRecord {
  final int? id;
  final int? itemId;
  final String itemName;
  final String category;
  final int quantitySold;
  final double costPrice;
  final double sellPrice;
  final double profit;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  final String paymentType;
  final int? installmentMonths;

  final Map<String, int> warranties;
  final List<String> imagePaths;

  final DateTime soldAt;

  const SaleRecord({
    this.id,
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantitySold,
    required this.costPrice,
    required this.sellPrice,
    required this.profit,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.paymentType,
    this.installmentMonths,
    this.warranties = const {},
    this.imagePaths = const [],
    required this.soldAt,
  });

  bool get isInstallment => paymentType == 'installment';

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    final warrantiesJson = map['warranties_json'] as String? ?? '{}';
    final imagePathsJson = map['image_paths_json'] as String? ?? '[]';

    final decodedWarranties = jsonDecode(warrantiesJson) as Map<String, dynamic>;
    final decodedImagePaths = jsonDecode(imagePathsJson) as List<dynamic>;

    return SaleRecord(
      id: map['id'] as int?,
      itemId: map['item_id'] as int?,
      itemName: map['item_name'] as String,
      category: map['category'] as String,
      quantitySold: map['quantity_sold'] as int,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      profit: (map['profit'] as num).toDouble(),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerAddress: map['customer_address'] as String?,
      paymentType: (map['payment_type'] as String?) ?? 'direct',
      installmentMonths: map['installment_months'] as int?,
      warranties: decodedWarranties.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      imagePaths: decodedImagePaths.map((e) => e.toString()).toList(),
      soldAt: DateTime.parse(map['sold_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'category': category,
      'quantity_sold': quantitySold,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'profit': profit,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'payment_type': paymentType,
      'installment_months': installmentMonths,
      'warranties_json': jsonEncode(warranties),
      'image_paths_json': jsonEncode(imagePaths),
      'sold_at': soldAt.toIso8601String(),
    };
  }

  SaleRecord copyWith({
    int? id,
    int? itemId,
    String? itemName,
    String? category,
    int? quantitySold,
    double? costPrice,
    double? sellPrice,
    double? profit,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? paymentType,
    int? installmentMonths,
    Map<String, int>? warranties,
    List<String>? imagePaths,
    DateTime? soldAt,
  }) {
    return SaleRecord(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantitySold: quantitySold ?? this.quantitySold,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      profit: profit ?? this.profit,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      paymentType: paymentType ?? this.paymentType,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      warranties: warranties ?? this.warranties,
      imagePaths: imagePaths ?? this.imagePaths,
      soldAt: soldAt ?? this.soldAt,
    );
  }
}