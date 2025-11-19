import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/providers/user_provider.dart';
import '/utils/themes/custom_themes/bottomnavbar.dart';
import '/screens/home.dart';
import '/screens/auth/users/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/screens/cart.dart';
import '/screens/profile.dart';
import '/screens/wishlist.dart';
import '/screens/catalog.dart';
import '/utils/themes/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/components/menu_drawer.dart';
import '/components/dialog_logout.dart';
import '/components/loading_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _showSearchBar = false;
  String name = '';
  String profileImage = '';
  bool isLoading = true;
  int _currentIndex = 0;
  final ZoomDrawerController _drawerController = ZoomDrawerController();
  List<String> menus = ["Home", "Catalogs", "Cart", "Wishlist", "Accounts"];
  late final List<Widget> pages;
  final HomeScreen homeScreen = const HomeScreen();
  final CatalogScreen catalogScreen = const CatalogScreen();
  final CartScreen cartScreen = const CartScreen();
  final WishListScreen wishListScreen = const WishListScreen();
  final ProfileScreen profileScreen = const ProfileScreen();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    pages = [
      homeScreen,
      catalogScreen,
      cartScreen,
      wishListScreen,
      profileScreen
    ];
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // final query = searchController.text.trim().toLowerCase();
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

        if (!mounted) return; // ✅ check before setState

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

    if (!mounted) return; // ✅ check again before last update
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: ZoomDrawer(
        controller: _drawerController,
        menuScreen: MenuDrawer(
          currentIndex: _currentIndex,
          onItemSelected: (index) {
            setState(() => _currentIndex = index);
            _drawerController.toggle!();
          },
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
                            "My",
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
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(HugeIconsSolid.search01),
                              labelText: "Search",
                              hintText: "Search Here...",
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showSearchBar = !_showSearchBar;
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
          bottomNavigationBar: buildCurvedNavBar(context, _currentIndex, (
            index,
          ) {
            setState(() => _currentIndex = index);
          }),
        ),
        borderRadius: 24.0,
        showShadow: true,
        angle: -8.0,
        mainScreenScale: 0.05, // slightly more zoom-in effect
        shadowLayer1Color: AppTheme.customListBg(context).withOpacity(0.5),
        shadowLayer2Color: AppTheme.customListBg(context).withOpacity(1.0),
        mainScreenTapClose: true,
        // overlayBlur: 0.8,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        menuBackgroundColor: Colors.transparent,
        openCurve: Curves.fastOutSlowIn,
        closeCurve: Curves.easeInBack,
      ),
    );
  }
}
