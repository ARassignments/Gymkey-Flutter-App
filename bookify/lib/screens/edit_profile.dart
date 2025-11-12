import 'dart:typed_data';
import 'package:bookify/screens/profile.dart';
import 'package:bookify/utils/themes/custom_themes/app_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController searchController = TextEditingController();
  final auth = FirebaseAuth.instance;
  final _storageSupabase = Supabase.instance.client.storage.from("images");
  final picker = ImagePicker();

  String name = '';
  String email = '';
  String contact = '';
  String address = '';
  String profileImage = '';

  Uint8List? _imageBytes;
  String? _image;
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null) {
          setState(() {
            name = data['name'] ?? '';
            email = data['email'] ?? '';
            contact = data['phone'] ?? '';
            address = data['address'] ?? '';
            profileImage = data['profile_image_url'] ?? '';

            nameController.text = name;
            emailController.text = email;
            contactController.text = contact;
            addressController.text = address;
          });
        }
      } catch (e) {
        print("Error fetching profile: $e");
      }
    }
  }

  Future getProfileImage() async {
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _image = pickedFile.name;
      });
    }
  }

  Future<String?> uploadImage(Uint8List imageBytes, String imageName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final fileName =
          'bkfy_${DateTime.now().microsecondsSinceEpoch}_$imageName';
      await _storageSupabase.uploadBinary(fileName, imageBytes,
          fileOptions: FileOptions(cacheControl: '3600', upsert: false));

      final imageUrl = _storageSupabase.getPublicUrl(fileName);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profile_image_url': imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return imageUrl;
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                CustomNavBar(searchController: searchController),
                const SizedBox(height: 20),

                Text(
                  "Edit Profile",
                  style: MyTextTheme.lightTextTheme.headlineMedium?.copyWith(
                    color: MyColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Picture Section
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
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!)
                            : (profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : null) as ImageProvider?,
                        child: _imageBytes == null && profileImage.isEmpty
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: getProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: MyColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Card Container for Form Fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        _buildTextField(
                            controller: nameController,
                            icon: Icons.person_outline,
                            label: "Full Name",
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Name is required";
                              } else if (value.length < 3) {
                                return "Name must be at least 3 characters";
                              }
                              return null;
                            }),
                        const SizedBox(height: 12),
                        _buildTextField(
                            controller: emailController,
                            icon: Icons.email_outlined,
                            label: "Email"),
                        const SizedBox(height: 12),
                        _buildTextField(
                            controller: contactController,
                            icon: Icons.phone_outlined,
                            label: "Phone Number",
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _buildTextField(
                            controller: addressController,
                            icon: Icons.home_outlined,
                            label: "Address"),
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
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String? uploadImageUrl;
                          if (_imageBytes != null && _image != null) {
                            uploadImageUrl = await uploadImage(_imageBytes!, _image!);
                          }

                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'name': nameController.text,
                              'email': emailController.text,
                              'phone': contactController.text,
                              'address': addressController.text,
                              if (uploadImageUrl != null)
                                'profile_image_url': uploadImageUrl,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Profile updated successfully"),
                              ),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Save Changes',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: MyColors.primary),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(color: Colors.black87),
    );
  }
}
