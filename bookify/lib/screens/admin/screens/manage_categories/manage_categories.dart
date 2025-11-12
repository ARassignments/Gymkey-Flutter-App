import 'package:bookify/screens/admin/screens/dashboard.dart';
import 'package:bookify/screens/admin/screens/manage_categories/add_category.dart';
import 'package:bookify/screens/admin/screens/manage_categories/edit_categories.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/adminbottomnavbar.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCategories extends StatefulWidget {
  const ManageCategories({super.key});

  @override
  State<ManageCategories> createState() => _ManageCategoriesState();
}

class _ManageCategoriesState extends State<ManageCategories> {
  final auth = FirebaseAuth.instance;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return true;
    final name = (data['name'] ?? '').toString().toLowerCase();
    return name.contains(query.toLowerCase());
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
        bottomNavigationBar: buildAdminCurvedNavBar(context, 2),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
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
                          Text("Hi, Admin",
                              style: MyTextTheme.lightTextTheme.titleLarge),
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
                        child: const Icon(Icons.search_rounded,
                            color: MyColors.primary, size: 30),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          auth.signOut().then((value) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignIn()),
                            );
                          });
                        },
                        child: const Icon(Icons.logout,
                            color: MyColors.primary, size: 30),
                      ),
                    ],
                  ),
                ),

                if (_showSearchBar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search categories...",
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              "Manage Categories",
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
                                    builder: (context) => const AddCategory(),
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

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('created_at', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No categories found"));
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _matchesSearch(data, query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(child: Text("No results found"));
                      }

                      return Column(
                        children: filtered.map((doc) {
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
                                    builder: (context) => EditCategory(
                                      categoryId: doc.id,
                                      categoryData: data,
                                    ),
                                  ),
                                );
                                return false;
                              } else if (direction ==
                                  DismissDirection.startToEnd) {
                                await FirebaseFirestore.instance
                                    .collection('categories')
                                    .doc(doc.id)
                                    .delete();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Category deleted successfully!'),
                                  ),
                                );
                                return true;
                              }
                              return false;
                            },
                            child: Card(
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              child: ListTile(
                                leading: Icon(Icons.list),
                                title: Text(
                                  (data['name'] ?? '').toString(),
                                  style: const TextStyle(
                                    color: MyColors.primary,
                                    fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
