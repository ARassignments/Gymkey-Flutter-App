import '/screens/home.dart';
import '/components/appsnackbar.dart';
import '/components/loading_screen.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;

  @override
  bool get wantKeepAlive => true;

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String imageUrl,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                CategoryDetailPage(category: title),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : const DecorationImage(
                  image: AssetImage('assets/images/placeholder.jpg'),
                  fit: BoxFit.cover,
                ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(HugeIconsSolid.catalogue, size: 30, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTheme.textTitle(
                context,
              ).copyWith(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingMoreCard(BuildContext context) {
    return InkWell(
      onTap: () {
        AppSnackBar.show(
          context,
          message: "More categories coming soon!",
          type: AppSnackBarType.info,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.customListBg(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Shimmer(
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 40,
                  color: AppTheme.iconColor(context),
                ),
                const SizedBox(height: 10),
                Text(
                  "Coming More",
                  style: AppTheme.textTitle(context).copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: AppTheme.textLabel(
                    context,
                  ).copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🔥 STREAM BUILDER FOR DYNAMIC CATEGORIES
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("categories")
                  .orderBy("name")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: LoadingLogo());
                }

                final categories = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      categories.length + 1, // 👉 Add one extra for Coming More
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3 / 2,
                  ),
                  itemBuilder: (context, index) {
                    // 👉 If last index → return Coming More Card
                    if (index == categories.length) {
                      return _buildComingMoreCard(context);
                    }

                    // 👉 Category Item
                    final cat = categories[index];
                    final title = cat['name'];

                    // Safe Firestore data extraction
                    final data = cat.data() as Map<String, dynamic>;
                    final imageUrl = data['image_url'] ?? "";

                    return _buildCategoryCard(context, title, imageUrl);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
