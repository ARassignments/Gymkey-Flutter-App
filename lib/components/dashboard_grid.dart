import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Orders',
        'value': '0',
        'color1': Colors.tealAccent.shade400,
        'color2': Colors.teal,
        'icon': HugeIconsStroke.shoppingBasket02,
      },
      {
        'title': 'Revenue',
        'value': 'Rs 0.00',
        'color1': Colors.orangeAccent,
        'color2': Colors.deepOrange,
        'icon': HugeIconsStroke.wallet02,
      },
      {
        'title': 'Credit Sale',
        'value': 'Rs 0.00',
        'color1': Colors.lightBlueAccent,
        'color2': Colors.blue,
        'icon': HugeIconsStroke.moneySend01,
      },
      {
        'title': 'Debit Sale',
        'value': 'Rs 0.00',
        'color1': Colors.purpleAccent,
        'color2': Colors.deepPurple,
        'icon': HugeIconsStroke.moneyReceive01,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600
            ? 2 // small screen → 2 cards per row
            : 4; // large screen → 4 cards per row

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final item = stats[index];
            return _buildStatCard(
              context,
              item['title'] as String,
              item['value'] as String,
              item['color1'] as Color,
              item['color2'] as Color,
              item['icon'] as IconData,
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color1,
    Color color2,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTheme.textTitle(
                    context,
                  ).copyWith(color: Colors.white, fontSize: 18),
                ),
                Text(
                  value,
                  style: AppTheme.textLabel(context).copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: AppFontFamily.poppinsMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
