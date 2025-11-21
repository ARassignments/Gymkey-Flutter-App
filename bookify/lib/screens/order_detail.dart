import '/components/loading_screen.dart';
import '/components/not_found.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:intl/intl.dart';
import '/utils/themes/themes.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  final FirebaseAuth auth = FirebaseAuth.instance;

  OrderDetailsPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final uid = auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "Order Detail",
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
      ),
      body: uid == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .collection("orders")
                  .doc(orderId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: LoadingLogo());
                }

                if (!snapshot.data!.exists) {
                  return const Center(
                    child: NotFoundWidget(
                      title: "Order Not Found",
                      message: "",
                    ),
                  );
                }

                final order = snapshot.data!.data() as Map<String, dynamic>;

                final items = List<Map<String, dynamic>>.from(
                  order["items"] ?? [],
                );

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _orderHeader(order, context),
                    const SizedBox(height: 16),
                    _itemsCard(items, context),
                    const SizedBox(height: 16),
                    _shippingCard(order, context),
                    const SizedBox(height: 16),
                    _promoPriceCard(order, context),
                  ],
                );
              },
            ),
    );
  }

  Widget _orderHeader(Map<String, dynamic> order, BuildContext context) {
    String status = order["status"] ?? "Pending";
    Timestamp date = order["orderDate"];
    final orderDate = date.toDate();

    return Card(
      shape: _shape(),
      elevation: 0,
      color: AppTheme.customListBg(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _rowBold("Order ID", order["orderId"], context),
            _row(
              "Date",
              DateFormat('MMM dd, yyyy | hh:mm a').format(orderDate),
              context,
            ),
            _row("Payment Method", "Cash On Delivery", context),
            _row(
              "Status",
              "",
              context,
              widget: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                  style: AppTheme.textSearchInfoLabeled(context).copyWith(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _shippingCard(Map<String, dynamic> order, BuildContext context) {
    return Card(
      shape: _shape(),
      elevation: 0,
      color: AppTheme.customListBg(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Shipping Details", context),
            const SizedBox(height: 12),
            _row("Address", "${order["shippingAddress"]}", context),
            _row("Method", "${order["shippingMethod"]}", context),
            _row("Arrival", "${order["shippingArrival"]}", context),
          ],
        ),
      ),
    );
  }

  Widget _promoPriceCard(Map<String, dynamic> order, BuildContext context) {
    return Card(
      shape: _shape(),
      elevation: 0,
      color: AppTheme.customListBg(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Payment Summary", context),
            const SizedBox(height: 12),

            _row("Items Total", "\$${order["itemsTotal"]}", context),
            _row("Delivery", "\$${order["deliveryCharge"]}", context),
            _row("Discount", "-\$${order["promoDiscountValue"]}", context),
            Divider(height: 20, color: AppTheme.dividerBg(context)),
            _rowBold("Total", "\$${order["totalAmount"]}", context),
          ],
        ),
      ),
    );
  }

  Widget _itemsCard(List<Map<String, dynamic>> items, BuildContext context) {
    return Card(
      shape: _shape(),
      elevation: 0,
      color: AppTheme.customListBg(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title("Items", context),
            const SizedBox(height: 12),

            ...items.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${e["title"]}  x ${e["quantity"]}",
                      style: AppTheme.textLabel(
                        context,
                      ).copyWith(fontWeight: FontWeight.normal),
                    ),
                    Text(
                      "\$${e["price"]}",
                      style: AppTheme.textLabel(
                        context,
                      ).copyWith(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Helpers
  ShapeBorder _shape() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

  Widget _title(String text, BuildContext context) => Text(
    text,
    style: AppTheme.textLabel(
      context,
    ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
  );

  Widget _row(
    String label,
    String value,
    BuildContext context, {
    Widget? widget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.textLabel(
              context,
            ).copyWith(fontWeight: FontWeight.normal),
          ),

          const SizedBox(width: 16),
          value.isNotEmpty
              ? Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    softWrap: true,
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontWeight: FontWeight.normal),
                  ),
                )
              : (widget ?? const SizedBox()),
        ],
      ),
    );
  }

  Widget _rowBold(String label, String value, BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
