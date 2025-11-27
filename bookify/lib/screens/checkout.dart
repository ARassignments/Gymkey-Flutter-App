import '/components/promo_bottom_sheet.dart';
import '/models/promo_model.dart';
import '/screens/user_orders.dart';
import '/components/shipping_bottom_sheet.dart';
import '/models/shipping_model.dart';
import '/components/appsnackbar.dart';
import '/providers/cart_provider.dart';
import '/screens/book_detail_page.dart';
import '/screens/edit_profile.dart';
import '/providers/user_provider.dart';
import '/utils/themes/themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/models/cart_item.dart';
import '/managers/cart_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Checkout extends ConsumerStatefulWidget {
  const Checkout({super.key});

  @override
  ConsumerState<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends ConsumerState<Checkout> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController promoCodeController = TextEditingController();
  final auth = FirebaseAuth.instance;
  List<CartItem> cartItems = [];
  ShippingModel? selectedShipping;
  PromoModel? selectedPromo;
  double deliveryCharge = 0;
  int promoDiscount = 0;
  String userAddress = "Loading address...";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
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

  Future<void> _openShippingSheet() async {
    final selected = await showModalBottomSheet<ShippingModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => ShippingBottomSheet(initial: selectedShipping),
    );

    if (selected != null) {
      setState(() {
        selectedShipping = selected;
        deliveryCharge = selected.price;
      });
    }
  }

  Future<void> _openPromoSheet() async {
    final selected = await showModalBottomSheet<PromoModel>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => PromoBottomSheet(initialPromo: selectedPromo),
    );

    if (selected != null) {
      setState(() {
        selectedPromo = selected;
        promoDiscount = selected.discount;
      });
    }
  }

  Future<void> _placeOrder(
    double itemsTotal,
    double totalAmount,
    List<CartItem> cartItems,
  ) async {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      AppSnackBar.show(
        context,
        message: "User not logged in!",
        type: AppSnackBarType.error,
      );
      return;
    }

    if (cartItems.isEmpty) {
      AppSnackBar.show(
        context,
        message: "Your cart is empty!",
        type: AppSnackBarType.error,
      );
      return;
    }

    if (selectedShipping == null) {
      AppSnackBar.show(
        context,
        message: "Shipping type is not selected!",
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    /// 🔥 Generate Unique Order ID
    final String orderId =
        "ORD-${DateTime.now().millisecondsSinceEpoch.toString()}";

    /// 📝 Complete Order Model
    final Map<String, dynamic> orderData = {
      "orderId": orderId,
      "userId": uid,
      "orderDate": Timestamp.now(),

      /// Items
      "items": cartItems.map((e) => e.toMap()).toList(),
      "itemsTotal": itemsTotal,
      "deliveryCharge": deliveryCharge,
      "promoDiscount": promoDiscount,
      "totalAmount": totalAmount,

      /// Shipping Details
      "shippingAddress": userAddress,
      "shippingMethod": selectedShipping?.title ?? "Not Selected",
      "shippingArrival": selectedShipping?.getArrivalDate() ?? "",

      /// Promo Details
      "promoDiscountValue": promoDiscount > 0
          ? (totalAmount * promoDiscount / 100)
          : 0,

      /// Status
      "status": "Pending",
      "paymentStatus": "Unpaid",

      /// Tracking
      "tracking": {
        "placedAt": Timestamp.now(),
        "confirmedAt": null,
        "shippedAt": null,
        "deliveredAt": null,
        "cancelledAt": null,
      },
    };
    try {
      final firestore = FirebaseFirestore.instance;

      /// 🔥 Soft Store 1 (User Orders)
      // await firestore
      //     .collection("users")
      //     .doc(uid)
      //     .collection("orders")
      //     .doc(orderId)
      //     .set(orderData);

      /// 🔥 Soft Store 2 (Admin All Orders)
      await firestore.collection("orders").doc(orderId).set(orderData);

      /// 🛒 Clear Cart
      await CartManager.batchRemoveCartItems(cartItems);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            backgroundColor: AppTheme.cardDarkBg(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.cardBg(context),
                    ),
                    child: Icon(
                      HugeIconsSolid.shoppingBag03,
                      color: AppTheme.iconColor(context),
                      size: 70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Order Successful!",
                    textAlign: TextAlign.center,
                    style: AppTheme.textTitle(context).copyWith(fontSize: 25),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your order has been placed successfully.\nThank you for shopping with us!",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(context),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close checkout page
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          opaque: false,
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  UserOrders(),
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
                    child: Text("View Order"),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close checkout page
                    },
                    child: const Text("Continue"),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      AppSnackBar.show(
        context,
        message: "Failed to place order: $e",
        type: AppSnackBarType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final cartItems = ref.watch(cartProvider);
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "Checkout",
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
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Column(
              spacing: 18,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Shipping Address",
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                /// 🔹 Address Card
                _buildCard(
                  child: Row(
                    spacing: 12,
                    children: [
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDarkBg(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          HugeIconsSolid.location06,
                          color: AppTheme.iconColor(context),
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Home", style: AppTheme.textTitle(context)),
                            Text(
                              user?.address.toString() ?? userAddress,
                              style: AppTheme.textLabel(context),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      EditProfileScreen(),
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
                        icon: Icon(
                          HugeIconsSolid.edit01,
                          color: AppTheme.iconColorThree(context),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 20, color: AppTheme.dividerBg(context)),

                Text(
                  "Order List",
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                ...cartItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  final num discount = item.discount ?? 0;
                  final double originalPrice = item.price * item.quantity;
                  final double discountedPrice = discount > 0
                      ? (item.price - (item.price * discount / 100)) *
                            item.quantity
                      : originalPrice;

                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.customListBg(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      spacing: 16,
                      children: [
                        // ---------------- IMAGE ----------------
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) =>
                                    BookDetailPage(bookId: item.bookId),
                                transitionsBuilder: (_, animation, __, child) {
                                  final tween = Tween(
                                    begin: Offset(0, 1),
                                    end: Offset.zero,
                                  ).chain(CurveTween(curve: Curves.easeInOut));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(item.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // INDEX NUMBER
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  width: 25,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: AppTheme.customListBg(context),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (index + 1).toString().padLeft(2, '0'),
                                      style: AppTheme.textSearchInfoLabeled(
                                        context,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // DISCOUNT BADGE
                              if (discount > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColor.accent_50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${discount.toString().padLeft(2, '0')}% OFF",
                                      style: AppTheme.textLabel(context)
                                          .copyWith(
                                            fontSize: 8,
                                            color: AppColor.white,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ---------------- BOOK INFO ----------------
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TITLE
                              Text(
                                item.title,
                                style: AppTheme.textTitle(context),
                              ),

                              const SizedBox(height: 8),

                              // ---------------- PRICE ----------------
                              Row(
                                spacing: 6,
                                children: [
                                  Icon(
                                    HugeIconsSolid.money02,
                                    color: AppTheme.iconColor(context),
                                    size: 16,
                                  ),

                                  /// Discounted Price or Normal
                                  Text(
                                    "\$${discountedPrice.toStringAsFixed(2)}",
                                    style: AppTheme.textLabel(context).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),

                                  /// Strike-through original price if discounted
                                  if (discount > 0)
                                    Text(
                                      "\$${originalPrice.toStringAsFixed(2)}",
                                      style:
                                          AppTheme.textSearchInfoLabeled(
                                            context,
                                          ).copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // ---------------- QTY ----------------
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.sliderHighlightBg(context),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "QTY: ${item.quantity.toString().padLeft(2, '0')}",
                                  style: AppTheme.textSearchInfoLabeled(
                                    context,
                                  ).copyWith(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                Divider(height: 20, color: AppTheme.dividerBg(context)),

                Text(
                  "Choose Shipping",
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                _buildCard(
                  child: InkWell(
                    onTap: _openShippingSheet,
                    child: selectedShipping == null
                        ? Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              spacing: 18,
                              children: [
                                Icon(
                                  HugeIconsSolid.shippingTruck02,
                                  color: AppTheme.iconColor(context),
                                  size: 24,
                                ),
                                Expanded(
                                  child: Column(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Choose Shipping Type",
                                        style: AppTheme.textTitle(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  HugeIconsStroke.arrowRight01,
                                  color: AppTheme.iconColorThree(context),
                                  size: 24,
                                ),
                              ],
                            ),
                          )
                        : Row(
                            spacing: 12,
                            children: [
                              Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDarkBg(context),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  selectedShipping!.icon,
                                  color: AppTheme.iconColor(context),
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  spacing: 8,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedShipping!.title,
                                      style: AppTheme.textTitle(context),
                                    ),
                                    Text(
                                      selectedShipping!.getArrivalDate(),
                                      style: AppTheme.textLabel(context),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${deliveryCharge.toStringAsFixed(0)}',
                                style: AppTheme.textTitle(context),
                              ),
                            ],
                          ),
                  ),
                ),

                Divider(height: 20, color: AppTheme.dividerBg(context)),

                Text(
                  "Promo Code",
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                Row(
                  children: [
                    selectedPromo == null
                        ? Expanded(
                            child: TextFormField(
                              controller: promoCodeController,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                labelText: "Enter Promo Code",
                                hintText: 'e.g. ABC123****',
                                counter: const SizedBox.shrink(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                } else if (value.length < 10) {
                                  return 'Promo Code must be at least 10 characters long';
                                } else if (!RegExp(
                                  r'^[a-zA-Z0-9]+$',
                                ).hasMatch(value)) {
                                  return 'Promo Code must contain only letters & digits';
                                }
                                return null;
                              },
                              maxLength: 10,
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.customListBg(context),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppTheme.sliderHighlightBg(context),
                              ),
                            ),
                            child: Row(
                              spacing: 8,
                              children: [
                                Text(
                                  "Discount ${promoDiscount.toString().padLeft(2, '0')}% Off",
                                  style: AppTheme.textSearchInfoLabeled(
                                    context,
                                  ).copyWith(fontSize: 16),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() => selectedPromo = null);
                                  },
                                  child: Icon(
                                    HugeIconsSolid.cancel01,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: _openPromoSheet,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.customListBg(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: AppTheme.iconColor(context),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                /// 🔹 Order Summary Card
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Order Summary", style: AppTheme.textTitle(context)),
                      const SizedBox(height: 15),
                      _summaryRow(
                        "Amount",
                        "\$${ref.read(cartProvider.notifier).totalPrice.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 12),
                      _summaryRow(
                        "Shipping",
                        "${selectedShipping == null ? '-' : '\$' + deliveryCharge.toStringAsFixed(2)}",
                      ),
                      const SizedBox(height: 12),
                      _summaryRow(
                        "Promo",
                        "${selectedPromo == null ? '-' : '- \$' + ((promoDiscount / 100) * ref.read(cartProvider.notifier).totalPrice + deliveryCharge).toStringAsFixed(2)}",
                      ),
                      Divider(height: 20, color: AppTheme.dividerBg(context)),
                      _summaryRow(
                        "Total",
                        "\$${(ref.read(cartProvider.notifier).totalPrice + deliveryCharge - ((promoDiscount / 100) * ref.read(cartProvider.notifier).totalPrice + deliveryCharge)).toStringAsFixed(2)}",
                        bold: true,
                        extraValue: selectedPromo == null
                            ? ""
                            : "\$${(ref.read(cartProvider.notifier).totalPrice + deliveryCharge).toStringAsFixed(2)}",
                      ),
                    ],
                  ),
                ),

                Divider(height: 20, color: AppTheme.dividerBg(context)),

                ElevatedButton(
                  onPressed: () => cartItems.isEmpty
                      ? null
                      : _placeOrder(
                          ref.read(cartProvider.notifier).totalPrice,
                          (ref.read(cartProvider.notifier).totalPrice +
                              deliveryCharge -
                              ((promoDiscount / 100) *
                                      ref
                                          .read(cartProvider.notifier)
                                          .totalPrice +
                                  deliveryCharge)),
                          cartItems,
                        ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            strokeCap: StrokeCap.round,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 12,
                          children: [
                            Text("Continue to Payment"),
                            Icon(HugeIconsSolid.arrowRight04),
                          ],
                        ),
                ),

                SizedBox(height: 20),
              ],
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
        color: AppTheme.customListBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  // Helper method for summary rows
  Row _summaryRow(
    String label,
    String value, {
    bool bold = false,
    String extraValue = "",
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
        Row(
          spacing: 8,
          children: [
            Text(
              value,
              style: AppTheme.textLabel(context).copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
              ),
            ),
            if (extraValue.isNotEmpty)
              Text(
                extraValue,
                style: AppTheme.textSearchInfoLabeled(context).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
