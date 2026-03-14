import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final int price;
  final String imageUrl;
  final String location;
  final String category;
  final DateTime createdAt;
  final String userId;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    required this.imageUrl,
    required this.location,
    required this.category,
    required this.createdAt,
    this.userId = '',
    this.isFavorite = false,
  });

  String get formattedPrice {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} KGS';
  }

  /// Serialize to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'location': location,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  /// Deserialize from Firestore document.
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0) is int
          ? map['price']
          : (map['price'] as num).toInt(),
      imageUrl: map['imageUrl'] ?? '',
      location: map['location'] ?? 'Бишкек',
      category: map['category'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }
}
