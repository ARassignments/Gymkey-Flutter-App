import '/components/appsnackbar.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/screens/order_detail.dart';
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';

class UserOrders extends StatefulWidget {
  const UserOrders({super.key});

  @override
  State<UserOrders> createState() => _UserOrdersState();
}

class _UserOrdersState extends State<UserOrders>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> cancelOrder(String orderId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders')
        .doc(orderId)
        .update({
          "status": "Cancelled",
          "tracking.cancelledAt": Timestamp.now(),
        });

    AppSnackBar.show(
      context,
      message: "Order cancelled successfully.",
      type: AppSnackBarType.success,
    );
  }

  Widget buildOrdersList({required String uid, required bool filterCompleted}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingLogo());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: NotFoundWidget(
              title: "You don't have an order yet",
              message: filterCompleted
                  ? "You don't have an complete orders at this time"
                  : "You don't have an active orders at this time",
            ),
          );
        }

        // FILTER ORDERS
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';

          if (filterCompleted) {
            return status == 'Delivered' || status == 'Completed';
          } else {
            return status != 'Delivered' && status != 'Completed';
          }
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: NotFoundWidget(
              title: "You don't have an order yet",
              message: filterCompleted
                  ? "You don't have an complete orders at this time"
                  : "You don't have an active orders at this time",
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final order = doc.data() as Map<String, dynamic>;

            return buildOrderCard(doc.id, order);
          },
        );
      },
    );
  }

  Widget buildOrderCard(String orderId, Map<String, dynamic> order) {
    final status = order['status'] ?? 'Processing';
    final timestamp = order['orderDate'];
    final total = order['totalAmount']?.toDouble() ?? 0.0;
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

    String formattedDate = "Unknown";

    if (timestamp is Timestamp) {
      final orderDate = timestamp.toDate();
      formattedDate = DateFormat('MMM dd, yyyy | hh:mm a').format(orderDate);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                OrderDetailsPage(orderId: orderId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      child: Card(
        elevation: 0,
        color: AppTheme.customListBg(context),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 16,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Book Image
                  Container(
                    width: 120,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: NetworkImage(
                          items.isNotEmpty ? items[0]['imageUrl'] ?? '' : '',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Book Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "# ",
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 14),
                            ),
                            Text(orderId, style: AppTheme.textTitle(context)),
                          ],
                        ),

                        Text(
                          "Order Place On $formattedDate",
                          style: AppTheme.textSearchInfoLabeled(
                            context,
                          ).copyWith(fontSize: 12),
                        ),

                        const SizedBox(height: 4),

                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6,vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'Delivered'
                                ? Colors.green.shade50
                                : status == 'Cancelled'
                                ? Colors.red.shade50
                                : AppTheme.sliderHighlightBg(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: AppTheme.textSearchInfoLabeled(context)
                                .copyWith(
                                  color: status == 'Delivered'
                                      ? Colors.green
                                      : status == 'Cancelled'
                                      ? Colors.red
                                      : AppTheme.iconColorThree(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 6,
                          children: [
                            Text(
                              "\$${total}",
                              style: AppTheme.textLabel(context).copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (status != 'Delivered' && status != 'Cancelled')
                              TextButton.icon(
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "My Orders",
          style: AppTheme.textTitle(context).copyWith(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.iconColor(context),
          unselectedLabelColor: AppTheme.iconColorThree(context),
          labelStyle: AppTheme.textTitle(context),
          indicatorColor: AppTheme.iconColor(context),
          splashFactory: null,
          overlayColor: null,
          dividerColor: AppTheme.dividerBg(context),
          dividerHeight: 1.5,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: buildOrdersList(
              uid: uid,
              filterCompleted: false,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: buildOrdersList(
              uid: uid,
              filterCompleted: true,
            ),
          ),
        ],
      ),
    );
  }
}
