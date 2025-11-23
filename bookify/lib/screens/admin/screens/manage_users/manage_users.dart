import '/screens/auth/users/sign_in.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _searchController.addListener(_onSearchChanged);
  }

  void fetchUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
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
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/b.jpg"),
                      radius: 20,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hi, Admin",
                          style: MyTextTheme.lightTextTheme.titleLarge,
                        ),
                        const Text(
                          "Administrator",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.search_rounded, color: MyColors.primary),
                      onPressed: () =>
                          setState(() => _showSearchBar = !_showSearchBar),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: MyColors.primary),
                      onPressed: () async {
                        await _auth.signOut();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const SignIn()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_showSearchBar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  "Manage Users",
                  style: TextStyle(
                    color: MyColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(12.0),
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
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Profile image with better error handling
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: profileImage.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        profileImage,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.person,
                                                  size: 30,
                                                ),
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return const SizedBox(
                                                width: 30,
                                                height: 30,
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            },
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(color: MyColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
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
