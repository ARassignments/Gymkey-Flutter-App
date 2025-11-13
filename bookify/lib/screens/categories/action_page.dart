import '/screens/book_detail_page.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/app_navbar.dart';
import '/utils/themes/custom_themes/bookcard.dart';
import '/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActionPage extends StatefulWidget {
  const ActionPage({super.key});

  @override
  State<ActionPage> createState() => _ActionPageState();
}

class _ActionPageState extends State<ActionPage> {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;

  // client-side sort state
  String _currentSortField = 'title'; // 'title' | 'price' | 'rating'
  bool _isDescending = false;

  late Stream<QuerySnapshot> _booksStream;

  // ✅ Poetry/History pattern
  String _selectedCategory = 'Action';
  final List<String> categories = [
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
    _updateStream(); // load for initial selected
    _reorderCategories(); // selected ko list ke start par lao
    searchController.addListener(_onSearchChanged); // live search
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {}); // live re-render while typing

  // ✅ selected ko index 0 par le aao
  void _reorderCategories() {
    setState(() {
      categories.remove(_selectedCategory);
      categories.insert(0, _selectedCategory);
    });
  }

  // ✅ Firestore stream selected category ke hisaab se
  void _updateStream() {
    _booksStream = FirebaseFirestore.instance
        .collection('books')
        .where('genre', isEqualTo: _selectedCategory)
        .snapshots();
  }

  // ✅ Pehle state + reorder + stream; phir navigate (Poetry/History jaisa)
  void navigateToCategory(String title) {
    setState(() {
      _selectedCategory = title;
      _reorderCategories();
      _updateStream();
    });

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

  // change sort mode (in-memory)
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
      if (!termOK(t)) return false; // AND-style matching
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

  /// rating extractor (flexible keys / formats)
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
        final s = x.trim();
        final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(s);
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
    final q = searchController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ✅ Categories List (selected pehle + active highlight)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => navigateToCategory(category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? MyColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: MyColors.primary),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : MyColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Filter + Title Row — Poetry/History pattern
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    q.isEmpty ? _selectedCategory : 'Results for “$q”',
                    style: MyTextTheme.lightTextTheme.headlineMedium,
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: const PopupMenuThemeData(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        textStyle: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.filter_list,
                        color: MyColors.primary,
                      ),
                      onSelected: sortBooks, // instant client-side sort
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "Price: Low to High",
                          child: Text(
                            "Price: Low to High",
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: "Price: High to Low",
                          child: Text(
                            "Price: High to Low",
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: "Top Rated",
                          child: Text(
                            "Top Rated",
                            style: TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Books grid (live search + client sort + stable keys)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _booksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                      return Center(
                        child: Text(
                          'No $_selectedCategory books available.',
                          style: TextStyle(color: MyColors.primary),
                        ),
                      );
                    }

                    // 1) Live search filter (client-side, dynamic)
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

                    // 2) Precompute data for robust sorting (client-side)
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

                    // 3) Sort using precomputed fields
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

                            if (aMissing != bMissing) return aMissing ? 1 : -1;

                            int cmp = 0;
                            if (!aMissing && !bMissing) {
                              cmp = _isDescending
                                  ? rb!.compareTo(ra!)
                                  : ra!.compareTo(rb!);
                              if (cmp != 0) return cmp;

                              final ca = a['ratingCount'] as int;
                              final cb = b['ratingCount'] as int;
                              cmp = _isDescending
                                  ? cb.compareTo(ca)
                                  : ca.compareTo(cb);
                              if (cmp != 0) return cmp;
                            }

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
                            childAspectRatio: 0.63,
                          ),
                      itemBuilder: (context, index) {
                        final doc =
                            computed[index]['doc'] as QueryDocumentSnapshot;
                        final data = doc.data() as Map<String, dynamic>;
                        final String bookId = doc.id;

                        final double? r = computed[index]['rating'] as double?;
                        final ratingForCard =
                            (r ?? 0.0); // show 0.0 when missing

                        return GestureDetector(
                          key: ValueKey(
                            'item-$bookId',
                          ), // stable identity per item
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
                                title: data['title'],
                                author: data['author'],
                                imagePath: data['cover_image_url'],
                                category: data['genre'],
                                price: _numOf(data['price']).toDouble(),
                                rating: ratingForCard,
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
