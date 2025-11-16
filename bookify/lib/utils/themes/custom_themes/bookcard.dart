import '/components/appsnackbar.dart';
import '/managers/wishlist_manager.dart';
import '/managers/cart_manager.dart';
import '/models/cart_item.dart';
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';

class BookCard extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String imagePath;
  final String category;
  final double price;
  final double? rating;
  final double? stock;

  const BookCard({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.imagePath,
    required this.category,
    required this.price,
    this.rating,
    this.stock,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool isFavorited = false;
  double averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    averageRating = widget.rating ?? 0.0;
    _loadWishlistStatus();
    _fetchAverageRating();
  }

  // ---------- Load wishlist status safely ----------
  Future<void> _loadWishlistStatus() async {
    try {
      final exists = await WishlistManager.isInWishlist(widget.bookId);
      if (!mounted) return;
      setState(() => isFavorited = exists);
    } catch (e) {
      print("Error loading wishlist status: $e");
    }
  }

  // ---------- Fetch average rating safely ----------
  Future<void> _fetchAverageRating() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('book_reviews')
          .where('bookId', isEqualTo: widget.bookId)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        double total = 0.0;
        int count = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final rating = (data['rating'] ?? 0).toDouble();
          total += rating;
          if (rating > 0) count++;
        }

        if (!mounted) return;
        setState(() {
          averageRating = count > 0 ? total / count : 0.0;
        });
      } else {
        if (!mounted) return;
        setState(() {
          averageRating = 0.0;
        });
      }
    } catch (e) {
      print("Error fetching average rating: $e");
      if (!mounted) return;
      setState(() => averageRating = 0.0);
    }
  }

  // ---------- Wishlist toggle ----------
  Future<void> _toggleWishlist() async {
    final item = CartItem(
      bookId: widget.bookId,
      title: widget.title,
      author: widget.author,
      imageUrl: widget.imagePath,
      price: widget.price,
    );

    final newFavorited = !isFavorited;

    if (!mounted) return;
    setState(() => isFavorited = newFavorited);

    try {
      if (newFavorited) {
        await WishlistManager.addToWishlist(item);
      } else {
        await WishlistManager.removeFromWishlist(item);
      }
    } catch (e) {
      print("Error updating wishlist: $e");
    }

    if (!mounted) return;
    AppSnackBar.show(
      context,
      message: newFavorited
          ? '${widget.title} added to wishlist'
          : '${widget.title} removed from wishlist',
      type: AppSnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  widget.imagePath,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    return Shimmer.fromColors(
                      baseColor: AppTheme.customListBg(context),
                      highlightColor: AppTheme.sliderHighlightBg(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.customListBg(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: 120,
                        width: double.infinity,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.iconColor(context),
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, _, __) => Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.customListBg(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: InkWell(
                  onTap: _toggleWishlist,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.customListBg(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorited
                          ? HugeIconsSolid.favourite
                          : HugeIconsStroke.favourite,
                      size: 18,
                      color: isFavorited
                          ? Colors.red
                          : AppTheme.iconColorThree(context),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 38,
                right: 6,
                child: InkWell(
                  onTap: () {
                    CartManager.addToCart(
                      CartItem(
                        bookId: widget.bookId,
                        title: widget.title,
                        author: widget.author,
                        imageUrl: widget.imagePath,
                        price: widget.price,
                      ),
                    );
                    AppSnackBar.show(
                      context,
                      message: '${widget.title} added to cart',
                      type: AppSnackBarType.success,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.customListBg(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      HugeIconsSolid.shoppingBag03,
                      size: 18,
                      color: AppTheme.iconColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 📝 Title
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.textTitle(context).copyWith(fontSize: 20),
                ),
                Row(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          HugeIconsSolid.star,
                          size: 10,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: AppTheme.textSearchInfoLabeled(
                            context,
                          ).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      height: 12,
                      width: 1.8,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppTheme.dividerBg(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.customListBg(context),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.sliderHighlightBg(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "10 Stocks Available",
                          style: AppTheme.textLabel(
                            context,
                          ).copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                ),
                // Text(
                //   widget.category,
                //   style: AppTheme.textSearchInfoLabeled(context),
                // ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.price.toStringAsFixed(0)}',
                      style: AppTheme.textLink(context).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navbarBg(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
