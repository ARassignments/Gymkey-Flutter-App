import '/providers/search_provider.dart';
import '/screens/admin/screens/home_admin.dart';
import '/screens/admin/screens/manage_categories/manage_categories.dart';
import '/components/dialog_logout.dart';
import '/components/loading_screen.dart';
import '/components/menu_drawer.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/screens/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/user_provider.dart';
import '/screens/admin/screens/manage_books/manage_books.dart';
import '/screens/admin/screens/manage_orders/manage_orders.dart';
import '/screens/auth/users/sign_in.dart';
import '/utils/themes/custom_themes/adminbottomnavbar.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _showSearchBar = false;
  String name = '';
  String profileImage = '';
  bool isLoading = true;
  int _currentIndex = 0;
  final forAdmin = true;
  final ZoomDrawerController _drawerController = ZoomDrawerController();
  List<String> menus = [
    "Dashboard",
    "Categories",
    "Products",
    "Orders",
    "Accounts",
  ];
  late final List<Widget> pages;
  final ManageCategories manageCategoriesScreen = const ManageCategories();
  final ManageBooks manageProductsScreen = const ManageBooks();
  final ManageOrders manageOrdersScreen = const ManageOrders();
  final ProfileScreen profileScreen = const ProfileScreen(forAdmin: true);

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      ref.read(searchQueryProvider.notifier).state = query;
    });
    pages = [
      HomeAdminScreen(
        onMenuSelect: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      manageCategoriesScreen,
      manageProductsScreen,
      manageOrdersScreen,
      profileScreen,
    ];
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    // _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // final query = _searchController.text.trim().toLowerCase();
  }

  Future<void> fetchUserData() async {
    final uid = user?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();

        if (!mounted) return;

        if (data != null) {
          setState(() {
            name = data['name'] ?? '';
            profileImage = data['profile_image_url'] ?? '';
          });
        }
      } catch (e) {
        print("Error fetching profile: $e");
      }
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  void _logout() {
    if (mounted) {
      auth.signOut().then((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SignIn(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
          ),
        );
      });
    }
  }

  void closeSearchBar() {
    setState(() {
      _showSearchBar = false;
      _searchController.clear();
    });
    ref.read(searchQueryProvider.notifier).state = "";
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: ZoomDrawer(
        controller: _drawerController,
        menuScreen: MenuDrawer(
          currentIndex: _currentIndex,
          onItemSelected: (index) {
            closeSearchBar();
            setState(() => _currentIndex = index);
            _drawerController.toggle!();
          },
          forAdmin: true,
        ),
        mainScreen: Scaffold(
          appBar: AppBar(
            leading: null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleSpacing: 0,
            toolbarHeight: 70,
            title: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      if (!_showSearchBar) ...[
                        InkWell(
                          child: Image.asset(
                            AppTheme.appLogo(context),
                            width: 60,
                          ),
                          onTap: () => _drawerController.toggle!(),
                        ),
                        SizedBox(width: 10),
                        if (_currentIndex < 1) ...[
                          ClipOval(
                            child:
                                (user != null && user.profileImage.isNotEmpty)
                                ? Image.network(
                                    user.profileImage,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  )
                                : SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      HugeIconsSolid.user03,
                                      size: 30,
                                      color: AppTheme.iconColorThree(context),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Text(
                                "Hi, ",
                                style: AppTheme.textTitle(context).copyWith(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _currentIndex > 0
                                    ? menus[_currentIndex]
                                    : user?.name ?? name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.textTitle(context).copyWith(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                ".",
                                style: AppTheme.textTitleActive(
                                  context,
                                ).copyWith(fontFamily: 'Poppins', fontSize: 19),
                              ),
                            ],
                          ),
                        ],
                        if (_currentIndex > 0) ...[
                          Text(
                            forAdmin
                                ? _currentIndex > 0 && _currentIndex < 4
                                      ? "Manage"
                                      : "My"
                                : "My",
                            style: AppTheme.textTitle(context).copyWith(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            menus[_currentIndex],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.textTitle(context).copyWith(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            ".",
                            style: AppTheme.textTitleActive(
                              context,
                            ).copyWith(fontFamily: 'Poppins', fontSize: 18),
                          ),
                        ],
                        const Spacer(),
                      ],
                      if (_showSearchBar) ...[
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: "Search",
                              hintText: "Search Here...",
                              prefixIcon: Icon(HugeIconsSolid.search01),
                              counter: const SizedBox.shrink(),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        HugeIconsStroke.cancel02,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                                .read(
                                                  searchQueryProvider.notifier,
                                                )
                                                .state =
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
                              } else if (!RegExp(
                                r'^[a-zA-Z0-9 ]+$',
                              ).hasMatch(value)) {
                                return 'Must contain only letters or digits';
                              }
                              return null;
                            },
                            maxLength: 20,
                            onChanged: (value) {
                              ref.read(searchQueryProvider.notifier).state =
                                  value;
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (forAdmin)
                        if (_currentIndex > 0 && _currentIndex < 4)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showSearchBar = !_showSearchBar;
                                if (_showSearchBar) {
                                  Future.delayed(
                                    Duration(milliseconds: 50),
                                    () {
                                      _searchFocusNode.requestFocus();
                                    },
                                  );
                                } else {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state =
                                      "";
                                }
                              });
                            },
                            child: Icon(
                              _showSearchBar
                                  ? HugeIconsStroke.cancel02
                                  : HugeIconsSolid.search01,
                              color: AppTheme.iconColorThree(context),
                              size: 24,
                            ),
                          ),
                      if (!_showSearchBar) ...[
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            DialogLogout().showDialog(context, _logout);
                          },
                          child: Icon(
                            HugeIconsSolid.logout02,
                            color: AppTheme.iconColorThree(context),
                            size: 24,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: user == null
              ? const Center(child: LoadingLogo())
              : IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: buildAdminCurvedNavBar(context, _currentIndex, (
            index,
          ) {
            closeSearchBar();
            setState(() => _currentIndex = index);
          }),
        ),
        borderRadius: 24.0,
        showShadow: true,
        angle: -8.0,
        mainScreenScale: 0.05,
        shadowLayer1Color: AppTheme.customListBg(context).withOpacity(0.5),
        shadowLayer2Color: AppTheme.customListBg(context).withOpacity(1.0),
        mainScreenTapClose: true,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        menuBackgroundColor: Colors.transparent,
        openCurve: Curves.fastOutSlowIn,
        closeCurve: Curves.easeInBack,
      ),
    );
  }
}
