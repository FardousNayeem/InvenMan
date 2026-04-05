class Item {
  final int? id;
  final String name;
  final String description;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final int? warrantyMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    this.warrantyMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      warrantyMonths: map['warranty_months'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'warranty_months': warrantyMonths,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    double? costPrice,
    double? sellingPrice,
    int? quantity,
    int? warrantyMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}