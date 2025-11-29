import '/components/appsnackbar.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/screens/order_detail.dart';
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';

class OrdersListTab extends StatefulWidget {
  final String uid;
  final bool filterCompleted;
  final bool filterCancelled;

  const OrdersListTab({
    super.key,
    required this.uid,
    required this.filterCompleted,
    required this.filterCancelled,
  });

  @override
  State<OrdersListTab> createState() => _OrdersListTabState();
}

class _OrdersListTabState extends State<OrdersListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> cancelOrder(String orderId) async {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Cancel Your Order?",
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Divider(height: 1, color: AppTheme.dividerBg(context)),

              Text(
                "Are you sure you want to 'Cancelled' your order?",
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(context),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.accent_50,
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(orderId)
                      .update({
                        "status": "Cancelled",
                        "tracking.cancelledAt": Timestamp.now(),
                      });
                  // await FirebaseFirestore.instance
                  //     .collection('orders')
                  //     .doc(orderId)
                  //     .delete();

                  AppSnackBar.show(
                    context,
                    message: "Order cancelled successfully.",
                    type: AppSnackBarType.success,
                  );
                },
                child: Text(
                  "Yes, Cancel Order",
                  style: TextStyle(color: Colors.white),
                ),
              ),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildOrderCard(String orderId, Map<String, dynamic> order) {
    final status = order['status'] ?? 'Pending';
    final timestamp = order['orderDate'];
    final timestampConfirm = order['tracking']['confirmedAt'];
    final timestampShipped = order['tracking']['shippedAt'];
    final timestampDelivered = order['tracking']['deliveredAt'];
    final timestampCancel = order['tracking']['cancelledAt'];
    final total = order['totalAmount']?.toDouble() ?? 0.0;
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

    String formattedDate = "Unknown";
    String formattedConfirmDate = "Unknown";
    String formattedShippedDate = "Unknown";
    String formattedDeliveredDate = "Unknown";
    String formattedCancelDate = "Unknown";
    String statuDate = "";

    if (timestamp is Timestamp) {
      final orderDate = timestamp.toDate();
      formattedDate = DateFormat('MMM dd, yyyy | hh:mm a').format(orderDate);
    }

    if (timestampConfirm is Timestamp) {
      final orderConfirmDate = timestampConfirm.toDate();
      formattedConfirmDate = DateFormat(
        'MMM dd, yyyy | hh:mm a',
      ).format(orderConfirmDate);
    }

    if (timestampShipped is Timestamp) {
      final orderShippedDate = timestampShipped.toDate();
      formattedShippedDate = DateFormat(
        'MMM dd, yyyy | hh:mm a',
      ).format(orderShippedDate);
    }

    if (timestampDelivered is Timestamp) {
      final orderDeliveredDate = timestampDelivered.toDate();
      formattedDeliveredDate = DateFormat(
        'MMM dd, yyyy | hh:mm a',
      ).format(orderDeliveredDate);
    }

    if (timestampCancel is Timestamp) {
      final orderCancelDate = timestampCancel.toDate();
      formattedCancelDate = DateFormat(
        'MMM dd, yyyy | hh:mm a',
      ).format(orderCancelDate);
    }

    if (status == 'Confirmed') {
      statuDate = formattedConfirmDate;
    } else if (status == 'Shipped') {
      statuDate = formattedShippedDate;
    } else if (status == 'Delivered') {
      statuDate = formattedDeliveredDate;
    } else if (status == 'Cancelled') {
      statuDate = formattedCancelDate;
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

                        Row(
                          spacing: 6,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
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
                            if (status != 'Pending')
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.sliderHighlightBg(context),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "On $statuDate",
                                  style: AppTheme.textSearchInfoLabeled(
                                    context,
                                  ).copyWith(fontSize: 9),
                                ),
                              ),
                          ],
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
                            if (status != 'Delivered' &&
                                status != 'Cancelled' &&
                                status != 'Shipped' &&
                                status != 'Confirmed')
                              TextButton.icon(
                                onPressed: () => cancelOrder(orderId),
                                icon: Icon(
                                  HugeIconsSolid.cancelCircle,
                                  color: AppColor.accent_50,
                                ),
                                label: Text(
                                  "Cancel Order",
                                  style: TextStyle(color: AppColor.accent_50),
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingLogo());
        }

        if (!snapshot.hasData) {
          String message;
          if (widget.filterCancelled) {
            message = "You don't have cancelled orders at this time";
          } else if (widget.filterCompleted) {
            message = "You don't have completed orders at this time";
          } else {
            message = "You don't have active orders at this time";
          }
          return Center(
            child: NotFoundWidget(
              title: "You don't have an order yet",
              message: message,
            ),
          );
        }

        // ---------- FILTER BY USER ID ----------
        final userOrders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userId'] == widget.uid;
        }).toList();

        if (userOrders.isEmpty) {
          String message;
          if (widget.filterCancelled) {
            message = "You don't have cancelled orders at this time";
          } else if (widget.filterCompleted) {
            message = "You don't have completed orders at this time";
          } else {
            message = "You don't have active orders at this time";
          }
          return Center(
            child: NotFoundWidget(
              title: "You don't have an order yet",
              message: message,
            ),
          );
        }

        // ---------- FILTER BY STATUS ----------
        final filteredDocs = userOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'Pending';

          if (widget.filterCancelled) {
            return status == 'Cancelled';
          }

          if (widget.filterCompleted) {
            return status == 'Delivered' || status == 'Completed';
          }

          return status != 'Delivered' &&
              status != 'Completed' &&
              status != 'Cancelled';
        }).toList();

        if (filteredDocs.isEmpty) {
          String message;
          if (widget.filterCancelled) {
            message = "You don't have cancelled orders at this time";
          } else if (widget.filterCompleted) {
            message = "You don't have completed orders at this time";
          } else {
            message = "You don't have active orders at this time";
          }
          return Center(
            child: NotFoundWidget(
              title: "You don't have an order yet",
              message: message,
            ),
          );
        }

        // ---------- BUILD LIST ----------
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final order = doc.data() as Map<String, dynamic>;

            return buildOrderCard(doc.id, order);
          },
        );
      },
    );
  }
}
