import 'dart:io' show Platform;
import 'package:flutter/services.dart'; // SystemNavigator.pop()
import 'package:bookify/screens/all_books.dart';
import 'package:bookify/screens/book_detail_page.dart';
import 'package:bookify/screens/categories/best_seller.dart';
import 'package:bookify/screens/categories/featured_books.dart';
import 'package:bookify/screens/categories/popular_books.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/app_navbar.dart';
import 'package:bookify/utils/themes/custom_themes/bookcard.dart';
import 'package:bookify/utils/themes/custom_themes/bottomnavbar.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  // double-back to exit helper
  DateTime? _lastBack;
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final pressedTwice =
        _lastBack != null &&
        now.difference(_lastBack!) <= const Duration(seconds: 2);

    if (pressedTwice) {
      if (Platform.isAndroid) {
        SystemNavigator.pop();
        return false;
      }
      return true;
    }

    _lastBack = now;
    if (!mounted) return false;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Tap one more to exit'),
          duration: Duration(seconds: 2),
        ),
      );
    return false;
  }

List<String> categories = [];

@override
void initState() {
  super.initState();
  fetchCategories();
}

Future<void> fetchCategories() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    final fetchedCategories =
        snapshot.docs.map((doc) => doc['name'] as String).toList();

    if (mounted) {
      setState(() {
        categories = fetchedCategories;
      });
    }
  } catch (e) {
    print('Error fetching categories: $e');
  }
}


  void navigateToCategory(String title) {
    if (title == 'Novels') {
      Navigator.pushNamed(context, '/novels');
    } else if (title == 'Self Love') {
      Navigator.pushNamed(context, '/self-love');
    } else if (title == 'Science') {
      Navigator.pushNamed(context, '/science');
    } else if (title == 'Romance') {
      Navigator.pushNamed(context, '/romance');
    } else if (title == 'History') {
      Navigator.pushNamed(context, '/history');
    } else if (title == 'Fantasy') {
      Navigator.pushNamed(context, '/fantasy');
    } else if (title == 'Poetry') {
      Navigator.pushNamed(context, '/poetry');
    } else if (title == 'Action') {
      Navigator.pushNamed(context, '/action');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No page found for category: $title")),
      );
    }
  }

  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // wrap Scaffold with WillPopScope
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFeeeeee),
        bottomNavigationBar: buildCurvedNavBar(context, 0),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              CustomNavBar(searchController: searchController),
              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // ===== Gym-Style Slider =====
                        SizedBox(
                          height: 220,
                          child: PageView(
                            controller: PageController(viewportFraction: 0.85),
                            children: [
                              _buildSliderCard(
                                title: 'Get Fit with GymX',
                                subtitle: 'Top Fitness Programs',
                                image: 'assets/images/banner1.webp',
                              ),
                              _buildSliderCard(
                                title: 'Yoga & Stretching',
                                subtitle: 'Relax & Flex',
                                image: 'assets/images/banner1.webp',
                              ),
                              _buildSliderCard(
                                title: 'Muscle Building',
                                subtitle: 'Strength & Power',
                                image: 'assets/images/banner1.webp',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // ===== Categories =====
                       SizedBox(
                        height: 45,
                        child: categories.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: GestureDetector(
                                      onTap: () => navigateToCategory(categories[index]),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(
                                            color: MyColors.primary,
                                          ),
                                        ),
                                        child: Text(
                                          categories[index],
                                          style: const TextStyle(
                                            color: MyColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                        const SizedBox(height: 30),

                        // ===== Featured Books Section =====
                        _buildSectionHeader(
                          context,
                          'Featured Products',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const FeaturedPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHorizontalBookList(
                          FirebaseFirestore.instance
                              .collection('books')
                              .where('is_featured', isEqualTo: true)
                              .get(),
                        ),

                        const SizedBox(height: 30),
                        _buildSectionHeader(
                          context,
                          'Popular Products',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PopularPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHorizontalBookList(
                          FirebaseFirestore.instance
                              .collection('books')
                              .where('is_popular', isEqualTo: true)
                              .get(),
                        ),

                        const SizedBox(height: 30),
                        _buildSectionHeader(
                          context,
                          'Best Selling Products',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BestSellerPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHorizontalBookList(
                          FirebaseFirestore.instance
                              .collection('books')
                              .where('is_best_selling', isEqualTo: true)
                              .get(),
                        ),

                        const SizedBox(height: 30),
                        _buildSectionHeader(
                          context,
                          'Explore All Products',
                          onSeeAll: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AllBooksPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildHorizontalBookList(
                          FirebaseFirestore.instance.collection('books').get(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Helper: Slider Card =====
  Widget _buildSliderCard(
      {required String title,
      required String subtitle,
      required String image}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  // ===== Helper: Section Header =====
  Widget _buildSectionHeader(BuildContext context, String title,
      {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: MyTextTheme.lightTextTheme.headlineSmall,
        ),
        InkWell(
          onTap: onSeeAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "See All",
                style: TextStyle(
                  color: MyColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Helper: Horizontal Book List =====
  Widget _buildHorizontalBookList(Future<QuerySnapshot> future) {
    return SizedBox(
      height: 260,
      child: FutureBuilder<QuerySnapshot>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No Products available.'),
            );
          }

          List<QueryDocumentSnapshot> books = snapshot.data!.docs;

          return ListView(
            scrollDirection: Axis.horizontal,
            children: books.take(6).map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String bookId = doc.id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                      ) =>
                          BookDetailPage(bookId: bookId),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: Hero(
                  tag: bookId,
                  child: Material(
                    color: const Color(0xFFeeeeee),
                    child: BookCard(
                      bookId: bookId,
                      title: data['title'],
                      author: data['author'],
                      imagePath: data['cover_image_url'],
                      category: data['genre'],
                      price: (data['price'] ?? 0).toDouble(),
                      rating: (data['rating'] ?? 0).toDouble(),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
