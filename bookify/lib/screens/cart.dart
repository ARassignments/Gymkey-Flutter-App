import '/components/appsnackbar.dart';
import '/screens/book_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/cart_provider.dart';
import '../screens/checkout.dart';
import '/utils/themes/themes.dart';
import '/components/not_found.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  void removeItem(
    BuildContext context,
    WidgetRef ref,
    String itemId,
    String itemImage,
    String itemIndex,
    String itemTitle,
    String itemQty,
    String itemPrice,
  ) {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: Wrap(
            children: [
              Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Remove From Cart?",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Divider(height: 1, color: AppTheme.dividerBg(context)),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.customListBg(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      spacing: 16,
                      children: [
                        // Book Image
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: DecorationImage(
                                  image: NetworkImage(itemImage),
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
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppTheme.customListBg(context),
                                ),
                                child: Center(
                                  child: Text(
                                    itemIndex,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemTitle,
                                style: AppTheme.textTitle(context),
                              ),
                          
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.sliderHighlightBg(
                                        context,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.sliderHighlightBg(
                                              context,
                                            ),
                                          ),
                                          child: Icon(
                                            HugeIconsSolid.remove01,
                                            size: 14,
                                            color: AppTheme.iconColorThree(
                                              context,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            itemQty,
                                            style:
                                                AppTheme.textSearchInfoLabeled(
                                                  context,
                                                ).copyWith(fontSize: 10),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppTheme.sliderHighlightBg(
                                              context,
                                            ),
                                          ),
                                          child: Icon(
                                            HugeIconsSolid.add01,
                                            size: 14,
                                            color: AppTheme.iconColorThree(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Price
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 6,
                                children: [
                                  Icon(
                                    HugeIconsSolid.money02,
                                    color: AppTheme.iconColor(context),
                                    size: 16,
                                  ),
                                  Text(
                                    itemPrice,
                                    style: AppTheme.textLabel(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.dividerBg(context)),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColor.accent_50),
                      overlayColor: AppColor.accent_50.withOpacity(0.1),
                      backgroundColor: AppTheme.screenBg(context),
                    ),
                    child: Text(
                      'Yes, Remove',
                      style: TextStyle(color: AppColor.accent_50),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(cartProvider.notifier).removeFromCart(itemId);
                    },
                  ),
                  ElevatedButton(
                    child: Text("Cancel"),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      body: SafeArea(
        child: cartItems.isEmpty
            ? const Center(
                child: NotFoundWidget(
                  title: "Your cart is empty",
                  message:
                      "You don't have any items added to cart yet. You need to add items to cart before checkout.",
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Dismissible(
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
                                        const Icon(HugeIconsStroke.swipeLeft01),
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
                              ref
                                  .read(cartProvider.notifier)
                                  .removeFromCart(item.bookId);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.customListBg(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  // Book Image
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          opaque: false,
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => BookDetailPage(
                                                bookId: item.bookId,
                                              ),
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
                                                final tween =
                                                    Tween(
                                                      begin: begin,
                                                      end: end,
                                                    ).chain(
                                                      CurveTween(curve: curve),
                                                    );
                                                return SlideTransition(
                                                  position: animation.drive(
                                                    tween,
                                                  ),
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                                (index + 1).toString().padLeft(
                                                  2,
                                                  '0',
                                                ),
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

                                          const SizedBox(height: 15),
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppTheme.sliderHighlightBg(
                                                        context,
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        final newQty =
                                                            item.quantity - 1;
                                                        ref
                                                            .read(
                                                              cartProvider
                                                                  .notifier,
                                                            )
                                                            .updateQuantity(
                                                              item.bookId,
                                                              newQty,
                                                              item.stock,
                                                            );
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              AppTheme.sliderHighlightBg(
                                                                context,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          HugeIconsSolid
                                                              .remove01,
                                                          size: 14,
                                                          color:
                                                              AppTheme.iconColorThree(
                                                                context,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        "QTY: ${item.quantity.toString().padLeft(2, '0')}",
                                                        style:
                                                            AppTheme.textSearchInfoLabeled(
                                                              context,
                                                            ).copyWith(
                                                              fontSize: 10,
                                                            ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        final newQty =
                                                            item.quantity + 1;
                                                        if (newQty <=
                                                            item.stock) {
                                                          ref
                                                              .read(
                                                                cartProvider
                                                                    .notifier,
                                                              )
                                                              .updateQuantity(
                                                                item.bookId,
                                                                newQty,
                                                                item.stock,
                                                              );
                                                        } else {
                                                          AppSnackBar.show(
                                                            context,
                                                            message:
                                                                "Maximum stock reached!",
                                                            type:
                                                                AppSnackBarType
                                                                    .warning,
                                                          );
                                                        }
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              AppTheme.sliderHighlightBg(
                                                                context,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          HugeIconsSolid.add01,
                                                          size: 14,
                                                          color:
                                                              AppTheme.iconColorThree(
                                                                context,
                                                              ),
                                                        ),
                                                      ),
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
                                              "\$${(item.price * item.quantity)}",
                                              style: AppTheme.textLabel(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        InkWell(
                                          onTap: () {
                                            removeItem(
                                              context,
                                              ref,
                                              item.bookId,
                                              item.imageUrl,
                                              (index + 1).toString().padLeft(
                                                2,
                                                '0',
                                              ),
                                              item.title,
                                              "QTY: ${item.quantity.toString().padLeft(2, '0')}",
                                              "\$${(item.price * item.quantity)}"
                                            );
                                            // ref
                                            //     .read(cartProvider.notifier)
                                            //     .removeFromCart(item.bookId);
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
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDarkBg(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      spacing: 16,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              "Total Price",
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 12),
                            ),
                            Text(
                              "\$${ref.read(cartProvider.notifier).totalPrice.toString()}",
                              style: AppTheme.textTitle(context).copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => Checkout(),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 12,
                              children: [
                                Text("Check Out"),
                                Icon(HugeIconsSolid.shoppingCartCheckOut02),
                              ],
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
  }
}
