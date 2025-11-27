import '/screens/admin/screens/manage_users/manage_users.dart';
import '/utils/themes/themes.dart';
import '/utils/constants/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeAdminScreen extends StatefulWidget {
  final Function(int) onMenuSelect;
  const HomeAdminScreen({super.key, required this.onMenuSelect});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen>
    with AutomaticKeepAliveClientMixin {
  bool _hover = false;
  @override
  void initState() {
    super.initState();
    // fetchCategories();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Overview",
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _buildBarChart(),
              const SizedBox(height: 10),
              Text(
                "Weekly Sales Data",
                textAlign: TextAlign.center,
                style: AppTheme.textSearchInfo(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onMenuSelect(1),
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
                                "Manage\nCategories",
                                style: AppTheme.textLink(context).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -5,
                            bottom: -5,
                            child: Image.asset(
                              "assets/images/items.png",
                              height: 110,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onMenuSelect(3),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hover = true),
                        onExit: (_) => setState(() => _hover = false),
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
                                  "Manage\nOrders",
                                  style: AppTheme.textLink(context).copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              right: _hover ? -20 : -25,
                              bottom: _hover ? -20 : -35,
                              child: AnimatedScale(
                                scale: _hover
                                    ? 1.12
                                    : 1.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: Image.asset(
                                  "assets/images/orders.png",
                                  height: 170,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onMenuSelect(2),
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
                                "Manage\nProducts",
                                style: AppTheme.textLink(context).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -30,
                            bottom: -30,
                            child: Image.asset(
                              "assets/images/products.png",
                              height: 170,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    ManageUsers(),
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
                                "Manage\nUsers",
                                style: AppTheme.textLink(context).copyWith(
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
                ],
              ),

              SizedBox(height: 20),

              // Expanded(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16.0),
              //     child: GridView.builder(
              //       shrinkWrap: true,
              //       physics: const NeverScrollableScrollPhysics(),
              //       itemCount: categories.length,
              //       gridDelegate:
              //           const SliverGridDelegateWithFixedCrossAxisCount(
              //             crossAxisCount: 2,
              //             crossAxisSpacing: 16,
              //             mainAxisSpacing: 16,
              //             childAspectRatio: 3 / 2,
              //           ),
              //       itemBuilder: (context, index) {
              //         final category = categories[index];
              //         return InkWell(
              //           onTap: () => navigateToCategory(category['title']),
              //           child: Container(
              //             decoration: BoxDecoration(
              //               color: Colors.white,
              //               borderRadius: BorderRadius.circular(16),
              //               border: Border.all(color: MyColors.primary),
              //               boxShadow: const [
              //                 BoxShadow(
              //                   color: MyColors.primary,
              //                   blurRadius: 4,
              //                   offset: Offset(0, 2),
              //                 ),
              //               ],
              //             ),
              //             padding: const EdgeInsets.all(16),
              //             child: Column(
              //               mainAxisAlignment: MainAxisAlignment.center,
              //               children: [
              //                 Icon(
              //                   category['icon'],
              //                   size: 30,
              //                   color: MyColors.primary,
              //                 ),
              //                 const SizedBox(height: 10),
              //                 Text(
              //                   category['title'],
              //                   style: const TextStyle(
              //                     fontSize: 11,
              //                     fontWeight: FontWeight.w600,
              //                     color: Colors.black87,
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: AppTheme.customListBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: 20,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: BarChart(
          BarChartData(
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    var style = AppTheme.textLabel(
                      context,
                    ).copyWith(fontSize: 12, color: MyColors.primary);
                    switch (value.toInt()) {
                      case 0:
                        return Text('Mon', style: style);
                      case 1:
                        return Text('Tue', style: style);
                      case 2:
                        return Text('Wed', style: style);
                      case 3:
                        return Text('Thu', style: style);
                      case 4:
                        return Text('Fri', style: style);
                      case 5:
                        return Text('Sat', style: style);
                      case 6:
                        return Text('Sun', style: style);
                      default:
                        return Text('');
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
          width: 28,
          borderRadius: BorderRadius.circular(12),
          color: MyColors.primary,
        ),
      ],
    );
  }
}
