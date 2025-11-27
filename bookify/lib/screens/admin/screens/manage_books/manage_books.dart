import 'dart:async';
import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/screens/book_detail_page.dart';
import '/utils/themes/themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/providers/search_provider.dart';
import '/screens/admin/screens/manage_books/add_books.dart';
import '/screens/admin/screens/manage_books/edit_books.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBooks extends ConsumerStatefulWidget {
  const ManageBooks({super.key});

  @override
  ConsumerState<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends ConsumerState<ManageBooks>
    with AutomaticKeepAliveClientMixin {
  final auth = FirebaseAuth.instance;
  StreamSubscription? _catsSub;
  StreamSubscription? _booksSub;

  // Local caches (offline filtering)
  List<QueryDocumentSnapshot> _allBooks = [];
  List<QueryDocumentSnapshot> _allCategories = [];

  // UI state
  String selectedCategory = 'All Products';
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listenToFirestore();
    // _loadAll();
  }

  void _listenToFirestore() {
    setState(() => _loading = true);

    // Listen to categories
    _catsSub = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            setState(() {
              _allCategories = snapshot.docs;
              _loading = false;
            });
          },
          onError: (error) {
            setState(() {
              _error = "Failed to load categories";
              _loading = false;
            });
          },
        );

    // Listen to books
    _booksSub = FirebaseFirestore.instance
        .collection('books')
        .orderBy('created_at', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            setState(() {
              _allBooks = snapshot.docs;
              _loading = false;
            });
          },
          onError: (error) {
            setState(() {
              _error = "Failed to load books";
              _loading = false;
            });
          },
        );
  }

  @override
  void dispose() {
    _catsSub?.cancel();
    _booksSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // fetch categories and books in parallel
      final catsFuture = FirebaseFirestore.instance
          .collection('categories')
          .get();
      final booksFuture = FirebaseFirestore.instance.collection('books').get();

      final results = await Future.wait([catsFuture, booksFuture]);

      final cats = results[0] as QuerySnapshot;
      final books = results[1] as QuerySnapshot;

      if (!mounted) return;

      setState(() {
        _allCategories = cats.docs;
        _allBooks = books.docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load data';
      });
    }
  }

  Future<void> _refresh() async => _listenToFirestore();

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

  // ---------- Category matching ----------
  bool _matchesCategory(Map<String, dynamic> data) {
    final cat = selectedCategory;

    if (cat == 'All Products') return true;

    final genreLike = _norm(
      _getAny(data, ['genre', 'category', 'type'])?.toString(),
    );

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

    // treat as a genre/category name
    return genreLike == _norm(cat);
  }

  // ---------- Search matching ----------
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

  // ---------- Derived filtered list ----------
  List<QueryDocumentSnapshot> _filteredBooks(String searchQuery) {
    final q = searchQuery.trim().toLowerCase();
    final byCategory = _allBooks.where((doc) {
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      return _matchesCategory(data);
    }).toList();

    final bySearch = byCategory.where((doc) {
      final data = (doc.data() as Map<String, dynamic>);
      return _matchesSearch(data, q);
    }).toList();

    return bySearch;
  }

  List<String> _categoryNames() {
    final names = _allCategories
        .map((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['name'] ?? '').toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
    return ['All Products', ...names];
  }

  // ---------- UI helpers ----------
  Widget _buildChips() {
    final dynamicCategories = _categoryNames();

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
              onTap: () => setState(() => selectedCategory = cat),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
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
  }

  Widget _buildBookTile(QueryDocumentSnapshot doc, int index) {
    final data = doc.data() as Map<String, dynamic>;
    final num discount = int.tryParse(data['discount']?.toString() ?? '0') ?? 0;
    final double discountedPrice =
        (double.tryParse(data['price']?.toString() ?? '0') ?? 0.0) -
        (((double.tryParse(data['price']?.toString() ?? '0') ?? 0.0) *
                discount) /
            100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
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
                  children: [
                    Icon(
                      HugeIconsSolid.delete01,
                      color: AppColor.accent_50,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Swipe right to remove",
                      style: AppTheme.textLink(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
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
                  children: [
                    const Icon(HugeIconsStroke.swipeLeft01),
                    const SizedBox(width: 8),
                    Text(
                      "Swipe left to edit",
                      style: AppTheme.textLink(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
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
            // edit
            showModalBottomSheet(
              context: context,
              isDismissible: false,
              enableDrag: false,
              showDragHandle: true,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              builder: (ctx) => EditBooks(bookId: doc.id, bookData: data),
            );
            return false;
          }

          if (direction == DismissDirection.startToEnd) {
            final bool? confirmDelete = await showModalBottomSheet<bool>(
              context: context,
              isDismissible: false,
              enableDrag: false,
              showDragHandle: true,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              builder: (ctx) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Column(
                    spacing: 16,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Confirm Delete",
                        textAlign: TextAlign.center,
                        style: AppTheme.textLabel(
                          ctx,
                        ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      Divider(height: 1, color: AppTheme.dividerBg(ctx)),
                      Text(
                        "Are you sure you want to delete '${data['title'] ?? ''}' product?",
                        textAlign: TextAlign.center,
                        style: AppTheme.textLabel(ctx),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          overlayColor: AppColor.accent_50.withOpacity(0.1),
                          backgroundColor: AppColor.accent_50,
                        ),
                        child: Text(
                          'Yes, Remove',
                          style: TextStyle(color: AppColor.white),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                      OutlinedButton(
                        child: const Text("Cancel"),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                );
              },
            );

            if (confirmDelete == true) {
              await FirebaseFirestore.instance
                  .collection('books')
                  .doc(doc.id)
                  .delete();
              if (!mounted) return true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Product deleted successfully!")),
              );
              return true;
            }
            return false;
          }

          return false;
        },
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    BookDetailPage(bookId: doc.id, forAdmin: true),
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
          child: Card(
            color: AppTheme.customListBg(context),
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.sliderHighlightBg(context),
                    ),
                    child: Center(
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: AppTheme.textSearchInfoLabeled(context),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            (data['cover_image_url'] != null &&
                                data['cover_image_url'].toString().isNotEmpty)
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
                      if (discount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.accent_50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${discount.toString().padLeft(2, '0')}% OFF",
                              style: AppTheme.textLabel(context).copyWith(
                                fontSize: 7,
                                color: AppColor.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (data['title'] ?? '').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.textTitle(context),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_getAny(data, ['genre', 'category', 'type']) ?? '')
                              .toString(),
                          style: AppTheme.textLabel(context),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          spacing: 6,
                          children: [
                            Text(
                              '\$${discount > 0 ? discountedPrice :(data['price'] ?? '' as int).toString()}',
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 14),
                            ),
                            if (discount > 0)
                              Text(
                                '\$${(data['price'] ?? '' as int).toString()}',
                                style: AppTheme.textSearchInfoLabeled(context)
                                    .copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.lineThrough,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // watch search provider reactively
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    // compute filtered list from local cache
    final filteredBooks = _filteredBooks(searchQuery);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _loading
                  ? const Center(child: LoadingLogo())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _allBooks.isEmpty
                  ? Center(
                      child: NotFoundWidget(
                        title: "No products found",
                        message: "",
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // chips
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 12,
                            ),
                            child: _buildChips(),
                          ),

                          // search result header (if searching)
                          if (searchQuery.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: AppTheme.textSearchInfo(context),
                                      children: [
                                        const TextSpan(text: 'Result for "'),
                                        TextSpan(
                                          text: searchQuery,
                                          style: AppTheme.textSearchInfoLabeled(
                                            context,
                                          ),
                                        ),
                                        const TextSpan(text: '"'),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      style: AppTheme.textSearchInfoLabeled(
                                        context,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: filteredBooks.length.toString(),
                                        ),
                                        const TextSpan(text: ' found'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 8),

                          // list
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: filteredBooks.isEmpty
                                ? Center(
                                    child: NotFoundWidget(
                                      title: "No products found",
                                      message: "",
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      filteredBooks.length,
                                      (i) {
                                        final doc = filteredBooks[i];
                                        return _buildBookTile(doc, i);
                                      },
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 80), // spacing for FAB
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        isExtended: true,
        foregroundColor: AppTheme.iconColor(context),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            showDragHandle: true,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) => const AddBooks(),
          );
        },
        backgroundColor: AppTheme.customListBg(context),
        label: Row(
          spacing: 8,
          children: [
            Icon(
              HugeIconsStroke.add01,
              color: AppTheme.iconColor(context),
              size: 20,
            ),
            Text("Add Product", style: AppTheme.textLabel(context)),
          ],
        ),
      ),
    );
  }
}
