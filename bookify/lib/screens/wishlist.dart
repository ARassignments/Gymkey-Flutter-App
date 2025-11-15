import '/components/appsnackbar.dart';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/models/cart_item.dart';
import '/managers/cart_manager.dart';
import '/managers/wishlist_manager.dart';
import '/screens/home.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/app_navbar.dart';
import '/utils/themes/custom_themes/bottomnavbar.dart';
import 'package:flutter/material.dart';

class WishListScreen extends StatefulWidget {
  const WishListScreen({super.key});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
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
                  stream: WishlistManager.getWishlistStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: LoadingLogo());
                    }

                    final wishlistItems = snapshot.data ?? [];

                    if (wishlistItems.isEmpty) {
                      return Center(
                        child: NotFoundWidget(
                          title: "Your wishlist is empty",
                          message: "You don't have any items added to wishlist yet.",
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: wishlistItems.length,
                      itemBuilder: (context, index) {
                        final item = wishlistItems[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.customListBg(context),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              // Book Image + Heart
                              Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: AppTheme.cardDarkBg(context),
                                      image: DecorationImage(
                                        image: NetworkImage(item.imageUrl),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: InkWell(
                                      onTap: () {
                                        WishlistManager.removeFromWishlist(
                                          item,
                                        );
                                        AppSnackBar.show(
                                          context,
                                          message:
                                              "${item.title} removed from wishlist",
                                          type: AppSnackBarType.success,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.customListBg(context),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          HugeIconsSolid.favourite,
                                          size: 14,
                                          color: Colors.red,
                                        ),
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
                                        borderRadius: BorderRadius.circular(20),
                                        color: AppTheme.customListBg(context),
                                      ),
                                      child: Center(
                                        child: Text(
                                          (index+1).toString().padLeft(2, '0'),
                                          style: AppTheme.textSearchInfoLabeled(
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
                                        style: AppTheme.textTitle(context),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Available Stock: ${item.stock.toString().padLeft(2, '0')} Left",
                                        style: AppTheme.textSearchInfoLabeled(
                                          context,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        spacing: 6,
                                        children: [
                                          Icon(
                                            HugeIconsSolid.money02,
                                            color: AppTheme.iconColor(context),
                                            size: 16,
                                          ),
                                          Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: AppTheme.textLabel(context),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Actions
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        CartManager.addToCart(item);
                                        WishlistManager.removeFromWishlist(
                                          item,
                                        );
                                        AppSnackBar.show(
                                          context,
                                          message:
                                              "${item.title} added to cart",
                                          type: AppSnackBarType.success,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.cardBg(context),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          HugeIconsSolid.shoppingBag01,
                                          size: 18,
                                          color: AppTheme.iconColorThree(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () {
                                        WishlistManager.removeFromWishlist(
                                          item,
                                        );
                                        AppSnackBar.show(
                                          context,
                                          message:
                                              '${item.title} removed from wishlist',
                                          type: AppSnackBarType.success,
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
                        );
                      },
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
