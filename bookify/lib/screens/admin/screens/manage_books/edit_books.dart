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

class EditBooks extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const EditBooks({
    super.key,
    required this.bookId,
    required this.bookData,
  });

  @override
  State<EditBooks> createState() => _EditBooksState();
}

class _EditBooksState extends State<EditBooks> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _storageSupabase = Supabase.instance.client.storage.from("images");

  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController quantityController;
 


  Uint8List? _imageBytes;
  String? _imageName;
  String? currentImageUrl;
  String selectedCategory = 'All Books';

  // ✅ Your available categories
  final List<String> categories = [
    "Featured",
    "Popular",
    "Best Selling",
    "Novels",
    "Self Love",
    "Action",
    "History",
    "Fantasy",
    "Romance",
    "Science",
    "Poetry",
    "All Books",
  ];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.bookData['title']);
    priceController = TextEditingController(
      text: widget.bookData['price'].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.bookData['description'],
    );
    quantityController = TextEditingController(
  text: widget.bookData['quantity']?.toString() ?? '0',
);

    currentImageUrl = widget.bookData['cover_image_url'];

    final genre = widget.bookData['genre'];
    // ✅ Handle missing or unknown genres safely
    if (genre != null && genre is String && genre.isNotEmpty) {
      if (!categories.contains(genre)) {
        categories.insert(0, genre);
      }
      selectedCategory = genre;
    }
  }

  // ---------- Pick image ----------
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

  // ---------- Update Firestore ----------
  Future<void> updateBook(String? newImageUrl) async {
    await FirebaseFirestore.instance.collection('books').doc(widget.bookId).update({
      'title': titleController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
      'description': descriptionController.text.trim(),
      'quantity': int.tryParse(quantityController.text) ?? 0,
      'genre': selectedCategory,
      'cover_image_url': newImageUrl ?? currentImageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                // ---------- HEADER ----------
                Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        "assets/images/b.jpg",
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Hi, Admin",
                      style: MyTextTheme.lightTextTheme.titleLarge,
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        _auth.signOut().then((value) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignIn()),
                          );
                        });
                      },
                      child: const Icon(Icons.logout, color: MyColors.primary, size: 30),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Text(
                  "Edit Product",
                  style: TextStyle(
                    color: MyColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- Image ----------
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
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
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : currentImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(currentImageUrl!, fit: BoxFit.cover),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image, size: 40, color: MyColors.primary),
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

                // ---------- Fields ----------
                _buildTextField(titleController, 'Title', 'Enter Product Name', Icons.book),
                _buildTextField(priceController, 'Price', 'Enter Price', Icons.attach_money,
                    keyboardType: TextInputType.number),
                _buildTextField(quantityController, 'Quantity', 'Enter Quantity', Icons.attach_money,
                    keyboardType: TextInputType.number),
                _buildTextField(descriptionController, 'Description', 'Enter Description',
                    Icons.description, maxLines: 3),

                // ---------- Category Dropdown ----------
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: const TextStyle(color: MyColors.primary)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category, color: MyColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: MyColors.primary),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                // ---------- Update Button ----------
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: MyElevatedButtonTheme.lightElevatedButtonTheme.style,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          String? imageUrl = currentImageUrl;
                          if (_imageBytes != null && _imageName != null) {
                            imageUrl = await uploadImageToSupabase(_imageBytes!, _imageName!);
                          }

                          await updateBook(imageUrl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Product updated successfully!")),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Update Product"),
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

  // ---------- Reusable TextField ----------
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
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
