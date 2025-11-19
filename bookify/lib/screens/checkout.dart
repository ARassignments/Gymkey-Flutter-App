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
  double deliveryCharge = 25.0;
  String userAddress = "Loading address...";

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

  Future<void> _placeOrder(double itemsTotal, double totalAmount) async {
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
      AppSnackBar.show(
        context,
        message: "Order placed successfully!",
        type: AppSnackBarType.success,
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to place order: $e")));
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
                                transitionsBuilder:
                                    (_, animation, __, child) {
                                      final tween =
                                          Tween(
                                            begin: Offset(0, 1),
                                            end: Offset.zero,
                                          ).chain(
                                            CurveTween(
                                              curve: Curves.easeInOut,
                                            ),
                                          );
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
                                    style: AppTheme.textLabel(context)
                                        .copyWith(
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
                                  color: AppTheme.sliderHighlightBg(
                                    context,
                                  ),
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
                    onTap: () {},
                    child: Padding(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Choose Shipping Type", style: AppTheme.textTitle(context)),
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

                TextFormField(
                  controller: promoCodeController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Enter Promo Code",
                    hintText: 'e.g. ABC123****',
                    counter: const SizedBox.shrink(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null;
                    } else if (value.length < 10) {
                      return 'Promo Code must be at least 10 characters long';
                    } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                      return 'Promo Code must contain only letters & digits';
                    }
                    return null;
                  },
                  maxLength: 10,
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
                        "\$${deliveryCharge.toStringAsFixed(2)}",
                      ),
                      Divider(height: 20, color: AppTheme.dividerBg(context)),
                      _summaryRow(
                        "Total",
                        "\$${(ref.read(cartProvider.notifier).totalPrice + deliveryCharge).toStringAsFixed(2)}",
                        bold: true,
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
                              deliveryCharge),
                        ),
                  child: Row(
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
  Row _summaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        ),
        Text(
          value,
          style: AppTheme.textLabel(context).copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
