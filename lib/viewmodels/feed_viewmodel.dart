import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FeedViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── State ──────────────────────────────────────────────────────────────
  String _selectedCategory = 'Все';
  String get selectedCategory => _selectedCategory;

  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  List<Product> get products => _selectedCategory == 'Все'
      ? List.unmodifiable(_products)
      : List.unmodifiable(
          _products.where((p) => p.category == _selectedCategory));

  List<Product> get favorites =>
      List.unmodifiable(_products.where((p) => p.isFavorite));

  bool get isLoading => _isLoading;
  String? get error => _error;

  FeedViewModel() {
    loadProducts();
  }

  // ── Load from Firestore (real-time stream) ────────────────────────────
  void loadProducts() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _products = snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Не удалось загрузить объявления';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────
  void filterByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Toggle favorite (local only — not persisted to Firestore).
  bool toggleFavorite(String id) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx == -1) return false;
    _products[idx].isFavorite = !_products[idx].isFavorite;
    notifyListeners();
    return _products[idx].isFavorite;
  }

  /// Add a new product listing to Firestore.
  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toMap());
    // Stream will auto-update the list
  }

  /// Delete a product listing from Firestore.
  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // ── Categories ─────────────────────────────────────────────────────────
  static const List<String> categories = [
    'Все',
    'Транспорт',
    'Недвижимость',
    'Услуги',
    'Дом и сад',
    'Техника и электроника',
  ];
}
