import 'package:bookify/components/loading_screen.dart';
import 'package:bookify/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '/models/cart_item.dart';
import '/managers/cart_manager.dart';
import '/screens/cart.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/text_theme.dart';
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
  List<Map<String, dynamic>> reviews = [];

  bool hasUserReviewed = false; // ✅ Flag to disable review input

  @override
  void initState() {
    super.initState();
    fetchBookData();
    fetchAverageRating();
    fetchReviews();
    checkIfUserReviewed(); // ✅ Check if user already reviewed
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
    final snapshot = await FirebaseFirestore.instance
        .collection('book_reviews')
        .where('bookId', isEqualTo: widget.bookId)
        .orderBy('created_at', descending: true)
        .get();

    setState(() {
      reviews = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  // ✅ Check if the logged-in user already reviewed this book
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already reviewed this book.")),
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
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: onTap != null ? () => onTap(starValue) : null,
          child: Icon(
            value >= starValue ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
        );
      }),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: book['cover_image_url'] != null
                            ? Image.network(
                                book['cover_image_url'],
                                width: 300,
                                height: 280,
                                fit: BoxFit.cover,
                              )
                            : const Image(
                                image: AssetImage(
                                  'assets/images/default_cover.jpg',
                                ),
                                width: 200,
                                height: 280,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      book['title'] ?? 'No Title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.textTitle(context).copyWith(fontSize: 25),
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
                              "10 Stocks",
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
                              "${averageRating.toStringAsFixed(1)} (${reviews.length.toString().padLeft(2, '0')} reviews)",
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (book.containsKey('author'))
                      Text(
                        "By ${book['author']}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      book['genre'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          "\$${book['price'] ?? 0}",
                          style: const TextStyle(
                            color: MyColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: MyColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          color: MyColors.primary,
                          onPressed: () {
                            final item = CartItem(
                              bookId: widget.bookId,
                              title: book['title'] ?? 'No Title',
                              author: book['author'] ?? 'Unknown',
                              imageUrl: book['cover_image_url'] ?? '',
                              price: (book['price'] is int)
                                  ? (book['price'] as int).toDouble()
                                  : (book['price'] ?? 0.0),
                              stock: (book['quantity'] ?? 10),
                            );
                            CartManager.addToCart(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.title} added to cart'),
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book['description'] ?? "No description available.",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Rate & Review this Book",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: MyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ✅ Disable stars if user already reviewed
                    buildRatingStars(
                      value: selectedRating ?? 0.0,
                      onTap: hasUserReviewed
                          ? null
                          : (val) => setState(() => selectedRating = val),
                    ),

                    const SizedBox(height: 10),
                    TextFormField(
                      controller: reviewController,
                      maxLines: 3,
                      enabled: !hasUserReviewed, // ✅ disable input
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: hasUserReviewed
                            ? "You already submitted a review."
                            : "Write your review here...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasUserReviewed
                              ? Colors.grey
                              : MyColors.primary,
                        ),
                        onPressed: hasUserReviewed ? null : submitReview,
                        child: Text(
                          hasUserReviewed
                              ? "Review Submitted"
                              : "Submit Review",
                          style: TextStyle(
                            color: Colors.white, // keep text visible
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "User Reviews",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: MyColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...reviews.map(
                      (review) => Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                (review['userImage'] ?? '')
                                    .toString()
                                    .isNotEmpty
                                ? NetworkImage(review['userImage'])
                                : null,
                            child:
                                (review['userImage'] ?? '').toString().isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(
                            review['userName'] ?? 'Anonymous',
                            style: const TextStyle(color: MyColors.primary),
                          ),
                          subtitle: Text(
                            review['review'] ?? '',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              Text(
                                '${review['rating'] ?? ''}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
