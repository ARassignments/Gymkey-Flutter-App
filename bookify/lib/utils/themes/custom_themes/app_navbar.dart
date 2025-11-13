// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:bookify/screens/auth/users/sign_in.dart';
// import 'package:bookify/utils/constants/colors.dart';
// import 'package:bookify/utils/themes/custom_themes/text_theme.dart';

// class CustomNavBar extends StatefulWidget {
//   const CustomNavBar({super.key});

//   @override
//   State<CustomNavBar> createState() => _CustomNavBarState();
// }

// class _CustomNavBarState extends State<CustomNavBar> {
//   final auth = FirebaseAuth.instance;
//   final user = FirebaseAuth.instance.currentUser;
//   final TextEditingController _searchController = TextEditingController();

//   String name = '';
//   String profileImage = '';
//   bool isLoading = true;
//   bool _showSearchBar = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchUserData();
//   }

//   Future<void> fetchUserData() async {
//     final uid = user?.uid;
//     if (uid != null) {
//       try {
//         final doc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(uid)
//             .get();
//         final data = doc.data();
//         if (data != null) {
//           setState(() {
//             name = data['name'] ?? '';
//             profileImage = data['profile_image_url'] ?? '';
//           });
//         }
//       } catch (e) {
//         print("Error fetching profile: $e");
//       }
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Row(
//             children: [
//               ClipOval(
//                 child: (profileImage.isNotEmpty)
//                     ? Image.network(
//                         profileImage,
//                         width: 40,
//                         height: 40,
//                         fit: BoxFit.cover,
//                       )
//                     : (user?.photoURL != null)
//                     ? Image.network(
//                         user!.photoURL!,
//                         width: 40,
//                         height: 40,
//                         fit: BoxFit.cover,
//                       )
//                     : const Icon(Icons.person, size: 40, color: Colors.grey),
//               ),
//               const SizedBox(width: 10),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Hi, ${user?.displayName ?? name}",
//                     style: MyTextTheme.lightTextTheme.titleLarge,
//                   ),
//                   const Text(
//                     "Have a nice day",
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//               const Spacer(),
//               InkWell(
//                 onTap: () {
//                   setState(() {
//                     _showSearchBar = !_showSearchBar;
//                   });
//                 },
//                 child: Icon(
//                   Icons.search_rounded,
//                   color: MyColors.primary,
//                   size: 30,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               InkWell(
//                 onTap: () {
//                   auth.signOut().then((_) {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (context) => const SignIn()),
//                     );
//                   });
//                 },
//                 child: Icon(Icons.logout, color: MyColors.primary, size: 30),
//               ),
//             ],
//           ),
//         ),
//         if (_showSearchBar)
//           Padding(
//             padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
//             child: TextField(
//               controller: _searchController,
//               style: const TextStyle(color: Colors.black),
//               decoration: InputDecoration(
//                 hintText: "Search...",
//                 hintStyle: const TextStyle(color: Colors.grey),
//                 prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/screens/auth/users/sign_in.dart';

class CustomNavBar extends StatefulWidget {
  final TextEditingController searchController; // Accepting search controller

  const CustomNavBar({
    super.key,
    required this.searchController,
  }); // Pass the controller

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  final auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _showSearchBar = false;

  String name = '';
  String profileImage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, ${user?.displayName ?? name}",
                    style: AppTheme.textTitle(context),
                  ),
                  // const Text(
                  //   "Have a nice day",
                  //   style: TextStyle(
                  //     color: Colors.grey,
                  //     fontSize: 12,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                ],
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    _showSearchBar = !_showSearchBar;
                  });
                },
                child: Icon(
                  HugeIconsSolid.search01,
                  color: AppTheme.iconColorThree(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  auth.signOut().then((_) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignIn()),
                    );
                  });
                },
                child: Icon(
                  HugeIconsSolid.logout02,
                  color: AppTheme.iconColorThree(context),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        if (_showSearchBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: TextField(
              controller: widget.searchController,
              decoration: InputDecoration(
                prefixIcon: Icon(HugeIconsSolid.search01),
                labelText: "Search",
                hintText: "Search Here...",
              ),
            ),
          ),
      ],
    );
  }
}
