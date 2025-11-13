import '/components/loading_screen.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/screens/auth/users/sign_in.dart';
import '/screens/edit_profile.dart';
import '/screens/home.dart';
import '/screens/user_orders.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/app_navbar.dart';
import '/utils/themes/custom_themes/bottomnavbar.dart';
import '/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();

        if (data != null) {
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
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? const Center(child: LoadingLogo())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
    
                    // View Orders Button
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserOrders()),
                            );
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, color: MyColors.primary),
                          label: Text(
                            "View Orders",
                            style: TextStyle(
                              color: MyColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
    
                    const SizedBox(height: 10),
    
                    // Profile Picture with Shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: MyColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: AppTheme.cardBg(context),
                        backgroundImage: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage.isEmpty
                            ? const Icon(HugeIconsSolid.user03, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
    
                    const SizedBox(height: 20),
    
                    Text(
                      "Profile Details",
                      style: AppTheme.textTitle(context).copyWith(fontSize: 20),
                    ),
    
                    const SizedBox(height: 20),
    
                    // Card with details
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg(context),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoTile(HugeIconsStroke.user03, "Name", name),
                            Divider(height: 20, thickness: 1, color: AppTheme.dividerBg(context)),
                            _buildInfoTile(HugeIconsStroke.mail01, "Email", email),
                            Divider(height: 20, thickness: 1, color: AppTheme.dividerBg(context)),
                            _buildInfoTile(HugeIconsStroke.call02, "Contact", contact),
                            Divider(height: 20, thickness: 1, color: AppTheme.dividerBg(context)),
                            _buildInfoTile(HugeIconsStroke.mapsLocation01, "Address", address),
                          ],
                        ),
                      ),
                    ),
    
                    const SizedBox(height: 30),
    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MyColors.primary, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.textSearchInfoLabeled(context).copyWith(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                value.isNotEmpty ? value : "Not provided",
                style: AppTheme.textSearchInfoLabeled(context).copyWith(fontSize: 13, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
