import 'dart:typed_data';
import 'package:bookify/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBooks extends StatefulWidget {
  const AddBooks({super.key});

  @override
  State<AddBooks> createState() => _AddBooksState();
}

class _AddBooksState extends State<AddBooks> {
  @override
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _storageSupabase = Supabase.instance.client.storage.from("images");
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController();

  String? selectedCategory;
  Uint8List? _imageBytes;
  String? _imageName;

  List<String> categories = [];
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .get();
    final cats = snapshot.docs.map((doc) => doc['name'] as String).toList();
    setState(() {
      categories = cats;
    });
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

  Future<String?> uploadImageToSupabase(Uint8List bytes, String name) async {
    try {
      final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}_$name';

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

  Future<void> addBookToFirestore(String imageUrl) async {
    await FirebaseFirestore.instance.collection('books').add({
      'title': titleController.text,
      'price': double.tryParse(priceController.text) ?? 0.0,
      'description': descriptionController.text,
      'category': selectedCategory ?? '',
      'cover_image_url': imageUrl,
      'quantity': int.tryParse(quantityController.text) ?? 0,
      'is_featured': selectedCategory == "Featured",
      'is_popular': selectedCategory == "Popular",
      'is_best_selling': selectedCategory == "Best Selling",
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeeeeee),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, Admin",
                        style: MyTextTheme.lightTextTheme.titleLarge,
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
                    onTap: () =>
                        setState(() => _showSearchBar = !_showSearchBar),
                    child: Icon(
                      Icons.search_rounded,
                      color: MyColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      _auth.signOut().then((value) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignIn(),
                          ),
                        );
                      });
                    },
                    child: Icon(
                      Icons.logout,
                      color: MyColors.primary,
                      size: 30,
                    ),
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
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Add Product",
                          style: TextStyle(
                            color: MyColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: pickImage,
                          child: Container(
                            height: 150,
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
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 40,
                                          color: MyColors.primary,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Tap to upload Product image",
                                          style: TextStyle(
                                            color: MyColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      _buildTextField(
                        titleController,
                        'Title',
                        'Enter Product Name',
                        Icons.book,
                      ),
                      _buildTextField(
                        descriptionController,
                        'Description',
                        'Enter Product Description',
                        Icons.description,
                        maxLines: 4,
                      ),
                      _buildTextField(
                        priceController,
                        'Price',
                        'Enter Product Price',
                        Icons.currency_exchange_sharp,
                        isNumber: true,
                      ),
                      _buildTextField(
                        quantityController,
                        'Quantity',
                        'Enter Product quantity',
                        Icons.confirmation_num,
                        isNumber: true,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2(
                            isExpanded: true,
                            hint: const Text(
                              "Select Category",
                              style: TextStyle(color: MyColors.primary),
                            ),
                            value: selectedCategory,
                            onChanged: (value) =>
                                setState(() => selectedCategory = value),
                            items: categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      cat,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: MyColors.primary,
                                      ),
                                    ),
                                    if (selectedCategory == cat)
                                      const Icon(
                                        Icons.check_circle,
                                        color: MyColors.primary,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            buttonStyleData: ButtonStyleData(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                border: Border.all(color: MyColors.primary),
                              ),
                              elevation: 3,
                            ),
                            iconStyleData: const IconStyleData(
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: MyColors.primary,
                              ),
                              iconSize: 28,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 250,
                              width: MediaQuery.of(context).size.width - 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                              ),
                              offset: const Offset(0, -4),
                              scrollbarTheme: ScrollbarThemeData(
                                radius: const Radius.circular(40),
                                thickness: MaterialStateProperty.all(5),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: MyElevatedButtonTheme
                                .lightElevatedButtonTheme
                                .style,
                            onPressed: () async {
                              if (_formKey.currentState!.validate() &&
                                  _imageBytes != null &&
                                  _imageName != null) {
                                final imageUrl = await uploadImageToSupabase(
                                  _imageBytes!,
                                  _imageName!,
                                );
                                if (imageUrl != null) {
                                  await addBookToFirestore(imageUrl);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Product added successfully",
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Image upload failed"),
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please complete all fields and upload image",
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text("Add Product"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
