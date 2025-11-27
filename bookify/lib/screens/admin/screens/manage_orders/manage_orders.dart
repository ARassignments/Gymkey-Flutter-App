import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/utils/themes/themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/search_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageOrders extends ConsumerStatefulWidget {
  const ManageOrders({super.key});

  @override
  ConsumerState<ManageOrders> createState() => _ManageOrdersState();
}

class _ManageOrdersState extends ConsumerState<ManageOrders>
    with AutomaticKeepAliveClientMixin {
  final auth = FirebaseAuth.instance;

  final List<String> statusOptions = [
    'Pending',
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

  @override
  bool get wantKeepAlive => true;

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
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      body: SafeArea(
        child: _loadingUsers
            ? const Center(child: LoadingLogo())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: _buildOrdersList(searchQuery))],
              ),
      ),
    );
  }

  Widget _buildOrdersList(String searchQuery) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: NotFoundWidget(title: "Orders not found", message: ""),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: LoadingLogo());
        }

        final orders = snapshot.data!.docs;

        final filtered = orders.where((doc) {
          final userId = doc.reference.path.split('/')[1];
          final email = _userMap[userId]?['email'] ?? '';
          return email.toLowerCase().contains(searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: NotFoundWidget(title: "No orders yet", message: ""),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.reference.path.split('/')[1];
            final orderId = doc.id;

            final user = _userMap[userId] ?? {};
            final userName = user['name'] ?? 'Unknown';
            final userEmail = user['email'] ?? 'Unknown';
            final userImage = user['profile_image_url'];
            final total = (data['totalAmount'] ?? 0).toDouble();
            final status = data['status'] ?? 'Processing';

            final timestamp = data['orderDate'] as Timestamp?;
            final date = timestamp?.toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                style: AppTheme.textTitle(context),
                              ),
                              Text(
                                userEmail,
                                style: AppTheme.textSearchInfoLabeled(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.sliderHighlightBg(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "# ",
                                      style: AppTheme.textSearchInfoLabeled(
                                        context,
                                      ).copyWith(fontSize: 14),
                                    ),
                                    Text(
                                      orderId,
                                      style: AppTheme.textTitle(context),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Order Place On ${date != null ? DateFormat('MMM dd, yyyy | hh:mm a').format(date) : 'Unknown'}",
                                  style: AppTheme.textSearchInfoLabeled(
                                    context,
                                  ).copyWith(fontSize: 12),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Total Amount: \$${total}",
                                  style: AppTheme.textLabel(context).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            height: 25,
                            decoration: BoxDecoration(
                              color: AppTheme.sliderHighlightBg(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                borderRadius: BorderRadius.circular(12),
                                padding: EdgeInsets.all(0),
                                elevation: 0,
                                value: status,
                                icon: Icon(
                                  HugeIconsStroke.arrowDown01,
                                  color: AppTheme.iconColorThree(context),
                                ),
                                style: AppTheme.textSearchInfoLabeled(
                                  context,
                                ).copyWith(fontSize: 12),
                                dropdownColor: AppTheme.screenBg(context),
                                items: statusOptions.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  );
                                }).toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    updateOrderStatus(
                                      userId,
                                      orderId,
                                      newStatus,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
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
