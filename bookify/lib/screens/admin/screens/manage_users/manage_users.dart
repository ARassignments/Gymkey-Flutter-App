import '/components/appsnackbar.dart';
import '/providers/search_provider.dart';
import '/utils/themes/themes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsers extends ConsumerStatefulWidget {
  const ManageUsers({super.key});

  @override
  ConsumerState<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends ConsumerState<ManageUsers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  void fetchUsers() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'User')
        .get();
    setState(() {
      _users = querySnapshot.docs;
      _filteredUsers = _users;
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final data = user.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void toggleUserStatus(String uid, bool status) async {
    await _firestore.collection('users').doc(uid).update({'enabled': status});
    AppSnackBar.show(
      context,
      message: status
          ? "Account enable successfully!"
          : "Account disable successfully!",
      type: status?AppSnackBarType.success:AppSnackBarType.warning,
    );
    fetchUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "Manage Users",
          style: AppTheme.textTitle(context).copyWith(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (_showSearchBar) {
                  Future.delayed(Duration(milliseconds: 50), () {
                    _searchFocusNode.requestFocus();
                  });
                } else {
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = "";
                }
              });
            },
            icon: Icon(
              _showSearchBar
                  ? HugeIconsStroke.cancel02
                  : HugeIconsSolid.search01,
              color: AppTheme.iconColorThree(context),
              size: 24,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showSearchBar) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextFormField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: "Search",
                      hintText: "Search Here...",
                      prefixIcon: Icon(HugeIconsSolid.search01),
                      counter: const SizedBox.shrink(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(HugeIconsStroke.cancel02),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state =
                                    "";
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                        return 'Must contain only letters';
                      }
                      return null;
                    },
                    maxLength: 20,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final data = user.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'No Name';
                    final email = data['email'] ?? 'No Email';
                    final profileImage =
                        data['profile_image_url'] ??
                        ''; // Changed from imagePath
                    final enabled = data['enabled'] ?? true;

                    return Card(
                      color: AppTheme.customListBg(context),
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Profile image with better error handling
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.sliderHighlightBg(
                                context,
                              ),
                              child: profileImage.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profileImage,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  HugeIconsSolid.user03,
                                                  size: 30,
                                                ),
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: CircularProgressIndicator(
                                                  strokeCap: StrokeCap.round,
                                                  strokeWidth: 4,
                                                  color:
                                                      AppTheme.iconColorThree(
                                                        context,
                                                      ),
                                                ),
                                              );
                                            },
                                      ),
                                    )
                                  : const Icon(HugeIconsSolid.user03, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: AppTheme.textTitle(context),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: AppTheme.textSearchInfoLabeled(
                                      context,
                                    ).copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: enabled,
                              onChanged: (val) =>
                                  toggleUserStatus(user.id, val),
                              activeColor: MyColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
