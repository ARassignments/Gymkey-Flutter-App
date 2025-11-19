import 'package:bookify/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/components/dialog_logout.dart';
import '/components/loading_screen.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/screens/auth/users/sign_in.dart';
import '/screens/edit_profile.dart';
import '/screens/user_orders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;

  String name = '';
  String email = '';
  String contact = '';
  String address = '';
  String profileImage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();

        if (data != null && mounted) {
          setState(() {
            name = data['name'] ?? '';
            email = data['email'] ?? '';
            contact = data['phone'] ?? '';
            address = data['address'] ?? '';
            profileImage = data['profile_image_url'] ?? '';
          });
        }
      } catch (e) {
        print("Error fetching profile: $e");
      }
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = ref.watch(userProvider);
    return SafeArea(
      child: isLoading
          ? const Center(child: LoadingLogo())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture with Shadow
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.cardBg(context),
                      backgroundImage: profileImage.isNotEmpty
                          ? NetworkImage(user?.profileImage ?? profileImage)
                          : null,
                      child: profileImage.isEmpty
                          ? Icon(
                              HugeIconsSolid.user03,
                              size: 60,
                              color: AppTheme.iconColorThree(context),
                            )
                          : null,
                    ),
                  ),
    
                  const SizedBox(height: 16),
                  Text(
                    "Profile Details",
                    style: AppTheme.textTitle(context).copyWith(fontSize: 20),
                  ),
    
                  const SizedBox(height: 20),
    
                  // Card with details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            HugeIconsStroke.user03,
                            "Name",
                            user?.name ?? name,
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.dividerBg(context),
                          ),
                          _buildInfoTile(
                            HugeIconsStroke.mail01,
                            "Email",
                            user?.email ?? email,
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.dividerBg(context),
                          ),
                          _buildInfoTile(
                            HugeIconsStroke.call02,
                            "Contact",
                            user?.phone ?? contact,
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.dividerBg(context),
                          ),
                          _buildInfoTile(
                            HugeIconsStroke.mapsLocation01,
                            "Address",
                            user?.address ?? address,
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => EditProfileScreen(),
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
                              icon: const Icon(HugeIconsSolid.edit01),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                              ),
                              label: Text("Edit Profile"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
    
                  const SizedBox(height: 20),
    
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              HugeIconsStroke.shoppingBag01,
                              size: 24,
                            ),
                            title: Text(
                              "View Orders",
                              style: AppTheme.textLabel(context),
                            ),
                            trailing: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDarkBg(context),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "02",
                                style: AppTheme.textSearchInfoLabeled(
                                  context,
                                ).copyWith(fontSize: 10),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserOrders(),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.dividerBg(context),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              Theme.of(context).brightness == Brightness.dark
                                  ? HugeIconsStroke.moon02
                                  : HugeIconsStroke.sun02,
                              size: 24,
                            ),
                            title: Text(
                              Theme.of(context).brightness == Brightness.dark
                                  ? "Dark Mode"
                                  : "Light Mode",
                              style: AppTheme.textLabel(context),
                            ),
                            trailing: Switch(
                              value:
                                  Theme.of(context).brightness ==
                                  Brightness.dark,
                              onChanged: (value) {
                                ThemeController.setTheme(
                                  value ? ThemeMode.dark : ThemeMode.light,
                                );
                              },
                            ),
                            onTap: () {
                              final isDark =
                                  ThemeController.themeNotifier.value ==
                                  ThemeMode.dark;
                              ThemeController.setTheme(
                                isDark ? ThemeMode.light : ThemeMode.dark,
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: AppTheme.dividerBg(context),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              HugeIconsStroke.chartBreakoutCircle,
                              size: 24,
                            ),
                            title: Text(
                              "About GymKey",
                              style: AppTheme.textLabel(context),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
    
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColor.accent_50),
                          overlayColor: AppColor.accent_50.withOpacity(0.1),
                        ),
                        onPressed: () {
                          DialogLogout().showDialog(context, _logout);
                        },
                        child: Text(
                          'Log Out',
                          style: TextStyle(color: AppColor.accent_50),
                        ),
                      ),
                    ),
                  ),
    
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: Icon(icon, size: 24),
      title: Text(label, style: AppTheme.textLabel(context)),
      subtitle: Text(
        value.isNotEmpty ? value : "Not provided",
        style: AppTheme.textSearchInfoLabeled(context).copyWith(fontSize: 12),
      ),
    );
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
}
