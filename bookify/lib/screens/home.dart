import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:bookify/screens/book_detail_page.dart';
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
          content: Text('Tap once more to exit'),
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
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      final fetchedCategories = snapshot.docs
          .map((doc) => doc['name'] as String)
          .toList();

      if (mounted) {
        setState(() {
          categories = fetchedCategories;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildSlider(),
                        const SizedBox(height: 30),

                        // ===== Dynamic Categories Section =====
                        categories.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Categories",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFF0059a7),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 45,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: categories.length,
                                      itemBuilder: (context, index) {
                                        final category = categories[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              border: Border.all(
                                                color: MyColors.primary,
                                              ),
                                            ),
                                            child: Text(
                                              category,
                                              style: const TextStyle(
                                                color: MyColors.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 30),

                        // ===== Dynamic Product Sections per Category =====
                        ...categories.map((category) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(context, category),
                              const SizedBox(height: 10),
                              _buildHorizontalBookList(
                                FirebaseFirestore.instance
                                    .collection('books')
                                    .where('category', isEqualTo: category)
                                    .get(),
                              ),
                              const SizedBox(height: 30),
                            ],
                          );
                        }).toList(),
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

  // ===== Helper: Slider =====
  Widget _buildSlider() {
    return SizedBox(
      height: 220,
      child: PageView(
        controller: PageController(viewportFraction: 0.85),
        children: [
          _buildSliderCard(
            title: 'Bookify Special Offers',
            subtitle: 'Get your favorites today!',
            image: 'assets/images/banner1.webp',
          ),
          _buildSliderCard(
            title: 'Top Reads of the Month',
            subtitle: 'Trending now on Bookify',
            image: 'assets/images/banner1.webp',
          ),
          _buildSliderCard(
            title: 'Discover New Authors',
            subtitle: 'Fresh stories every week',
            image: 'assets/images/banner1.webp',
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required String image,
  }) {
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
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
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
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: MyTextTheme.lightTextTheme.headlineSmall),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailPage(category: title),
              ),
            );
          },
          child: const Text(
            "See All",
            style: TextStyle(
              color: MyColors.primary,
              fontWeight: FontWeight.w600,
            ),
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products found.',
                style: TextStyle(color: Color(0xFF0059a7)),
              ),
            );
          }

          final books = snapshot.data!.docs;
          return ListView(
            scrollDirection: Axis.horizontal,
            children: books.take(6).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final bookId = doc.id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          BookDetailPage(bookId: bookId),
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
                child: Hero(
                  tag: bookId,
                  child: Material(
                    color: const Color(0xFFeeeeee),
                    child: BookCard(
                      bookId: bookId,
                      title: data['title'] ?? 'Untitled',
                      author: data['description'] ?? 'Unknown Author',
                      imagePath:
                          data['cover_image_url'] ??
                          'assets/images/placeholder.jpg',
                      category: data['category'] ?? 'Uncategorized',
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

// ===== Separate Page for "See All" per Category =====
class CategoryDetailPage extends StatelessWidget {
  final String category;
  const CategoryDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category), backgroundColor: MyColors.primary),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('books')
            .where('category', isEqualTo: category)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products available.',
                style: TextStyle(color: Color(0xFF0059a7)),
              ),
            );
          }

          final books = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final bookId = books[index].id;

              return BookCard(
                bookId: bookId,
                title: data['title'],
                author: data['author'],
                imagePath: data['cover_image_url'],
                category: data['category'],
                price: (data['price'] ?? 0).toDouble(),
                rating: (data['rating'] ?? 0).toDouble(),
              );
            },
          );
        },
      ),
    );
  }
}
