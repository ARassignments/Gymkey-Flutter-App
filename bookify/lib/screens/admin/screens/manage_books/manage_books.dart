import 'package:bookify/components/loading_screen.dart';
import 'package:bookify/components/not_found.dart';
import 'package:bookify/screens/book_detail_page.dart';
import 'package:bookify/utils/themes/themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/providers/search_provider.dart';
import '/screens/admin/screens/manage_books/add_books.dart';
import '/screens/admin/screens/manage_books/edit_books.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/screens/auth/users/sign_in.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBooks extends ConsumerStatefulWidget {
  const ManageBooks({super.key});

  @override
  ConsumerState<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends ConsumerState<ManageBooks>
    with AutomaticKeepAliveClientMixin {
  final auth = FirebaseAuth.instance;

  String selectedCategory = 'All Products';

  List<String> categories = ['All Products'];

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .get();

    final fetched = snapshot.docs
        .map((doc) => (doc['name'] ?? '').toString())
        .toList();

    setState(() {
      categories = ['All Products', ...fetched];
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }

  void _searchBooks() => setState(() {});

  // ---------- Safe getters ----------
  T? _get<T>(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is T) return v;
    return null;
  }

  dynamic _getAny(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k)) return m[k];
    }
    return null;
  }

  // ---------- Normalizers ----------
  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == 'true' || s == 'yes' || s == '1' || s == 'y';
    }
    return false;
  }

  String _norm(String? s) => (s ?? '').trim().toLowerCase();

  Set<String> _normStringSet(dynamic listish) {
    final out = <String>{};
    if (listish is List) {
      for (final e in listish) {
        out.add(_norm(e?.toString()));
      }
    }
    return out;
  }

  // Combine possible tag arrays
  Set<String> _collectTags(Map<String, dynamic> data) {
    final keys = ['tags', 'labels', 'badges', 'categories'];
    final set = <String>{};
    for (final k in keys) {
      set.addAll(_normStringSet(_getAny(data, [k])));
    }
    return set;
  }

  // Check any of many keys for a truthy flag
  bool _hasAnyTruthy(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      if (data.containsKey(k) && _asBool(data[k])) return true;
    }
    return false;
  }

  // ---------- Category match logic (very robust) ----------
  bool _matchesCategory(Map<String, dynamic> data) {
    final cat = selectedCategory;

    if (cat == 'All Products') return true;

    // Genre fallback across fields
    final genreLike = _norm(
      _getAny(data, ['genre', 'category', 'type'])?.toString(),
    );

    // Tag & flag sets
    final tags = _collectTags(data);

    if (cat == 'Featured') {
      final flag = _hasAnyTruthy(data, [
        'isFeatured',
        'featured',
        'is_featured',
        'is-featured',
        'feature',
        'isFeature',
      ]);
      final inTags = tags.contains('featured') || tags.contains('feature');
      return flag || inTags;
    }

    if (cat == 'Popular') {
      final flag = _hasAnyTruthy(data, [
        'isPopular',
        'popular',
        'is_popular',
        'is-popular',
        'hot',
        'trending',
        'isTrending',
      ]);
      final inTags =
          tags.contains('popular') ||
          tags.contains('hot') ||
          tags.contains('trending');
      return flag || inTags;
    }

    if (cat == 'Best Selling') {
      final flag = _hasAnyTruthy(data, [
        'isBestSelling',
        'bestSelling',
        'best_selling',
        'best-selling',
        'bestseller',
        'bestSeller',
        'isBestseller',
      ]);
      final inTags =
          tags.contains('best selling') ||
          tags.contains('best_selling') ||
          tags.contains('best-selling') ||
          tags.contains('bestseller') ||
          tags.contains('best seller');
      return flag || inTags;
    }

    // Otherwise treat as a genre category
    return genreLike == _norm(cat);
  }

  // ---------- Search match ----------
  bool _matchesSearch(Map<String, dynamic> data, String q) {
    if (q.isEmpty) return true;
    final title = _norm(data['title']?.toString());
    final author = _norm(data['author']?.toString());
    final price = _norm(data['price']?.toString());
    final genre = _norm(
      _getAny(data, ['genre', 'category', 'type'])?.toString(),
    );

    final terms = q
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty);
    bool termOK(String t) =>
        title.contains(t) ||
        author.contains(t) ||
        genre.contains(t) ||
        price.contains(t);

    for (final t in terms) {
      if (!termOK(t)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('categories')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingLogo());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: NotFoundWidget(
                          title: "No categories found",
                          message: "",
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    final dynamicCategories = [
                      'All Products',
                      ...docs.map((e) => e['name'].toString()).toList(),
                    ];

                    return SizedBox(
                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dynamicCategories.length,
                        itemBuilder: (context, index) {
                          final cat = dynamicCategories[index];
                          final isSelected = selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: InkWell(
                              onTap: () =>
                                  setState(() => selectedCategory = cat),
                              child: Container(
                                height: 8,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? MyColors.primary
                                      : AppTheme.customListBg(context),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: isSelected
                                        ? MyColors.primary
                                        : AppTheme.sliderHighlightBg(context),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    cat,
                                    style: AppTheme.textLabel(context).copyWith(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.iconColor(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Books list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<QuerySnapshot>(
                  // Saare books laao; filtering neeche client-side hogi
                  stream: FirebaseFirestore.instance
                      .collection('books')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingLogo());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: NotFoundWidget(
                          title: "No products found",
                          message: "",
                        ),
                      );
                    }

                    final q = searchQuery;
                    final docs = snapshot.data!.docs;

                    // 1) Category filter
                    final byCategory = docs.where((doc) {
                      final data = (doc.data() as Map<String, dynamic>?) ?? {};
                      return _matchesCategory(data);
                    }).toList();

                    // 2) Search filter
                    final filteredBooks = byCategory.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _matchesSearch(data, q);
                    }).toList();

                    if (filteredBooks.isEmpty) {
                      return const Center(
                        child: NotFoundWidget(
                          title: "No products found",
                          message: "",
                        ),
                      );
                    }

                    return Column(
                      spacing: 12,
                      children: filteredBooks.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        return Dismissible(
                          key: Key(doc.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg(context),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
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
                                  direction: ShimmerDirection.ltr,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 12,
                                    children: [
                                      Icon(
                                        HugeIconsSolid.delete01,
                                        color: AppColor.accent_50,
                                        size: 24,
                                      ),
                                      Text(
                                        "Swipe right to remove",
                                        style: AppTheme.textLink(context)
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                      ),
                                      const Icon(HugeIconsStroke.swipeRight01),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg(context),
                              borderRadius: BorderRadius.circular(12),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 12,
                                    children: [
                                      const Icon(HugeIconsStroke.swipeLeft01),
                                      Text(
                                        "Swipe left to edit",
                                        style: AppTheme.textLink(context)
                                            .copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                      ),
                                      Icon(
                                        HugeIconsSolid.edit01,
                                        color: AppColor.accent_50,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditBooks(bookId: doc.id, bookData: data),
                                ),
                              );
                              return false;
                            } else if (direction ==
                                DismissDirection.startToEnd) {
                              await FirebaseFirestore.instance
                                  .collection('books')
                                  .doc(doc.id)
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Product deleted successfully!',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return true;
                            }
                            return false;
                          },
                          child: InkWell(
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
                                        bookId: doc.id,
                                        forAdmin: true,
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
                            child: Card(
                              color: AppTheme.customListBg(context),
                              margin: EdgeInsets.all(0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          (data['cover_image_url'] != null &&
                                              data['cover_image_url']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? Image.network(
                                              data['cover_image_url'],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                    ),

                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (data['title'] ?? '').toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTheme.textTitle(context),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (_getAny(data, [
                                                      'genre',
                                                      'category',
                                                      'type',
                                                    ]) ??
                                                    '')
                                                .toString(),
                                            style: AppTheme.textLabel(context),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${(data['price'] ?? '').toString()}',
                                            style:
                                                AppTheme.textSearchInfoLabeled(
                                                  context,
                                                ).copyWith(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddBooks()),
          );
        },
        backgroundColor: AppTheme.customListBg(context),
        child: Icon(HugeIconsStroke.add01, color: AppTheme.iconColor(context)),
      ),
    );
  }
}
