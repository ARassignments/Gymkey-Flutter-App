import '/components/appsnackbar.dart';
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
  List<QueryDocumentSnapshot> allCategories = [];
  List<QueryDocumentSnapshot> filteredCategories = [];
  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // fetchCategories();
    FirebaseFirestore.instance
      .collection('categories')
      .orderBy('created_at', descending: true)
      .snapshots()
      .listen((snapshot) {
        allCategories = snapshot.docs;
        applySearchFilter();
        setState(() => isLoading = false);
      });
  }

  Future<void> fetchCategories() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .orderBy('created_at', descending: true)
        .get();

    allCategories = snapshot.docs;
    applySearchFilter();

    setState(() => isLoading = false);
  }

  void applySearchFilter() {
    final query = ref.read(searchQueryProvider).toLowerCase();

    filteredCategories = allCategories.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? "";
      return name.contains(query);
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(searchQueryProvider, (prev, next) => applySearchFilter());
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchCategories,
          child: isLoading
              ? const Center(child: LoadingLogo())
              : filteredCategories.isEmpty
              ? Column(
                  children: [
                    _searchInfo(context),
                    Expanded(
                      child: Center(
                        child: NotFoundWidget(
                          title: "No Categories Found",
                          message: "",
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _searchInfo(context),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, i) {
                          final doc = filteredCategories[i];
                          final data = doc.data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Dismissible(
                              key: Key(doc.id),
                              direction: DismissDirection.horizontal,

                              // swipe actions
                              background: _deleteBackground(context),
                              secondaryBackground: _editBackground(context),

                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  // Edit
                                  showModalBottomSheet(
                                    context: context,
                                    isDismissible: false,
                                    enableDrag: false,
                                    showDragHandle: true,
                                    isScrollControlled: true,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(30),
                                      ),
                                    ),
                                    builder: (context) =>
                                        EditCategoryBottomSheet(
                                          categoryId: doc.id,
                                          categoryData: data,
                                        ),
                                  );

                                  return false;
                                }

                                if (direction == DismissDirection.startToEnd) {
                                  final bool? confirmDelete =
                                      await showModalBottomSheet<bool>(
                                        context: context,
                                        isDismissible: false,
                                        enableDrag: false,
                                        showDragHandle: true,
                                        isScrollControlled: true,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(30),
                                          ),
                                        ),
                                        builder: (context) {
                                          return _confirmDeleteSheet(
                                            context,
                                            data['name'],
                                          );
                                        },
                                      );

                                  if (confirmDelete == true) {
                                    await FirebaseFirestore.instance
                                        .collection('categories')
                                        .doc(doc.id)
                                        .delete();

                                    allCategories.remove(doc);
                                    applySearchFilter();
                                    AppSnackBar.show(
                                      context,
                                      message: "Category deleted successfully!",
                                      type: AppSnackBarType.success,
                                    );
                                    return true;
                                  }

                                  return false;
                                }

                                return false;
                              },

                              child: _categoryTile(context, data, i),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        isExtended: true,
        foregroundColor: AppTheme.iconColor(context),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isDismissible: false,
            enableDrag: false,
            showDragHandle: true,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (context) => const AddCategoryBottomSheet(),
          );
          // fetchCategories();
        },
        backgroundColor: AppTheme.customListBg(context),
        label: Row(
          spacing: 8,
          children: [
            Icon(
              HugeIconsStroke.add01,
              color: AppTheme.iconColor(context),
              size: 20,
            ),
            Text("Add Category", style: AppTheme.textLabel(context)),
          ],
        ),
      ),
    );
  }

  Widget _searchInfo(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    if (searchQuery.isEmpty) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              style: AppTheme.textSearchInfo(context),
              children: [
                const TextSpan(text: 'Result for "'),
                TextSpan(
                  text: searchQuery,
                  style: AppTheme.textSearchInfoLabeled(context),
                ),
                const TextSpan(text: '"'),
              ],
            ),
          ),
          Text(
            "${filteredCategories.length} found",
            style: AppTheme.textSearchInfoLabeled(context),
          ),
        ],
      ),
    );
  }

  Widget _deleteBackground(BuildContext context) => Container(
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
                style: AppTheme.textLink(
                  context,
                ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const Icon(HugeIconsStroke.swipeRight01),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _editBackground(BuildContext context) => Container(
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
                style: AppTheme.textLink(
                  context,
                ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              Icon(HugeIconsSolid.edit01, color: AppColor.accent_50, size: 24),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _confirmDeleteSheet(BuildContext context, String name) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        spacing: 16,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Confirm Delete",
            textAlign: TextAlign.center,
            style: AppTheme.textLabel(
              context,
            ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Divider(color: AppTheme.dividerBg(context)),
          Text(
            "Are you sure you want to delete '$name' category?",
            textAlign: TextAlign.center,
            style: AppTheme.textLabel(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.accent_50,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Remove",
              style: TextStyle(color: Colors.white),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(BuildContext context, Map data, int i) {
    return Card(
      elevation: 0,
      color: AppTheme.customListBg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (i + 1).toString().padLeft(2, '0'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child:
                  data['image_url'] != null &&
                      data['image_url'].toString().isNotEmpty
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
          data['name'] ?? "",
          style: AppTheme.textLabel(
            context,
          ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}