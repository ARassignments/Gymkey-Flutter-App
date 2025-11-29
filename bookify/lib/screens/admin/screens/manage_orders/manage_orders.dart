import 'package:bookify/components/appsnackbar.dart';
import 'package:bookify/screens/order_detail.dart';
import 'package:bookify/utils/constants/colors.dart';
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
    'Confirmed',
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
    switch (newStatus.toLowerCase()) {
      case 'confirmed':
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'status': newStatus,
              "tracking.confirmedAt": Timestamp.now(),
            });
      case 'shipped':
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'status': newStatus,
              "tracking.shippedAt": Timestamp.now(),
            });
      case 'delivered':
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'status': newStatus,
              "tracking.deliveredAt": Timestamp.now(),
            });
      case 'cancelled':
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'status': newStatus,
              "tracking.cancelledAt": Timestamp.now(),
            });
    }
    AppSnackBar.show(
      context,
      message: "This order now $newStatus successfully",
      type: AppSnackBarType.success,
    );
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

  Color? getStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return AppColor.accent_50;
      case 'delivered':
        return Colors.green;
      default:
        return Theme.of(context).brightness == Brightness.dark
            ? AppColor.neutral_50
            : AppColor.neutral_40;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return HugeIconsSolid.packageRemove;
      case 'delivered':
        return HugeIconsSolid.packageDelivered;
      case 'shipped':
        return HugeIconsSolid.deliveryTruck02;
      case 'pending':
        return HugeIconsSolid.packageProcess;
      default:
        return HugeIconsSolid.packageOpen;
    }
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
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'] ?? "";
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
            final userId = data['userId'];
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
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    OrderDetailsPage(orderId: orderId),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(0.0, 1.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                      child: Container(
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
                                    final currentIndex = statusOptions.indexOf(
                                      status,
                                    );
                                    final optionIndex = statusOptions.indexOf(
                                      s,
                                    );
                                    bool isDisabled = false;
                                    if (status == "Cancelled") {
                                      isDisabled = true;
                                    } else if (s == "Cancelled" &&
                                        status != "Pending") {
                                      isDisabled = true;
                                    } else if (optionIndex < currentIndex) {
                                      isDisabled = true;
                                    }

                                    return DropdownMenuItem(
                                      value: s,
                                      enabled: !isDisabled,
                                      child: Row(
                                        spacing: 6,
                                        children: [
                                          Icon(
                                            getStatusIcon(s),
                                            color: isDisabled
                                                ? s != "Cancelled"
                                                      ? getStatusColor(
                                                          context,
                                                          s,
                                                        )?.withOpacity(0.5)
                                                      : getStatusColor(
                                                          context,
                                                          s,
                                                        )
                                                : getStatusColor(context, s),
                                            size: 18,
                                          ),
                                          Text(
                                            s,
                                            style: TextStyle(
                                              color: isDisabled
                                                  ? s != "Cancelled"
                                                        ? getStatusColor(
                                                            context,
                                                            s,
                                                          )?.withOpacity(0.5)
                                                        : getStatusColor(
                                                            context,
                                                            s,
                                                          )
                                                  : getStatusColor(context, s),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus == null) return;
                                    if (newStatus == status) return;
                                    if (status == "Cancelled") return;

                                    final currentIndex = statusOptions.indexOf(
                                      status,
                                    );
                                    final newIndex = statusOptions.indexOf(
                                      newStatus,
                                    );
                                    if (newIndex < currentIndex) {
                                      return;
                                    }
                                    if (newStatus == "Cancelled" &&
                                        status != "Pending") {
                                      return;
                                    }

                                    showModalBottomSheet(
                                      context: context,
                                      isDismissible: false,
                                      enableDrag: false,
                                      showDragHandle: true,
                                      isScrollControlled: true,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(30),
                                        ),
                                      ),
                                      builder: (context) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            bottom:
                                                MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                20,
                                            left: 20,
                                            right: 20,
                                          ),
                                          child: Column(
                                            spacing: 16,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Change Order Status?",
                                                textAlign: TextAlign.center,
                                                style:
                                                    AppTheme.textLabel(
                                                      context,
                                                    ).copyWith(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              Divider(
                                                height: 1,
                                                color: AppTheme.dividerBg(
                                                  context,
                                                ),
                                              ),

                                              Text(
                                                "Are you sure you want to change status to '$newStatus'?",
                                                textAlign: TextAlign.center,
                                                style: AppTheme.textLabel(
                                                  context,
                                                ),
                                              ),

                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      newStatus == 'Cancelled'
                                                      ? AppColor.accent_50
                                                      : newStatus == 'Delivered'
                                                      ? Colors.green[900]
                                                      : Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                      ? Colors.white
                                                      : MyColors.primary,
                                                ),
                                                onPressed: () async {
                                                  Navigator.pop(context);

                                                  updateOrderStatus(
                                                    userId,
                                                    orderId,
                                                    newStatus,
                                                  );
                                                },
                                                child: Text(
                                                  "Yes, $newStatus",
                                                  style: TextStyle(
                                                    color:
                                                        (newStatus ==
                                                                'Cancelled' ||
                                                            newStatus ==
                                                                'Delivered')
                                                        ? Colors.white
                                                        : Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                        ? Colors.black
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),

                                              OutlinedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text("Cancel"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
