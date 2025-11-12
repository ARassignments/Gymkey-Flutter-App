import 'dart:io' show Platform;
import 'package:bookify/screens/admin/screens/manage_categories/manage_categories.dart';
import 'package:flutter/services.dart'; // SystemNavigator.pop()
import 'package:bookify/screens/admin/screens/manage_books/manage_books.dart';
import 'package:bookify/screens/admin/screens/manage_orders/manage_orders.dart';
import 'package:bookify/screens/admin/screens/manage_users/manage_users.dart';
import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/adminbottomnavbar.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

final List<Map<String, dynamic>> categories = [
  {'title': 'Manage Categories', 'icon': Icons.category},
  {'title': 'Manage Products', 'icon': Icons.book},
  {'title': 'Manage Users', 'icon': Icons.people},
  {'title': 'Manage Orders', 'icon': Icons.shopping_cart},
];

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final auth = FirebaseAuth.instance;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  // Double-back to exit (Android)
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

  void navigateToCategory(String title) {
    if (title == 'Manage Products') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageBooks()),
      );
    } else if (title == 'Manage Users') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageUsers()),
      );
    } else if (title == 'Manage Orders') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageOrders()),
      );
    } else if (title == 'Manage Categories') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ManageCategories()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFeeeeee),
        bottomNavigationBar: buildAdminCurvedNavBar(context, 0),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Icon(
                        Icons.search_rounded,
                        color: MyColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        auth.signOut().then((_) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignIn()),
                          );
                        });
                      },
                      child: Icon(
                        Icons.logout,
                        color: MyColors.primary,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showSearchBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 30),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Overview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MyColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    "Weekly Sales Data",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MyColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildBarChart(),
              ),
              const SizedBox(height: 30),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
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
                                  fontSize: 11,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Bar Chart Section =====
  Widget _buildBarChart() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: MyColors.primary,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const style = TextStyle(
                      fontSize: 10,
                      color: MyColors.primary,
                      fontWeight: FontWeight.w500,
                    );
                    switch (value.toInt()) {
                      case 0:
                        return const Text('Mon', style: style);
                      case 1:
                        return const Text('Tue', style: style);
                      case 2:
                        return const Text('Wed', style: style);
                      case 3:
                        return const Text('Thu', style: style);
                      case 4:
                        return const Text('Fri', style: style);
                      case 5:
                        return const Text('Sat', style: style);
                      case 6:
                        return const Text('Sun', style: style);
                      default:
                        return const Text('');
                    }
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barGroups: [
              makeGroupData(0, 5),
              makeGroupData(1, 9),
              makeGroupData(2, 6),
              makeGroupData(3, 10),
              makeGroupData(4, 8),
              makeGroupData(5, 7),
              makeGroupData(6, 4),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          color: MyColors.primary,
        ),
      ],
    );
  }
}
