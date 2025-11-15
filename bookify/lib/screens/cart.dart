import 'package:bookify/components/appsnackbar.dart';
import 'package:shimmer/shimmer.dart';

import '/components/not_found.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/components/loading_screen.dart';
import '/models/cart_item.dart';
import '/managers/cart_manager.dart';
import '/screens/checkout.dart';
import '/screens/home.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/app_navbar.dart';
import '/utils/themes/custom_themes/bottomnavbar.dart';
import '/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        navigateWithFade(context, const HomeScreen());
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.screenBg(context),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<CartItem>>(
                  stream: CartManager.getCartStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: LoadingLogo());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: NotFoundWidget(
                          title: "No item in cart",
                          message: "",
                        ),
                      );
                    }

                    final cartItems = snapshot.data ?? [];

                    if (cartItems.isEmpty) {
                      return const Center(
                        child: NotFoundWidget(
                          title: "Your cart is empty",
                          message: "You don't have any items added to cart yet. You need to add items to cart before checkout.",
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];

                              return Dismissible(
                                key: Key(item.bookId),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg(context),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Shimmer(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppTheme.sliderHighlightBg(context),
                                            AppTheme.iconColorThree(context),
                                            AppTheme.sliderHighlightBg(context),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        direction: ShimmerDirection.rtl,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          spacing: 12,
                                          children: [
                                            const Icon(
                                              HugeIconsStroke.swipeLeft01,
                                            ),
                                            Text(
                                              "Swipe left to remove",
                                              style: AppTheme.textLink(context)
                                                  .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            Icon(
                                              HugeIconsSolid.delete01,
                                              color: AppColor.accent_50,
                                              size: 24,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onDismissed: (direction) {
                                  CartManager.removeFromCart(
                                    item.bookId,
                                    context,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.customListBg(context),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      // Book Image
                                      Stack(
                                        children: [
                                          Container(
                                            width: 120,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  item.imageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              width: 25,
                                              height: 88,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: AppTheme.customListBg(
                                                  context,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  (index + 1)
                                                      .toString()
                                                      .padLeft(2, '0'),
                                                  style:
                                                      AppTheme.textSearchInfoLabeled(
                                                        context,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Book Info
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: AppTheme.textTitle(
                                                  context,
                                                ),
                                              ),
                                          
                                              const SizedBox(height: 20),
                                              Row(
                                                children: [
                                                  InkWell(
                                                    onTap: () {
                                                      CartManager.updateQuantity(
                                                        item.bookId,
                                                        item.quantity - 1,
                                                        context,
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            AppTheme.sliderHighlightBg(
                                                              context,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.remove,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Text(
                                                      "QTY: ${item.quantity.toString().padLeft(2, '0')}",
                                                      style:
                                                          AppTheme.textSearchInfoLabeled(
                                                            context,
                                                          ).copyWith(
                                                            fontSize: 12,
                                                          ),
                                                    ),
                                                  ),
                                                  InkWell(
                                                    onTap: () {
                                                      if (item.quantity <
                                                          item.stock) {
                                                        CartManager.updateQuantity(
                                                          item.bookId,
                                                          item.quantity + 1,
                                                          context,
                                                        );
                                                      } else {
                                                        AppSnackBar.show(
                                                          context,
                                                          message:
                                                              "Maximum stock reached!",
                                                          type: AppSnackBarType
                                                              .warning,
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            AppTheme.sliderHighlightBg(
                                                              context,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.add,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Price + Delete
                                      Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              spacing: 6,
                                              children: [
                                                Icon(
                                                  HugeIconsSolid.money02,
                                                  color: AppTheme.iconColor(
                                                    context,
                                                  ),
                                                  size: 16,
                                                ),
                                                Text(
                                                  "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                                                  style: AppTheme.textLabel(
                                                    context,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            InkWell(
                                              onTap: () {
                                                CartManager.removeFromCart(
                                                  item.bookId,
                                                  context,
                                                );
                                              },
                                              child: const Icon(
                                                HugeIconsSolid.delete01,
                                                color: AppColor.accent_50,
                                                size: 18,
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
                          ),
                        ),

                        // Checkout Button
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Checkout(),
                                  ),
                                );
                              },
                              child: const Text("Check Out"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
