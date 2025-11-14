import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartManager {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _userCartRef() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid).collection('cartItems');
  }

  static Future<void> addToCart(CartItem item) async {
    try {
      final ref = _userCartRef().doc(item.bookId);
      final doc = await ref.get();
      if (doc.exists) {
        await ref.update({'quantity': FieldValue.increment(1)});
      } else {
        await ref.set(item.toMap());
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

static Future<void> removeFromCart(String bookId, BuildContext context, {State? state}) async {
  try {
    await _userCartRef().doc(bookId).delete();

    // ✅ Only show Snackbar if widget is mounted
    if (state != null && state.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item removed from cart")),
      );
    }
  } catch (e) {
    if (state != null && state.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing item: ${e.toString()}")),
      );
    }
  }
}

  static Future<void> updateQuantity(
    String bookId,
    int quantity,
    BuildContext context,
  ) async {
    try {
      if (quantity < 1) {
        await removeFromCart(bookId, context);
      } else {
        await _userCartRef().doc(bookId).update({'quantity': quantity});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating quantity: ${e.toString()}")),
      );
    }
  }

  static Stream<List<CartItem>> getCartStream() {
    return _userCartRef().snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => CartItem.fromMap(doc.data())).toList(),
    );
  }

  static Future<void> batchRemoveCartItems(List<CartItem> cartItems) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final item in cartItems) {
        final itemRef = _userCartRef().doc(item.bookId);
        batch.delete(itemRef);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove cart items: $e');
    }
  }
}
