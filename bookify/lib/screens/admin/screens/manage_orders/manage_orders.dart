import 'package:bookify/screens/admin/screens/dashboard.dart';
import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/adminbottomnavbar.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageOrders extends StatefulWidget {
  const ManageOrders({super.key});

  @override
  State<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends State<ManageOrders> {
  final auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;

  final List<String> statusOptions = [
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  Map<String, Map<String, dynamic>> _userMap = {};
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      final map = <String, Map<String, dynamic>>{};
      for (var doc in snap.docs) {
        map[doc.id] = doc.data();
      }
      if (!mounted) return;
      setState(() {
        _userMap = map;
        _loadingUsers = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> updateOrderStatus(
    String userId,
    String orderId,
    String newStatus,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        navigateWithFade(context, const Dashboard());
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFeeeeee),
        bottomNavigationBar: buildAdminCurvedNavBar(context, 3),
        body: SafeArea(
          child: _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    _buildHeader(),
                    if (_showSearchBar) _buildSearchBar(),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Text(
                          "Manage Orders",
                          style: TextStyle(
                            color: MyColors.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: _buildOrdersList()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage("assets/images/b.jpg"),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hi, Admin", style: MyTextTheme.lightTextTheme.titleLarge),
              const Text(
                "Administrator",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: MyColors.primary),
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: MyColors.primary),
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignIn()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by user email...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('orders')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading orders.",
              style: TextStyle(color: MyColors.primary),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs;

        final filtered = orders.where((doc) {
          final userId = doc.reference.path.split('/')[1];
          final email = _userMap[userId]?['email'] ?? '';
          return email.toLowerCase().contains(
            _searchController.text.trim().toLowerCase(),
          );
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              "No orders yet.",
              style: TextStyle(color: MyColors.primary),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.path.split('/')[1];
            final orderId = doc.id;

            final user = _userMap[userId] ?? {};
            final userName = user['name'] ?? 'Unknown';
            final userEmail = user['email'] ?? 'Unknown';
            final userImage = user['profile_image_url'];
            final total = (data['itemsTotal'] ?? 0).toDouble();
            final status = data['status'] ?? 'Processing';

            final timestamp = data['orderDate'] as Timestamp?;
            final date = timestamp?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: MyColors.primary.withOpacity(0.3), // Teal shadow
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: User Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: userImage != null
                              ? NetworkImage(userImage)
                              : const AssetImage("assets/images/b.jpg")
                                    as ImageProvider,
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  color: MyColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row 2: Order ID
                    Row(
                      children: [
                        const Text(
                          "Order ID:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MyColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SelectableText(
                            orderId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange,
                            ),
                            maxLines: 1,
                            toolbarOptions: const ToolbarOptions(copy: true),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Row 3: Order Date
                    Text(
                      "Order Date: ${date != null ? date.toString().split(' ').first : 'Unknown'}",
                      style: const TextStyle(color: Colors.black87),
                    ),

                    const SizedBox(height: 8),

                    // Row 4: Total and Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Price: \$${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: MyColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: MyColors.primary),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: MyColors.primary,
                              ),
                              style: const TextStyle(
                                color: MyColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              dropdownColor: Colors.white,
                              items: statusOptions.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                );
                              }).toList(),
                              onChanged: (newStatus) {
                                if (newStatus != null) {
                                  updateOrderStatus(userId, orderId, newStatus);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
