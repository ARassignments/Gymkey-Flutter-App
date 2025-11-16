import 'dart:io' show Platform;
import 'package:hugeicons_pro/hugeicons.dart';
import '/components/dashboard_slider.dart';
import '/components/loading_screen.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import '/components/not_found.dart';
import '/utils/themes/themes.dart';
import 'package:flutter/services.dart';
import '/screens/book_detail_page.dart';
import '/utils/themes/custom_themes/bookcard.dart';
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
  int _currentIndex = 0;
  final ZoomDrawerController _drawerController = ZoomDrawerController();

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
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardSlider(
                      slidesData: [
                        _buildSliderCard(
                          title: '',
                          subtitle: '',
                          image: 'assets/images/banner1.png',
                        ),
                        _buildSliderCard(
                          title: '',
                          subtitle: '',
                          image: 'assets/images/banner2.png',
                        ),
                        _buildSliderCard(
                          title: '',
                          subtitle: '',
                          image: 'assets/images/banner3.png',
                        ),
                      ],
                    ),

                    // ===== Dynamic Categories Section =====
                    categories.isEmpty
                        ? Center(child: LoadingLogo())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Categories",
                                style: AppTheme.textLabel(context).copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CategoryDetailPage(
                                              category: category,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: Container(
                                          height: 8,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.customListBg(
                                              context,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.sliderHighlightBg(
                                                context,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              category,
                                              style: AppTheme.textLabel(
                                                context,
                                              ).copyWith(fontSize: 12),
                                            ),
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
                            category,
                          ),
                          const SizedBox(height: 30),
                        ],
                      );
                    }).toList(),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Need Help?",
                        style: AppTheme.textLabel(
                          context,
                        ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: Opacity(
                            opacity: 0.5,
                            child: InkWell(
                              child: Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.customListBg(context),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        "FAQs",
                                        style: AppTheme.textLink(context)
                                            .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -40,
                                    bottom: -35,
                                    child: Image.asset(
                                      "assets/images/faqs_image.png",
                                      height: 180,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Opacity(
                            opacity: 0.5,
                            child: InkWell(
                              child: Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    height: 100,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppTheme.customListBg(context),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        "Chat Now",
                                        style: AppTheme.textLink(context)
                                            .copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -40,
                                    bottom: -28,
                                    child: Image.asset(
                                      "assets/images/chat_image.png",
                                      height: 180,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
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
    return Material(
      elevation: 0,
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
              alignment: AlignmentGeometry.topCenter,
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
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.textTitle(
                    context,
                  ).copyWith(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Helper: Section Header =====
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryDetailPage(category: title),
              ),
            );
          },
          child: Text(
            "See All",
            style: AppTheme.textLink(
              context,
            ).copyWith(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  // ===== Helper: Horizontal Book List =====
  Widget _buildHorizontalBookList(
    Future<QuerySnapshot> future,
    String category,
  ) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<QuerySnapshot>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: LoadingLogo());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: NotFoundWidget(
                title: "Not Found Products",
                message: "",
                size: 140,
              ),
            );
          }

          final books = snapshot.data!.docs;
          final displayBooks = books
              .take(6)
              .toList(); // Show only 6 items initially

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 16),
            children: [
              ...displayBooks.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bookId = doc.id;

                return InkWell(
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
                );
              }),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailPage(category: category),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: EdgeInsets.only(left: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.customListBg(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 6,
                      children: [
                        Text('Load More', style: AppTheme.textTitle(context)),
                        Icon(HugeIconsSolid.arrowRight01, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "${category} Category",
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
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('books')
            .where('category', isEqualTo: category)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingLogo());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: NotFoundWidget(
                title: "No products available.",
                message: "",
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
              childAspectRatio: 0.85,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final bookId = books[index].id;

              return InkWell(
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
                  stock: (data['stock'] ?? 0).toDouble(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
