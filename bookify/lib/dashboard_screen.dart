import 'package:flutter/services.dart';
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim().toLowerCase();
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

  List<Widget> _pages() {
    return [
      _homePage(),
      _catalogPage(),
      _cartPage(),
      _wishlistPage(),
      _accountsPage(),
    ];
  }

  Widget _homePage() {
    return HomeScreen();
  }

  Widget _catalogPage() {
    return CatalogScreen();
  }

  // Widget _accountsPage() {
  //   return ListView(
  //     shrinkWrap: true,
  //     children: [
  //       ValueListenableBuilder<String?>(
  //         valueListenable: avatarNotifier,
  //         builder: (context, avatar, _) {
  //           return ListTile(
  //             contentPadding: const EdgeInsets.symmetric(
  //               horizontal: 16,
  //               vertical: 8,
  //             ),
  //             title: Row(
  //               children: [
  //                 CircleAvatar(
  //                   radius: 40,
  //                   backgroundColor: AppTheme.customListBg(context),
  //                   foregroundImage: avatar != null
  //                       ? AssetImage(avatar)
  //                       : const AssetImage("assets/images/avatars/boy_14.png"),
  //                 ),
  //                 SizedBox(width: 16),
  //                 Column(
  //                   mainAxisAlignment: MainAxisAlignment.start,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       "${user!["FullName"]}",
  //                       style: AppTheme.textLabel(context).copyWith(
  //                         fontSize: 17,
  //                         fontFamily: AppFontFamily.poppinsSemiBold,
  //                       ),
  //                     ),
  //                     SizedBox(height: 4),
  //                     Text(
  //                       "View Profile",
  //                       style: AppTheme.textLink(context).copyWith(
  //                         fontSize: 12,
  //                         fontFamily: AppFontFamily.poppinsRegular,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => const ProfileScreen()),
  //               );
  //             },
  //           );
  //         },
  //       ),
  //       Divider(thickness: 30, height: 30, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.userGroup, size: 24),
  //         title: Text("Customers", style: AppTheme.textLabel(context)),
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (_) => const CustomersScreen()),
  //           );
  //         },
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.moneyReceiveFlow01, size: 24),
  //         title: Text("Payments", style: AppTheme.textLabel(context)),
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (_) => const PaymentsScreen()),
  //           );
  //         },
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.recycle02, size: 24),
  //         title: Text("Scraps", style: AppTheme.textLabel(context)),
  //         onTap: () {
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (_) => const ScrapsScreen()),
  //           );
  //         },
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.userGroup03, size: 24),
  //         title: Text("Users", style: AppTheme.textLabel(context)),
  //         onTap: () {},
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.messageMultiple02, size: 24),
  //         title: Text("Messages", style: AppTheme.textLabel(context)),
  //         onTap: () {},
  //       ),
  //       Divider(thickness: 30, height: 30, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(
  //           Theme.of(context).brightness == Brightness.dark
  //               ? HugeIconsStroke.moon02
  //               : HugeIconsStroke.sun02,
  //           size: 24,
  //         ),
  //         title: Text(
  //           Theme.of(context).brightness == Brightness.dark
  //               ? "Dark Mode"
  //               : "Light Mode",
  //           style: AppTheme.textLabel(context),
  //         ),
  //         trailing: Switch(
  //           value: ThemeController.themeNotifier.value == ThemeMode.dark,
  //           onChanged: (value) {
  //             ThemeController.setTheme(
  //               value ? ThemeMode.dark : ThemeMode.light,
  //             );
  //           },
  //         ),
  //         onTap: () {
  //           final isDark =
  //               ThemeController.themeNotifier.value == ThemeMode.dark;
  //           ThemeController.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  //         },
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.crown03, size: 24),
  //         title: Text("Subscription", style: AppTheme.textLabel(context)),
  //         onTap: () {},
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.note, size: 24),
  //         title: Text("Privacy Policy", style: AppTheme.textLabel(context)),
  //         onTap: () {},
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.headset, size: 24),
  //         title: Text("Help Center", style: AppTheme.textLabel(context)),
  //         onTap: () {},
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       ListTile(
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 8,
  //         ),
  //         leading: Icon(HugeIconsStroke.chartBreakoutCircle, size: 24),
  //         title: Text(
  //           "About Y2K Solutions",
  //           style: AppTheme.textLabel(context),
  //         ),
  //         onTap: () {},
  //       ),
  //       Divider(height: 1, color: AppTheme.dividerBg(context)),
  //       const SizedBox(height: 50),
  //       ListTile(
  //         title: OutlineErrorButton(
  //           text: 'Log Out',
  //           onPressed: () {
  //             DialogLogout().showDialog(context, _logout);
  //           },
  //         ),
  //       ),
  //       const SizedBox(height: 30),
  //     ],
  //   );
  // }

  Widget _cartPage() {
    return CartScreen();
  }

  Widget _wishlistPage() {
    return WishListScreen();
  }

  Widget _accountsPage() {
    return ProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages();
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
            title: Expanded(
              child: Column(
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
                              child: (profileImage.isNotEmpty)
                                  ? Image.network(
                                      profileImage,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : (user?.photoURL != null)
                                  ? Image.network(
                                      user!.photoURL!,
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
                                      : user?.displayName ?? name,
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
                                  style: AppTheme.textTitleActive(context)
                                      .copyWith(
                                        fontFamily: 'Poppins',
                                        fontSize: 19,
                                      ),
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
          ),
          body: user == null
              ? const Center(child: LoadingLogo())
              : IndexedStack(index: _currentIndex, children: _pages()),
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
