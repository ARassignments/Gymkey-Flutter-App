import 'package:bookify/screens/admin/screens/dashboard.dart';
import 'package:bookify/screens/admin/screens/manage_books/add_books.dart';
import 'package:bookify/screens/admin/screens/manage_books/edit_books.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/adminbottomnavbar.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBooks extends StatefulWidget {
  const ManageBooks({super.key});

  @override
  State<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends State<ManageBooks> {
  final auth = FirebaseAuth.instance;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.addListener(_searchBooks);
    fetchCategories();
  }

  @override
  void dispose() {
    _searchController.removeListener(_searchBooks);
    _searchController.dispose();
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
    return WillPopScope(
      onWillPop: () async {
        navigateWithFade(context, const Dashboard());
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFeeeeee),
        bottomNavigationBar: buildAdminCurvedNavBar(context, 1),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          "assets/images/b.jpg",
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi, Admin",
                            style: MyTextTheme.lightTextTheme.titleLarge,
                          ),
                          const Text(
                            "Administrator",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () =>
                            setState(() => _showSearchBar = !_showSearchBar),
                        child: const Icon(
                          Icons.search_rounded,
                          color: MyColors.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          auth.signOut().then((value) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignIn(),
                              ),
                            );
                          });
                        },
                        child: const Icon(
                          Icons.logout,
                          color: MyColors.primary,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search bar
                if (_showSearchBar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Search...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Manage Books header card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MyColors.primary),
                      boxShadow: const [
                        BoxShadow(
                          color: MyColors.primary,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              "Manage Products",
                              style: TextStyle(
                                color: MyColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddBooks(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.add_circle_rounded,
                                size: 40,
                                color: MyColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Categories chips
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No categories found');
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
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => selectedCategory = cat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? MyColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: MyColors.primary),
                                  ),
                                  child: Text(
                                    cat,
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
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Books list
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StreamBuilder<QuerySnapshot>(
                    // Saare books laao; filtering neeche client-side hogi
                    stream: FirebaseFirestore.instance
                        .collection('books')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No products found.',style: TextStyle(color:Color(0xFF0059a7) ),));
                      }

                      final q = _searchController.text.trim().toLowerCase();
                      final docs = snapshot.data!.docs;

                      // 1) Category filter
                      final byCategory = docs.where((doc) {
                        final data =
                            (doc.data() as Map<String, dynamic>?) ?? {};
                        return _matchesCategory(data);
                      }).toList();

                      // 2) Search filter
                      final filteredBooks = byCategory.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _matchesSearch(data, q);
                      }).toList();

                      if (filteredBooks.isEmpty) {
                        return const Center(child: Text('No products found.',style: TextStyle(color:Color(0xFF0059a7) ),));
                      }

                      return Column(
                        children: filteredBooks.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                            ),
                            secondaryBackground: Container(
                              color: MyColors.primary,
                              alignment: Alignment.centerRight,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 20),
                                child: Icon(Icons.edit, color: Colors.white),
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditBooks(
                                      bookId: doc.id,
                                      bookData: data,
                                    ),
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
                                    content: Text('Product deleted successfully!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return true;
                              }
                              return false;
                            },
                            child: Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 12.0,
                              ),
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    (data['cover_image_url'] != null &&
                                            data['cover_image_url']
                                                .toString()
                                                .isNotEmpty)
                                        ? Image.network(
                                            data['cover_image_url'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (data['title'] ?? '').toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: MyColors.primary,
                                              fontSize: 16,
                                            ),
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
                                            style: const TextStyle(
                                              color: MyColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '\$${(data['price'] ?? '').toString()}',
                                            style: const TextStyle(
                                              color: Colors.deepOrange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
