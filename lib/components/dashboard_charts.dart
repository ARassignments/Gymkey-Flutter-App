import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '/theme/theme.dart';

class DashboardCharts extends StatefulWidget {
  const DashboardCharts({super.key});

  @override
  State<DashboardCharts> createState() => _DashboardChartsState();
}

class _DashboardChartsState extends State<DashboardCharts>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _showAvg = false;
  bool _loading = true;
  late AnimationController _fadeController;

  final List<String> _tabs = ["Sales", "Users", "Expenses", "Revenue", "Share"];

  // Chart Data Model
  final Map<String, dynamic> dynamicChartData = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate network/API

    dynamicChartData["Sales"] = [
      const FlSpot(0, 1.3),
      const FlSpot(1, 2.1),
      const FlSpot(2, 2.5),
      const FlSpot(3, 3.0),
      const FlSpot(4, 3.4),
      const FlSpot(5, 4.2),
    ];

    dynamicChartData["Users"] = [
      const FlSpot(0, 1.0),
      const FlSpot(1, 1.5),
      const FlSpot(2, 1.8),
      const FlSpot(3, 1.5),
      const FlSpot(4, 3.2),
      const FlSpot(5, 3.9),
    ];

    dynamicChartData["Expenses"] = [
      const FlSpot(0, 2.2),
      const FlSpot(1, 1.9),
      const FlSpot(2, 2.5),
      const FlSpot(3, 2.0),
      const FlSpot(4, 2.8),
      const FlSpot(5, 3.1),
    ];

    // Monthly Revenue Data (for Bar Chart)
    dynamicChartData["Revenue"] = [
      1.5,
      2.0,
      2.8,
      3.2,
      4.0,
      4.5,
      4.3,
      3.8,
      3.5,
      4.0,
      4.3,
      5.0,
    ];

    // Category Share Data (for Pie Chart)
    dynamicChartData["Share"] = {
      "Electronics": 40,
      "Fashion": 25,
      "Groceries": 15,
      "Others": 20,
    };

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.customListBg(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTabSwitcher(context),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _loading
                ? _buildShimmerLoader(context)
                : FadeTransition(
                    opacity: _fadeController,
                    child: SizedBox(height: 260, child: _buildSelectedChart()),
                  ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _selectedTab < 3
                ? TextButton(
                    onPressed: () {
                      setState(() => _showAvg = !_showAvg);
                    },
                    child: Text(
                      _showAvg ? "Show Actual" : "Show Average",
                      style: AppTheme.textLabel(context).copyWith(
                        fontSize: 10,
                        fontFamily: AppFontFamily.poppinsMedium,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 🟦 Tabs (Sales, Users, Expenses, Revenue, Share)
  Widget _buildTabSwitcher(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          bool isActive = _selectedTab == index;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _selectedTab = index;
                _fadeController.forward(from: 0);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.cardDarkBg(context).withOpacity(0.7)
                    : AppTheme.customListBg(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _tabs[index],
                style: AppTheme.textLabel(context).copyWith(
                  fontFamily: isActive
                      ? AppFontFamily.poppinsMedium
                      : AppFontFamily.poppinsLight,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 📊 Select Chart by Tab
  Widget _buildSelectedChart() {
    switch (_tabs[_selectedTab]) {
      case "Sales":
        return LineChart(
          _buildLineData("Sales", [
            const Color(0xff23b6e6),
            const Color(0xff02d39a),
          ]),
        );
      case "Users":
        return LineChart(
          _buildLineData("Users", [
            const Color(0xff845ef7),
            const Color(0xff9775fa),
          ]),
        );
      case "Expenses":
        return LineChart(
          _buildLineData("Expenses", [
            const Color(0xfffa5252),
            const Color(0xffff8787),
          ]),
        );
      case "Revenue":
        return BarChart(_buildBarChartData());
      case "Share":
        return PieChart(_buildPieChartData());
      default:
        return const SizedBox.shrink();
    }
  }

  LineChartData _buildLineData(String key, List<Color> colors) {
    if (_showAvg) return _avgLineData(key, colors.first);

    final spots = dynamicChartData[key] ?? <FlSpot>[];
    final yValues = spots.map((e) => e.y).toList();
    final minY = yValues.isEmpty ? 0 : yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.isEmpty ? 10 : yValues.reduce((a, b) => a > b ? a : b);

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: false,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: AppTheme.dividerBg(context), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 0,
            getTitlesWidget: (value, _) {
              return Padding(padding: const EdgeInsets.only(right: 8.0));
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

        // ✅ LEFT AXIS TITLES (Y-axis)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 0,
            getTitlesWidget: (value, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                // child: Text(
                //   value.toDouble().toStringAsFixed(1),
                //   style: AppTheme.textSearchInfoLabeled(
                //     context,
                //   ).copyWith(fontSize: 11),
                // ),
              );
            },
          ),
        ),

        // ✅ BOTTOM AXIS TITLES (X-axis)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) {
              const months = [
                "Jan",
                "Feb",
                "Mar",
                "Apr",
                "May",
                "Jun",
                "Jul",
                "Aug",
                "Sep",
                "Oct",
                "Nov",
                "Dec",
              ];
              if (value.toInt() < months.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    months[value.toInt()],
                    style: AppTheme.textSearchInfoLabeled(
                      context,
                    ).copyWith(fontSize: 10),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),

      borderData: FlBorderData(show: false),

      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          gradient: LinearGradient(colors: colors),
          spots: List<FlSpot>.from(spots),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: colors.map((c) => c.withOpacity(0.25)).toList(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: const FlDotData(show: true),
          barWidth: 3,
          isStrokeCapRound: true,
        ),
      ],

      // ✅ SMOOTH ANIMATION + TOOLTIP
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppTheme.customListBg(context),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                "${spot.y.toStringAsFixed(1)}",
                AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(color: colors.first),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// 💰 Bar Chart (Monthly Revenue)
  BarChartData _buildBarChartData() {
    final data = dynamicChartData["Revenue"] as List<double>? ?? [];
    return BarChartData(
      minY: data.isEmpty
          ? 0
          : data.reduce((a, b) => a < b ? a : b), // add some padding
      maxY: data.isEmpty
          ? 10
          : data.reduce((a, b) => a > b ? a : b), // add some padding
      barGroups: data
          .asMap()
          .entries
          .map(
            (e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 14,
                  gradient: const LinearGradient(
                    colors: [Color(0xff4facfe), Color(0xff00f2fe)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            ),
          )
          .toList(),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 20,
            getTitlesWidget: (value, _) {
              return Text(
                value.toDouble().toStringAsFixed(1),
                style: AppTheme.textSearchInfoLabeled(
                  context,
                ).copyWith(fontSize: 11),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              const months = [
                "J",
                "F",
                "M",
                "A",
                "M",
                "J",
                "J",
                "A",
                "S",
                "O",
                "N",
                "D",
              ];
              if (v.toInt() < months.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    months[v.toInt()],
                    style: AppTheme.textSearchInfoLabeled(context).copyWith(
                      fontSize: 11,
                      fontFamily: AppFontFamily.poppinsMedium,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipColor: (_) => AppTheme.customListBg(context),

          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            // You can use your own custom colors
            final colors = [Colors.blue, Colors.green, Colors.purple];

            return BarTooltipItem(
              '${rod.toY.toStringAsFixed(1)}', // ✅ Display Y-value of the bar
              AppTheme.textSearchInfoLabeled(context).copyWith(
                color: colors.first, // or any color logic you want
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🥧 Pie Chart (Category Share)
  PieChartData _buildPieChartData() {
    // Convert any Map<String, int> or Map<String, num> into Map<String, double>
    final rawData = dynamicChartData["Share"];
    final Map<String, double> data = {};

    if (rawData is Map) {
      rawData.forEach((key, value) {
        data[key.toString()] = (value is num) ? value.toDouble() : 0.0;
      });
    }

    double total = data.values.fold(0, (a, b) => a + b);

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 32,
      sections: data.entries.map((e) {
        final percent = (e.value / total) * 100;
        return PieChartSectionData(
          color: _getCategoryColor(e.key),
          value: e.value,
          title: "${percent.toStringAsFixed(0)}%",
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(String key) {
    switch (key) {
      case "Electronics":
        return Colors.blueAccent;
      case "Fashion":
        return Colors.pinkAccent;
      case "Groceries":
        return Colors.green;
      default:
        return Colors.orangeAccent;
    }
  }

  /// ⚪ Average Line
  LineChartData _avgLineData(String key, Color color) {
    final spots = dynamicChartData[key] ?? <FlSpot>[];
    return LineChartData(
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      // gridData: FlGridData(
      //   show: false,
      //   drawVerticalLine: false,
      //   getDrawingHorizontalLine: (value) =>
      //       FlLine(color: AppTheme.dividerBg(context), strokeWidth: 1),
      // ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          spots: List<FlSpot>.from(spots),
          belowBarData: BarAreaData(show: false),
          dotData: const FlDotData(show: true),
          barWidth: 3,
          isStrokeCapRound: true,
        ),
      ],
      borderData: FlBorderData(show: false),

      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppTheme.customListBg(context),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                "${spot.y.toStringAsFixed(1)}",
                AppTheme.textSearchInfoLabeled(context).copyWith(color: color),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// ✨ Shimmer Loader
  Widget _buildShimmerLoader(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            strokeWidth: 4,
            color: AppTheme.inputProgress(context),
          ),
          const SizedBox(height: 16),
          Text("Loading chart data...", style: AppTheme.textLabel(context)),
        ],
      ),
    );
  }
}
