import '/models/cart_item.dart';
import '/managers/cart_manager.dart';
import '/screens/home.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/app_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Checkout extends StatefulWidget {
  const Checkout({super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;
  List<CartItem> cartItems = [];
  double deliveryCharge = 2.0;
  String userAddress = "Loading address...";

  @override
  void initState() {
    super.initState();
    _loadCart();
    _loadUserAddress();
  }

  Future<void> _loadCart() async {
    CartManager.getCartStream().listen((items) {
      setState(() {
        cartItems = items;
      });
    });
  }

  Future<void> _loadUserAddress() async {
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('address')) {
        setState(() {
          userAddress = doc['address'];
        });
      } else {
        setState(() {
          userAddress = "No address found. Please update your profile.";
        });
      }
    }
  }

  double get itemsTotal =>
      cartItems.fold(0.0, (total, item) => total + item.price * item.quantity);

  double get totalAmount => itemsTotal + deliveryCharge;

  Future<void> _placeOrder() async {
    final uid = auth.currentUser?.uid;
    if (uid == null || cartItems.isEmpty) return;

    final orderData = {
      'userId': uid,
      'orderDate': Timestamp.now(),
      'items': cartItems.map((e) => e.toMap()).toList(),
      'itemsTotal': itemsTotal,
      'deliveryCharge': deliveryCharge,
      'totalAmount': totalAmount,
      'shippingAddress': userAddress,
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .add(orderData);

      await CartManager.batchRemoveCartItems(cartItems);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// 🔹 Address Card
                    _buildCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              color: MyColors.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              userAddress,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🔹 Order Summary Card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MyColors.primary,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _summaryRow("Items Total",
                              "\$${itemsTotal.toStringAsFixed(2)}"),
                          const SizedBox(height: 8),
                          _summaryRow("Delivery Charges",
                              "\$${deliveryCharge.toStringAsFixed(2)}"),
                          const Divider(height: 25, thickness: 1.2),
                          _summaryRow(
                            "Total",
                            "\$${totalAmount.toStringAsFixed(2)}",
                            bold: true,
                            valueColor: MyColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            /// ✅ Place Order Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14,horizontal: 110),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: MyColors.primary,
                    elevation: 6,
                  ),
                  child: const Text(
                    "Place Order",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card wrapper with shadow
  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Helper method for summary rows
  Row _summaryRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: MyColors.primary,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.teal,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
