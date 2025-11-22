import '/components/loading_screen.dart';
import '/components/not_found.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/utils/themes/themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/search_provider.dart';
import '/screens/admin/screens/manage_categories/add_category.dart';
import '/screens/admin/screens/manage_categories/edit_categories.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageCategories extends ConsumerStatefulWidget {
  const ManageCategories({super.key});

  @override
  ConsumerState<ManageCategories> createState() => _ManageCategoriesState();
}

class _ManageCategoriesState extends ConsumerState<ManageCategories>
    with AutomaticKeepAliveClientMixin {
  final auth = FirebaseAuth.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      body: SafeArea(
        child: Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingLogo());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: NotFoundWidget(
                    title: "No Categories Found",
                    message: "",
                  ),
                );
              }

              final filtered = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: NotFoundWidget(
                    title: "No Categories Found",
                    message: "",
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final doc = filtered[i];
                  final data = doc.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Shimmer(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.sliderHighlightBg(context),
                                  AppTheme.iconColorThree(context),
                                  AppTheme.sliderHighlightBg(context),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              direction: ShimmerDirection.ltr,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  Icon(
                                    HugeIconsSolid.delete01,
                                    color: AppColor.accent_50,
                                    size: 24,
                                  ),
                                  Text(
                                    "Swipe right to remove",
                                    style: AppTheme.textLink(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Icon(HugeIconsStroke.swipeRight01),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      secondaryBackground: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Shimmer(
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  const Icon(HugeIconsStroke.swipeLeft01),
                                  Text(
                                    "Swipe left to edit",
                                    style: AppTheme.textLink(context).copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Icon(
                                    HugeIconsSolid.edit01,
                                    color: AppColor.accent_50,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        }

                        if (direction == DismissDirection.startToEnd) {
                          await FirebaseFirestore.instance
                              .collection('categories')
                              .doc(doc.id)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Category deleted")),
                          );

                          return true;
                        }

                        return false;
                      },
                      child: Card(
                        color: AppTheme.customListBg(context),
                        margin: EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (i + 1).toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child:
                                    data['image_url'] != null &&
                                        data['image_url'].isNotEmpty
                                    ? Image.network(
                                        data['image_url'],
                                        width: 80,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 80,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      ),
                              ),
                            ],
                          ),
                          title: Text(
                            data['name'],
                            style: AppTheme.textLabel(context).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCategory()),
          );
        },
        backgroundColor: AppTheme.customListBg(context),
        child: Icon(HugeIconsStroke.add01, color: AppTheme.iconColor(context)),
      ),
    );
  }
}
