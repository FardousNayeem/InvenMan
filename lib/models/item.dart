import 'dart:convert';

class Item {
  final int? id;
  final String name;
  final String description;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int quantity;
  final String supplier;
  final Map<String, int> warranties;
  final List<String> imagePaths;
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
    required this.supplier,
    this.warranties = const {},
    this.imagePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromMap(Map<String, dynamic> map) {
    final warrantiesJson = map['warranties_json'] as String? ?? '{}';
    final imagePathsJson = map['image_paths_json'] as String? ?? '[]';

    final decodedWarranties = jsonDecode(warrantiesJson) as Map<String, dynamic>;
    final decodedImagePaths = jsonDecode(imagePathsJson) as List<dynamic>;

    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      supplier: map['supplier'] as String? ?? '',
      warranties: decodedWarranties.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      imagePaths: decodedImagePaths.map((e) => e.toString()).toList(),
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
      'supplier': supplier,
      'warranties_json': jsonEncode(warranties),
      'image_paths_json': jsonEncode(imagePaths),
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
    String? supplier,
    Map<String, int>? warranties,
    List<String>? imagePaths,
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
      supplier: supplier ?? this.supplier,
      warranties: warranties ?? this.warranties,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}