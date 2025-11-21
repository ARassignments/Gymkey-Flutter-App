import '/components/loading_screen.dart';
import '/components/not_found.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/screens/book_detail_page.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/bookcard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AllBooksPage extends StatefulWidget {
  const AllBooksPage({super.key});

  @override
  State<AllBooksPage> createState() => _AllBooksPageState();
}

class _AllBooksPageState extends State<AllBooksPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;

  // client-side sort state
  String _currentSortField = 'title'; // 'title' | 'price' | 'rating'
  bool _isDescending = false;

  late Stream<QuerySnapshot> _booksStream;

  final List<String> categories = const [
    'Novels',
    'Self Love',
    'Science',
    'Romance',
    'History',
    'Fantasy',
    'Poetry',
    'Action',
  ];

  @override
  void initState() {
    super.initState();
    _updateStream();
    searchController.addListener(_onSearchChanged); // live search
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {}); // re-render while typing

  // Firestore stream without server-side sort (client-side only)
  void _updateStream() {
    _booksStream = FirebaseFirestore.instance.collection('books').snapshots();
  }

  void navigateToCategory(String title) {
    final routes = {
      'Novels': '/novels',
      'Self Love': '/self-love',
      'Science': '/science',
      'Romance': '/romance',
      'History': '/history',
      'Fantasy': '/fantasy',
      'Poetry': '/poetry',
      'Action': '/action',
    };
    if (routes.containsKey(title)) {
      Navigator.pushNamed(context, routes[title]!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No page found for category: $title")),
      );
    }
  }

  // in-memory sort toggle
  void sortBooks(String criteria) {
    setState(() {
      switch (criteria) {
        case "Price: Low to High":
          _currentSortField = 'price';
          _isDescending = false;
          break;
        case "Price: High to Low":
          _currentSortField = 'price';
          _isDescending = true;
          break;
        case "Top Rated":
          _currentSortField = 'rating';
          _isDescending = true; // high → low
          break;
        default:
          _currentSortField = 'title';
          _isDescending = false;
      }
    });
  }

  // ---------- Search helpers ----------
  bool _matchesQuery(Map<String, dynamic> book, String query) {
    if (query.isEmpty) return true;

    final title = (book['title'] ?? '').toString().toLowerCase();
    final author = (book['author'] ?? '').toString().toLowerCase();
    final genre = (book['genre'] ?? '').toString().toLowerCase();

    final priceVal = (book['price'] ?? 0);
    final double price = priceVal is num
        ? priceVal.toDouble()
        : double.tryParse(priceVal.toString()) ?? 0.0;

    final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
    bool termOK(String t) =>
        title.contains(t) ||
        author.contains(t) ||
        genre.contains(t) ||
        price.toString().contains(t);

    for (final t in terms) {
      if (t.isEmpty) continue;
      if (!termOK(t)) return false; // AND-style matching across terms
    }
    return true;
  }

  // ---------- Parse helpers ----------
  num _numOf(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v) ?? 0;
    return 0;
  }

  int _intOf(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  String _strOf(dynamic v) => (v ?? '').toString().toLowerCase();

  /// rating extractor (flexible keys + string parsing)
  double? _ratingOf(Map<String, dynamic> m) {
    dynamic v =
        m['averageRating'] ??
        m['rating'] ??
        m['avgRating'] ??
        m['ratingValue'] ??
        (m['ratings'] is Map
            ? (m['ratings']['average'] ?? m['ratings']['avg'])
            : null) ??
        (m['rating'] is Map
            ? (m['rating']['value'] ?? m['rating']['avg'])
            : null);

    double? tryNum(dynamic x) {
      if (x is num) return x.toDouble();
      if (x is String) {
        final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(x);
        if (match != null) {
          final normalized = match.group(1)!.replaceAll(',', '.');
          return double.tryParse(normalized);
        }
      }
      return null;
    }

    final parsed = tryNum(v);
    if (parsed == null) return null;
    return parsed.clamp(0.0, 5.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final q = searchController.text.trim();

    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "All Items",
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text("Categories", style: AppTheme.textTitle(context)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => navigateToCategory(categories[index]),
                        child: Container(
                          height: 8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.customListBg(context),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: AppTheme.sliderHighlightBg(context),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              categories[index],
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
            ),

            const SizedBox(height: 16),

            // Filter + Title Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    q.isEmpty ? "Our All Books" : 'Results for “$q”',
                    style: AppTheme.textTitle(context),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: AppTheme.customListBg(context),
                        surfaceTintColor: Colors.transparent,
                        textStyle: AppTheme.textLabel(context),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        HugeIconsStroke.sorting05,
                        color: AppTheme.iconColor(context),
                      ),
                      onSelected: sortBooks,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "Price: Low to High",
                          child: Text(
                            "Price: Low to High",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                        PopupMenuItem(
                          value: "Price: High to Low",
                          child: Text(
                            "Price: High to Low",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                        PopupMenuItem(
                          value: "Top Rated",
                          child: Text(
                            "Top Rated",
                            style: AppTheme.textLabel(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Books grid (live search + client sort)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _booksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingLogo());
                    }

                    if (snapshot.hasError) {
                      debugPrint('Firestore Error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Failed to load books'),
                            ElevatedButton(
                              onPressed: _updateStream,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: NotFoundWidget(
                          title: "Not Items Found",
                          message: "",
                        ),
                      );
                    }

                    // 1) Filter by live query
                    final allDocs = snapshot.data!.docs;
                    final List<QueryDocumentSnapshot> filteredDocs = q.isEmpty
                        ? allDocs
                        : allDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _matchesQuery(data, q);
                          }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'No results for “$q”.',
                          style: const TextStyle(color: MyColors.primary),
                        ),
                      );
                    }

                    // 2) Precompute for robust sorting
                    final List<Map<String, dynamic>> computed = filteredDocs
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final double? rating = _ratingOf(data); // null ok
                          final int ratingCount = _intOf(
                            data['ratingCount'] ??
                                data['reviews'] ??
                                data['numRatings'],
                          );
                          final String title = _strOf(data['title']);
                          final double price = _numOf(data['price']).toDouble();
                          return {
                            'doc': doc,
                            'rating': rating,
                            'ratingCount': ratingCount,
                            'title': title,
                            'price': price,
                          };
                        })
                        .toList();

                    // 3) Sort in-memory
                    computed.sort((a, b) {
                      switch (_currentSortField) {
                        case 'price':
                          {
                            final cmp = (a['price'] as double).compareTo(
                              b['price'] as double,
                            );
                            return _isDescending ? -cmp : cmp;
                          }
                        case 'rating':
                          {
                            final ra = a['rating'] as double?;
                            final rb = b['rating'] as double?;
                            final aMissing = ra == null;
                            final bMissing = rb == null;

                            // Missing ratings always last
                            if (aMissing != bMissing) return aMissing ? 1 : -1;

                            int cmp = 0;
                            if (!aMissing && !bMissing) {
                              cmp = _isDescending
                                  ? rb!.compareTo(ra!)
                                  : ra!.compareTo(rb!);
                              if (cmp != 0) return cmp;

                              // tie-break by ratingCount
                              final ca = a['ratingCount'] as int;
                              final cb = b['ratingCount'] as int;
                              cmp = _isDescending
                                  ? cb.compareTo(ca)
                                  : ca.compareTo(cb);
                              if (cmp != 0) return cmp;
                            }

                            // final tie: title asc
                            return (a['title'] as String).compareTo(
                              b['title'] as String,
                            );
                          }
                        case 'title':
                        default:
                          {
                            final cmp = (a['title'] as String).compareTo(
                              b['title'] as String,
                            );
                            return _isDescending ? -cmp : cmp;
                          }
                      }
                    });

                    // 4) Grid
                    return GridView.builder(
                      itemCount: computed.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.95,
                          ),
                      itemBuilder: (context, index) {
                        final doc =
                            computed[index]['doc'] as QueryDocumentSnapshot;
                        final data = doc.data() as Map<String, dynamic>;
                        final String bookId = doc.id;

                        return GestureDetector(
                          key: ValueKey('item-$bookId'), // stable identity
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        BookDetailPage(bookId: bookId),
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
                          child: Hero(
                            tag: bookId,
                            child: Material(
                              color: Colors.transparent,
                              child: BookCard(
                                key: ValueKey('card-$bookId'),
                                bookId: bookId,
                                title: data['title'] ?? 'Untitled',
                                author: data['description'] ?? 'Unknown Author',
                                imagePath:
                                    data['cover_image_url'] ??
                                    'assets/images/placeholder.jpg',
                                category: data['category'] ?? 'Uncategorized',
                                price: (data['price'] ?? 0).toDouble(),
                                rating: (data['rating'] ?? 0).toDouble(),
                                stock: (data['quantity'] ?? 0),
                                discount: (data['discount'] ?? 0),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
