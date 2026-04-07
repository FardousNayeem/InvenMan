import 'dart:convert';

class SaleRecord {
  final int? id;
  final int itemId;
  final String itemName;
  final String category;
  final int quantitySold;
  final double costPrice;
  final double sellPrice;
  final double profit;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  final Map<String, int> warranties;

  final DateTime soldAt;

  SaleRecord({
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
    this.warranties = const {},
    required this.soldAt,
  });

  factory SaleRecord.fromMap(Map<String, dynamic> map) {
    final warrantiesJson = map['warranties_json'] as String? ?? '{}';
    final decodedWarranties = jsonDecode(warrantiesJson) as Map<String, dynamic>;

    return SaleRecord(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      itemName: map['item_name'] as String,
      category: map['category'] as String,
      quantitySold: map['quantity_sold'] as int,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      profit: (map['profit'] as num).toDouble(),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerAddress: map['customer_address'] as String?,
      warranties: decodedWarranties.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
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
      'warranties_json': jsonEncode(warranties),
      'sold_at': soldAt.toIso8601String(),
    };
  }
}