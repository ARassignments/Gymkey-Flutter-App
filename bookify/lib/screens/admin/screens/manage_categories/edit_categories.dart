import 'dart:io';
import 'dart:typed_data';
import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCategory extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic> categoryData;

  const EditCategory({
    super.key,
    required this.categoryId,
    required this.categoryData,
  });

  @override
  State<EditCategory> createState() => _EditCategoryState();
}

class _EditCategoryState extends State<EditCategory> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _storageSupabase = Supabase.instance.client.storage.from("images");
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  Uint8List? _imageBytes;
  String? _imageName;
  String? currentImageUrl;
  final picker = ImagePicker();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.categoryData['name']);
    descriptionController = TextEditingController(
      text: widget.categoryData['description'] ?? '',
    );
    currentImageUrl = widget.categoryData['image_url'] ?? '';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  // ---------- Upload to Supabase ----------
  Future<String?> uploadImageToSupabase(Uint8List bytes, String name) async {
    try {
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}_$name';
      await _storageSupabase.uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: false),
      );
      return _storageSupabase.getPublicUrl(fileName);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // Update Firestore
  Future<void> updateCategory() async {
    setState(() => _isLoading = true);

    try {
      String? imageUrl = widget.categoryData['image_url'];
      if (_imageBytes != null) {
        imageUrl = await uploadImageToSupabase(_imageBytes!, _imageName!);
      }

      await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .update({
            'name': nameController.text.trim(),
            'image_url': imageUrl ?? '',
            'updated_at': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category updated successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update category!")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    "Edit Category",
                    style: TextStyle(
                      color: MyColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- IMAGE PICKER ----------
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: MyColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : (currentImageUrl != null &&
                              currentImageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              currentImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 40,
                                  color: MyColors.primary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Tap to upload product image",
                                  style: TextStyle(color: MyColors.primary),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- NAME FIELD ----------
                _buildTextField(
                  nameController,
                  'Category Name',
                  'Enter Category Name',
                  Icons.category,
                ),

                // ---------- UPDATE BUTTON ----------
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style:
                          MyElevatedButtonTheme.lightElevatedButtonTheme.style,
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                await updateCategory();
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Update Category"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- REUSABLE TEXT FIELD ----------
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: const TextStyle(color: MyColors.primary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: MyColors.primary),
          hintStyle: const TextStyle(color: MyColors.primary),
          prefixIcon: Icon(icon, color: MyColors.primary),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MyColors.primary, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: MyColors.primary, width: 2),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? "$label is required" : null,
      ),
    );
  }
}
