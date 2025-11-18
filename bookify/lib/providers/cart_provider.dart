import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final Ref ref;
  CartNotifier(this.ref) : super([]) {
    _init();
  }

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _userCartRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    return _db.collection('users').doc(uid).collection('cartItems');
  }

  void _init() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _userCartRef().snapshots().listen((snapshot) {
        final cart = snapshot.docs
            .map((doc) => CartItem.fromMap(doc.data()))
            .toList();
        state = cart;
      });
    }
  }

  Future<void> addToCart(CartItem item) async {
    final ref = _userCartRef().doc(item.bookId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.update({'quantity': FieldValue.increment(1)});
    } else {
      await ref.set(item.toMap());
    }
  }

  Future<void> removeFromCart(String bookId) async {
    await _userCartRef().doc(bookId).delete();
  }

  Future<void> updateQuantity(String bookId, int quantity, int stock) async {
    if (quantity < 1) return; // minimum check
    if (quantity > stock) return; // maximum stock check

    await _userCartRef().doc(bookId).update({'quantity': quantity});
  }

  Future<void> batchRemoveCartItems(List<CartItem> items) async {
    final batch = _db.batch();
    for (final item in items) {
      batch.delete(_userCartRef().doc(item.bookId));
    }
    await batch.commit();
  }

  double get totalPrice =>
      state.fold(0, (sum, item) => sum + (item.price * item.quantity));
}
