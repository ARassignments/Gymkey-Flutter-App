import 'dart:io';
import 'dart:typed_data';
import 'package:bookify/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCategory extends StatefulWidget {
  const AddCategory({super.key});

  @override
  State<AddCategory> createState() => _AddCategoryState();
}

class _AddCategoryState extends State<AddCategory> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  final ImagePicker picker = ImagePicker();
  final supabase = Supabase.instance.client;

  bool _isLoading = false;

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

  Future<String?> uploadImageToSupabase(Uint8List bytes, String name) async {
    try {
      final fileName = 'cat_${DateTime.now().millisecondsSinceEpoch}_$name';

      // Upload binary using .upload
      final response = await Supabase.instance.client.storage
          .from('images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Generate public URL
      final publicUrl = Supabase.instance.client.storage
          .from('images')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  // Add category to Firestore
  Future<void> addCategoryToFirestore() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrl = await uploadImageToSupabase(_imageBytes!,_imageName!);

      await FirebaseFirestore.instance.collection('categories').add({
        'name': nameController.text.trim(),
        'image_url': imageUrl ?? '',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Firestore add category error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add category")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      appBar: AppBar(
        title: const Text("Add Category"),
        backgroundColor: MyColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickImage,
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _imageBytes!,
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: MyColors.primary,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  nameController,
                  "Category Name",
                  "Enter Category Name",
                  Icons.category,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: MyElevatedButtonTheme.lightElevatedButtonTheme.style,
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              addCategoryToFirestore();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please fill all fields"),
                                ),
                              );
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Add Category"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      validator: (value) =>
          value == null || value.isEmpty ? "$label is required" : null,
      style: const TextStyle(color: MyColors.primary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: MyColors.primary),
        prefixIcon: Icon(icon, color: MyColors.primary),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MyColors.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MyColors.primary, width: 2),
        ),
      ),
    );
  }
}
