import '/components/appsnackbar.dart';
import '/components/loading_screen.dart';
import '/managers/wishlist_manager.dart';
import '/utils/themes/themes.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/models/cart_item.dart';
import '/managers/cart_manager.dart';
import '/utils/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId;
  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;
  DocumentSnapshot? bookData;
  double? selectedRating;
  final reviewController = TextEditingController();
  double averageRating = 0.0;
  bool isFavorited = false;
  bool itemExistsInCart = false;
  List<Map<String, dynamic>> reviews = [];
  List<Map<String, dynamic>> topThreeReviews = [];
  int selectedQty = 1;

  bool hasUserReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadWishlistStatus();
    fetchBookData();
    fetchAverageRating();
    fetchReviews();
    checkIfUserReviewed();
    _loadCartQuantity();
    CartManager.getCartStream().listen((items) {
      bool exists = items.any((item) => item.bookId == widget.bookId);

      setState(() {
        itemExistsInCart = exists;
      });
    });
  }

  Future<void> fetchBookData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.bookId)
        .get();
    if (snapshot.exists) {
      setState(() => bookData = snapshot);
    }
  }

  Future<void> fetchAverageRating() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('book_reviews')
          .where('bookId', isEqualTo: widget.bookId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        double total = 0.0;
        int count = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final ratingValue = data['rating'];
          if (ratingValue != null && ratingValue is num) {
            total += ratingValue.toDouble();
            count++;
          }
        }

        setState(() {
          averageRating = count > 0 ? total / count : 0.0;
        });
      } else {
        setState(() {
          averageRating = 0.0;
        });
      }
    } catch (e) {
      print("Error fetching average rating: $e");
      setState(() {
        averageRating = 0.0;
      });
    }
  }

  Future<void> fetchReviews() async {
  try {
    final reviewSnapshot = await FirebaseFirestore.instance
        .collection('book_reviews')
        .where('bookId', isEqualTo: widget.bookId)
        .orderBy('created_at', descending: true)
        .get();

    List<Map<String, dynamic>> enrichedReviews = [];

    for (var doc in reviewSnapshot.docs) {
      final reviewData = doc.data() as Map<String, dynamic>;
      final userId = reviewData['userId'];

      // Fetch user info from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userData = userDoc.exists ? userDoc.data() as Map<String, dynamic> : {};

      enrichedReviews.add({
        "reviewId": doc.id,
        "rating": reviewData['rating'],
        "review": reviewData['review'],
        "created_at": reviewData['created_at'],
        "userId": userId,
        "userName": userData['name'] ?? userData['username'] ?? "Anonymous",
        "userImage": userData['profile_image_url'] ?? "",
      });
    }

    // Sort reviews by rating (descending)
    enrichedReviews.sort((a, b) {
      final r1 = (a['rating'] as num?)?.toDouble() ?? 0;
      final r2 = (b['rating'] as num?)?.toDouble() ?? 0;
      return r2.compareTo(r1);
    });

    setState(() {
      reviews = enrichedReviews;
      topThreeReviews = enrichedReviews.take(3).toList();
    });
  } catch (e) {
    print("Error fetching reviews: $e");
  }
}



  Future<void> checkIfUserReviewed() async {
    final user = auth.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('book_reviews')
        .where('bookId', isEqualTo: widget.bookId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        hasUserReviewed = true;
        final data = snapshot.docs.first.data();
        selectedRating = (data['rating'] as num).toDouble();
        reviewController.text = data['review'] ?? '';
      });
    }
  }

  Future<void> submitReview() async {
    final user = auth.currentUser;
    if (user == null) return;

    // ✅ Prevent multiple submissions
    final existingReviewSnapshot = await FirebaseFirestore.instance
        .collection('book_reviews')
        .where('bookId', isEqualTo: widget.bookId)
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existingReviewSnapshot.docs.isNotEmpty) {
      AppSnackBar.show(
        context,
        message: "You have already reviewed this book.",
        type: AppSnackBarType.warning,
      );
      return;
    }

    if (selectedRating != null && reviewController.text.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) throw Exception('User document not found.');

        final userData = userDoc.data() as Map<String, dynamic>;
        final fullName = userData['name']?.toString().trim() ?? '';
        final profileImage =
            userData['profile_image_url']?.toString().trim() ?? '';

        final review = {
          'bookId': widget.bookId,
          'userId': user.uid,
          'userName': fullName.isNotEmpty && !fullName.contains('@')
              ? fullName
              : (user.email ?? 'Anonymous'),
          'userImage': profileImage,
          'rating': selectedRating,
          'review': reviewController.text,
          'created_at': FieldValue.serverTimestamp(),
        };

        // ✅ Add review
        await FirebaseFirestore.instance.collection('book_reviews').add(review);

        // 🔁 Recalculate average rating
        final snapshot = await FirebaseFirestore.instance
            .collection('book_reviews')
            .where('bookId', isEqualTo: widget.bookId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final total = snapshot.docs.fold<double>(
            0.0,
            (sum, doc) => sum + (doc['rating'] as num).toDouble(),
          );
          final avgRating = total / snapshot.docs.length;

          await FirebaseFirestore.instance
              .collection('books')
              .doc(widget.bookId)
              .update({'averageRating': avgRating});
        }

        // ✅ Disable further review input
        setState(() {
          hasUserReviewed = true;
        });
        reviewController.clear();

        await fetchAverageRating();
        await fetchReviews();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully")),
        );
      } catch (e) {
        print("🔥 Error saving review: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit review.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter rating and review")),
      );
    }
  }

  Widget buildRatingStars({
    required double value,
    void Function(double)? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: onTap != null ? () => onTap(starValue) : null,
          child: Icon(
            value >= starValue ? HugeIconsSolid.star : HugeIconsStroke.star,
            color: Colors.amber,
            size: 45,
          ),
        );
      }),
    );
  }

  Future<void> _loadWishlistStatus() async {
    try {
      final exists = await WishlistManager.isInWishlist(widget.bookId);
      if (!mounted) return;
      setState(() => isFavorited = exists);
    } catch (e) {
      print("Error loading wishlist status: $e");
    }
  }

  Future<void> _toggleWishlist() async {
    final book = bookData!.data() as Map<String, dynamic>;
    final item = CartItem(
      bookId: widget.bookId,
      title: book['title'] ?? 'No Title',
      author: book['auther'] ?? 'No Category',
      imageUrl: book['cover_image_url'],
      price: (book['price'] as int).toDouble(),
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
          ? '${book['title'] ?? 'No Title'} added to wishlist'
          : '${book['title'] ?? 'No Title'} removed from wishlist',
      type: AppSnackBarType.success,
    );
  }

  Future<void> _loadCartQuantity() async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cartItems')
          .doc(widget.bookId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        final q = (data['quantity'] is int)
            ? data['quantity'] as int
            : ((data['quantity'] as num?)?.toInt() ?? 1);
        setState(() {
          selectedQty = q >= 1 ? q : 1;
        });
      } else {
        setState(() {
          selectedQty = 1;
        });
      }
    } catch (e) {
      print("Error loading cart quantity: $e");
    }
  }

  Future<void> _addToCartWithSelectedQty(Map<String, dynamic> book) async {
    final price = (book['price'] is int)
        ? (book['price'] as int).toDouble()
        : (book['price'] is double ? book['price'] as double : 0.0);
    final item = CartItem(
      bookId: widget.bookId,
      title: book['title'] ?? 'No Title',
      author: book['author'] ?? 'Unknown',
      imageUrl: book['cover_image_url'] ?? '',
      price: price,
      stock: (book['quantity'] ?? 0),
      quantity: selectedQty,
    );

    try {
      await CartManager.addToCart(item);
      await CartManager.updateQuantity(
        widget.bookId,
        selectedQty,
        context,
        stock: book['quantity'] ?? 0,
      );

      setState(() {
        itemExistsInCart = true;
      });

      AppSnackBar.show(
        context,
        message:
            '${item.title} ${itemExistsInCart ? "update cart" : "Add to cart"} added to cart',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      print("Error adding to cart: $e");
      AppSnackBar.show(
        context,
        message: 'Failed to add to cart',
        type: AppSnackBarType.error,
      );
    }
  }

  void _reviewDialog() {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Rate & Review this Book",
                      textAlign: TextAlign.center,
                      style: AppTheme.textLabel(
                        context,
                      ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                    ),

                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    buildRatingStars(
                      value: selectedRating ?? 0.0,
                      onTap: hasUserReviewed
                          ? null
                          : (value) {
                              setModalState(() {
                                selectedRating = value;
                              });
                              setState(() {});
                            },
                    ),

                    TextFormField(
                      controller: reviewController,
                      enabled: !hasUserReviewed,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: hasUserReviewed
                            ? "You already submitted a review."
                            : "Write your review here...",
                      ),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasUserReviewed
                            ? AppTheme.customListBg(context)
                            : MyColors.primary,
                      ),
                      onPressed: hasUserReviewed ? null : submitReview,
                      child: Text(
                        hasUserReviewed ? "Review Submitted" : "Submit Review",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
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

  void _allReviewDialog() {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "All Reviews",
                      textAlign: TextAlign.center,
                      style: AppTheme.textLabel(
                        context,
                      ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                    ),

                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    ...reviews.map(
                      (review) => Card(
                        color: AppTheme.customListBg(context),
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.cardDarkBg(context),
                            backgroundImage:
                                (review['userImage'] ?? '')
                                    .toString()
                                    .isNotEmpty
                                ? NetworkImage(review['userImage'])
                                : null,
                            child:
                                (review['userImage'] ?? '').toString().isEmpty
                                ? Icon(
                                    HugeIconsSolid.user03,
                                    color: AppTheme.iconColorThree(context),
                                  )
                                : null,
                          ),
                          title: Text(
                            review['userName'] ?? 'Anonymous',
                            style: AppTheme.textTitle(context),
                          ),
                          subtitle: Text(
                            review['review'] ?? '',
                            style: AppTheme.textLabel(context),
                          ),
                          trailing: Row(
                            spacing: 6,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                HugeIconsSolid.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              Text(
                                '${review['rating'] ?? ''}',
                                style: AppTheme.textSearchInfoLabeled(
                                  context,
                                ).copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (topThreeReviews.isEmpty) ...[
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _reviewDialog();
                        },
                        child: SizedBox(
                          height: 80,
                          child: Card(
                            color: AppTheme.customListBg(context),
                            elevation: 0,
                            child: Shimmer(
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  const Icon(HugeIconsStroke.tap01),
                                  Text(
                                    "Write your review here...",
                                    style: AppTheme.textLink(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
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

  @override
  Widget build(BuildContext context) {
    if (bookData == null) {
      return Scaffold(
        backgroundColor: AppTheme.screenBg(context),
        body: Center(child: LoadingLogo()),
      );
    }

    final book = bookData!.data() as Map<String, dynamic>;
    final int stock = (book['quantity'] is int)
        ? book['quantity'] as int
        : ((book['quantity'] as num?)?.toInt() ?? 0);

    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "Product Detail",
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
      body: SingleChildScrollView(
        child: Container(
          color: AppTheme.cardBg(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: book['cover_image_url'] != null
                        ? Image.network(
                            book['cover_image_url'],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            alignment: AlignmentGeometry.topCenter,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;

                              return Shimmer.fromColors(
                                baseColor: AppTheme.customListBg(context),
                                highlightColor: AppTheme.sliderHighlightBg(
                                  context,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.customListBg(context),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  height: 250,
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
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.customListBg(context),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Image(
                            image: AssetImage(
                              'assets/images/default_cover.jpg',
                            ),
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.screenBg(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            book['title'] ?? 'No Title',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.textTitle(
                              context,
                            ).copyWith(fontSize: 25),
                          ),
                        ),
                        InkWell(
                          onTap: _toggleWishlist,
                          child: Icon(
                            isFavorited
                                ? HugeIconsSolid.favourite
                                : HugeIconsStroke.favourite,
                            size: 22,
                            color: isFavorited
                                ? Colors.red
                                : AppTheme.iconColorThree(context),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 6),
                    Row(
                      spacing: 12,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
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
                              "${book['quantity'].toString().padLeft(2, '0') ?? 'No'} Stocks",
                              style: AppTheme.textLabel(
                                context,
                              ).copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              HugeIconsSolid.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${averageRating.toStringAsFixed(1)} (${reviews.length > 0 ? reviews.length.toString().padLeft(2, '0') : 'no'} reviews)",
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    const SizedBox(height: 16),
                    Text(
                      "Description",
                      style: AppTheme.textLink(
                        context,
                      ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book['description'] ??
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                      textAlign: TextAlign.justify,
                      style: AppTheme.textLabel(context).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      spacing: 16,
                      children: [
                        Text(
                          "Quantity",
                          style: AppTheme.textLink(
                            context,
                          ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.customListBg(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.sliderHighlightBg(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () async {
                                  if (selectedQty > 1) {
                                    setState(() => selectedQty--);
                                    await CartManager.updateQuantity(
                                      widget.bookId,
                                      selectedQty,
                                      context,
                                      stock: stock,
                                    );
                                  } else {
                                    AppSnackBar.show(
                                      context,
                                      message: "Minimum quantity is 1",
                                      type: AppSnackBarType.warning,
                                    );
                                  }
                                },
                                child: Icon(HugeIconsSolid.remove01, size: 14),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  selectedQty.toString().padLeft(2, '0'),
                                  style: AppTheme.textSearchInfoLabeled(
                                    context,
                                  ).copyWith(fontSize: 14),
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  if (selectedQty < stock) {
                                    setState(() => selectedQty++);
                                    await CartManager.updateQuantity(
                                      widget.bookId,
                                      selectedQty,
                                      context,
                                      stock: stock,
                                    );
                                  } else {
                                    AppSnackBar.show(
                                      context,
                                      message: "Maximum stock reached!",
                                      type: AppSnackBarType.warning,
                                    );
                                  }
                                },
                                child: Icon(HugeIconsSolid.add01, size: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Top Reviews",
                          style: AppTheme.textLink(
                            context,
                          ).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _allReviewDialog,
                              child: Text(
                                "See All",
                                style: AppTheme.textLink(context).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            if (!hasUserReviewed)
                              InkWell(
                                onTap: () {
                                  _reviewDialog();
                                },
                                child: Icon(
                                  HugeIconsSolid.commentAdd01,
                                  size: 18,
                                  color: AppTheme.iconColorTwo(context),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (topThreeReviews.isNotEmpty) ...[
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 80,
                          autoPlay: true,
                          clipBehavior: Clip.antiAlias,
                          enlargeStrategy: CenterPageEnlargeStrategy.scale,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          autoPlayInterval: const Duration(seconds: 3),
                          viewportFraction: 1.00,
                        ),
                        items: topThreeReviews.map((review) {
                          return Builder(
                            builder: (context) {
                              return Card(
                                color: AppTheme.customListBg(context),
                                elevation: 0,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppTheme.cardDarkBg(
                                      context,
                                    ),
                                    backgroundImage:
                                        (review['userImage'] ?? '')
                                            .toString()
                                            .isNotEmpty
                                        ? NetworkImage(review['userImage'])
                                        : null,
                                    child:
                                        (review['userImage'] ?? '')
                                            .toString()
                                            .isEmpty
                                        ? Icon(
                                            HugeIconsSolid.user03,
                                            color: AppTheme.iconColorThree(
                                              context,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    review['userName'] ?? 'Anonymous',
                                    style: AppTheme.textTitle(context),
                                  ),
                                  subtitle: Text(
                                    review['review'] ?? '',
                                    style: AppTheme.textLabel(context),
                                  ),
                                  trailing: Row(
                                    spacing: 6,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        HugeIconsSolid.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                      Text(
                                        '${review['rating'] ?? ''}',
                                        style: AppTheme.textSearchInfoLabeled(
                                          context,
                                        ).copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    if (topThreeReviews.isEmpty) ...[
                      InkWell(
                        onTap: () {
                          _reviewDialog();
                        },
                        child: SizedBox(
                          height: 80,
                          child: Card(
                            color: AppTheme.customListBg(context),
                            elevation: 0,
                            child: Shimmer(
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  const Icon(HugeIconsStroke.tap01),
                                  Text(
                                    "Write your review here...",
                                    style: AppTheme.textLink(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.dividerBg(context)),
                    const SizedBox(height: 16),
                    Row(
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
                              "\$${((book['price'] ?? 0) * selectedQty).toString()}",
                              style: AppTheme.textTitle(context).copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: stock > 0
                                ? () => _addToCartWithSelectedQty(book)
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 12,
                              children: [
                                Icon(HugeIconsSolid.shoppingBag01),
                                Text(
                                  itemExistsInCart
                                      ? "Update Cart"
                                      : "Add to Cart",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
