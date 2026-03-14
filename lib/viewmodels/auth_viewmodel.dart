import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ── Profile fields (cached from Firestore) ─────────────────────────────
  String _displayName = '';
  String _avatarUrl = '';
  String _phone = '';
  String _city = 'Бишкек';

  String get displayName =>
      _displayName.isNotEmpty ? _displayName : (currentUser?.email ?? '');
  String get avatarUrl => _avatarUrl;
  String get phone => _phone;
  String get city => _city;

  AuthViewModel() {
    _auth.authStateChanges().listen((user) {
      if (user != null) _loadProfile();
      notifyListeners();
    });
  }

  // ── Auth actions ───────────────────────────────────────────────────────
  String? _error;
  String? get error => _error;

  bool _loading = false;
  bool get loading => _loading;

  Future<bool> signUp(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      // Create default profile doc
      await _db.collection('users').doc(cred.user!.uid).set({
        'email': email.trim(),
        'displayName': '',
        'avatarUrl': '',
        'phone': '',
        'city': 'Бишкек',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _displayName = '';
    _avatarUrl = '';
    _phone = '';
    _city = 'Бишкек';
    notifyListeners();
  }

  // ── Profile management ────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _displayName = data['displayName'] ?? '';
        _avatarUrl = data['avatarUrl'] ?? '';
        _phone = data['phone'] ?? '';
        _city = data['city'] ?? 'Бишкек';
        notifyListeners();
      }
    } catch (_) {
      // Firestore may be unreachable — keep defaults
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? phone,
    String? city,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) {
      _displayName = displayName;
      updates['displayName'] = displayName;
    }
    if (avatarUrl != null) {
      _avatarUrl = avatarUrl;
      updates['avatarUrl'] = avatarUrl;
    }
    if (phone != null) {
      _phone = phone;
      updates['phone'] = phone;
    }
    if (city != null) {
      _city = city;
      updates['city'] = city;
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Этот email уже зарегистрирован';
      case 'invalid-email':
        return 'Неверный формат email';
      case 'weak-password':
        return 'Пароль слишком короткий (мин. 6 символов)';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      case 'invalid-credential':
        return 'Неверный email или пароль';
      default:
        return 'Ошибка авторизации ($code)';
    }
  }
}
