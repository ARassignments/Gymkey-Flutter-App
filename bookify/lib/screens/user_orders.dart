import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/app_navbar.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => _UserOrdersState();
}

class _UserOrdersState extends State<UserOrders> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> cancelOrder(String orderId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders')
        .doc(orderId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order cancelled successfully.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            CustomNavBar(searchController: searchController),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Your Orders",
                style: TextStyle(
                  color: MyColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('orders')
                    .orderBy('orderDate', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No orders yet.",
                        style: TextStyle(color: MyColors.primary),
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: orders.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final doc = orders[index];
                      final order = doc.data() as Map<String, dynamic>;

                      final orderId = doc.id;
                      final status = order['status'] ?? 'Processing';
                      final timestamp = order['orderDate'];
                      final total = order['itemsTotal']?.toDouble() ?? 0.0;
                      final items = List<Map<String, dynamic>>.from(
                        order['items'] ?? [],
                      );

                      String formattedDate = 'Unknown';
                      String deliveryDate = 'Unknown';

                      if (timestamp is Timestamp) {
                        final orderDate = timestamp.toDate();
                        formattedDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(orderDate);
                        deliveryDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(orderDate.add(const Duration(days: 7)));
                      }

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🧾 Order ID
                              Row(
                                children: [
                                  const Text(
                                    "Order ID: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: MyColors.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: SelectableText(
                                      orderId,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.teal,
                                      ),
                                      maxLines: 1,
                                      showCursor: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 🟠 Status
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  backgroundColor: status == 'Delivered'
                                      ? Colors.green.shade100
                                      : status == 'Cancelled'
                                      ? Colors.red.shade100
                                      : Colors.orange.shade100,
                                  label: Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'Delivered'
                                          ? Colors.green
                                          : status == 'Cancelled'
                                          ? Colors.red
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 📆 Dates
                              Text(
                                "Order Date: $formattedDate",
                                style: const TextStyle(color: Colors.teal),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Delivery Date: $deliveryDate",
                                style: const TextStyle(color: Colors.teal),
                              ),
                              const SizedBox(height: 12),

                              // 📚 Items
                              if (items.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: items.map((book) {
                                    return Text(
                                      "• ${book['title']} x${book['quantity'] ?? 1}",
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 12),

                              // 💵 Total
                              Text(
                                "Total: \$${total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: MyColors.primary,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 6),

                              // ❌ Cancel Button
                              if (status != 'Delivered' &&
                                  status != 'Cancelled')
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => cancelOrder(orderId),
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      "Cancel Order",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
