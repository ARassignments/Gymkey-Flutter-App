import '/screens/all_books.dart';
import '/screens/auth/users/sign_in.dart';
import '/screens/categories/action_page.dart';
import '/screens/categories/fantasy_page.dart';
import '/screens/categories/history_page.dart';
import '/screens/categories/novels_page.dart';
import '/screens/categories/poetry_page.dart';
import '/screens/categories/romance_page.dart';
import '/screens/categories/science_page.dart';
import '/screens/categories/self_love_page.dart';
import '/screens/home.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/app_navbar.dart';
import '/utils/themes/custom_themes/bottomnavbar.dart';
import '/utils/themes/custom_themes/text_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;

  final List<Map<String, dynamic>> categories = [
    {"title": "Novels", "icon": Icons.book},
    {"title": "Self Love", "icon": Icons.favorite},
    {"title": "Science", "icon": Icons.science},
    {"title": "Romance", "icon": Icons.favorite_border},
    {"title": "History", "icon": Icons.history_edu},
    {"title": "Fantasy", "icon": Icons.auto_awesome},
    {"title": "Poetry", "icon": Icons.create},
    {"title": "Action", "icon": Icons.flash_on},
  ];

  void navigateToCategory(String title) {
    final Map<String, Widget> routes = {
      "Novels": const NovelsPage(),
      "Self Love": const SelfLovePage(),
      "Science": const SciencePage(),
      "Romance": const RomancePage(),
      "History": const HistoryPage(),
      "Fantasy": const FantasyPage(),
      "Poetry": const PoetryPage(),
      "Action": const ActionPage(),
    };

    if (routes.containsKey(title)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => routes[title]!),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unknown category: $title")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        navigateWithFade(context, const HomeScreen());
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFeeeeee),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categories title and See All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Categories",
                            style: MyTextTheme.lightTextTheme.headlineSmall,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllBooksPage(),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "See All Books",
                                  style: TextStyle(
                                    color: MyColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Container(
                                  width: 97,
                                  height: 1.0,
                                  color: MyColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 3 / 2,
                            ),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return GestureDetector(
                            onTap: () => navigateToCategory(category['title']),
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
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    category['icon'],
                                    size: 30,
                                    color: MyColors.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    category['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
