import 'dart:typed_data';
import 'dart:typed_data';
import '/components/appsnackbar.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/utils/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class EditBooks extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const EditBooks({super.key, required this.bookId, required this.bookData});

  @override
  State<EditBooks> createState() => _EditBooksState();
}


class _EditBooksState extends State<EditBooks> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _storageSupabase = Supabase.instance.client.storage.from("images");

  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController discountController;
  late TextEditingController descriptionController;
  late TextEditingController quantityController;

  Uint8List? _imageBytes;
  String? _imageName;
  String? currentImageUrl;
  String selectedCategory = 'All Books';
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
    titleController = TextEditingController(text: widget.bookData['title']);
    priceController = TextEditingController(
      text: widget.bookData['price'].toString(),
    );
    discountController = TextEditingController(
      text: widget.bookData['discount'].toString(),
    );
    descriptionController = TextEditingController(
      text: widget.bookData['description'],
    );
    quantityController = TextEditingController(
      text: widget.bookData['quantity']?.toString() ?? '0',
    );

    currentImageUrl = widget.bookData['cover_image_url'];

    // Show current book genre immediately
    selectedCategory = widget.bookData['genre'] ?? 'All Products';

    // Fetch all categories in the background
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
    await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.bookId)
        .update({
          'title': titleController.text.trim(),
          'price': double.tryParse(priceController.text.trim()) ?? 0.0,
          'discount': double.tryParse(discountController.text.trim()) ?? 0.0,
          'description': descriptionController.text.trim(),
          'quantity': int.tryParse(quantityController.text) ?? 0,
          'genre': selectedCategory,
          'cover_image_url': newImageUrl ?? currentImageUrl,
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Edit Product",
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),
              InkWell(
                onTap: pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.customListBg(context),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            _imageBytes!,
                            height: 180,
                            width: 150,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        )
                      : currentImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            currentImageUrl!,
                            height: 180,
                            width: 150,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        )
                      : Center(
                          child: Column(
                            spacing: 12,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                HugeIconsSolid.imageAdd01,
                                size: 50,
                                color: MyColors.primary,
                              ),
                              Text(
                                "Tap to upload or choose category image",
                                style: AppTheme.textSearchInfoLabeled(
                                  context,
                                ).copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              // ---------- Fields ----------
              _buildTextField(
                titleController,
                'Title',
                'Enter Product Name',
                HugeIconsSolid.textFont,
                maxLength: 40
              ),
              _buildTextField(
                priceController,
                'Price',
                'Enter Price',
                HugeIconsSolid.money01,
                keyboardType: TextInputType.number,
                maxLength: 5
              ),
              _buildTextField(
                quantityController,
                'Quantity',
                'Enter Quantity',
                HugeIconsSolid.package,
                keyboardType: TextInputType.number,
                maxLength: 3
              ),
              _buildTextField(
                discountController,
                'Discount',
                'Enter Discount',
                HugeIconsSolid.discount01,
                keyboardType: TextInputType.number,
                maxLength: 2
              ),
              _buildTextField(
                descriptionController,
                'Description',
                'Enter Description',
                HugeIconsSolid.documentValidation,
                maxLines: 4,
              ),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: AppTheme.textLabel(context),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(HugeIconsSolid.catalogue),
                  suffixIcon: Icon(
                    HugeIconsSolid.arrowDown01,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColor.neutral_70
                        : AppColor.neutral_20,
                  ),
                ),
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String? imageUrl = currentImageUrl;
                    if (_imageBytes != null && _imageName != null) {
                      imageUrl = await uploadImageToSupabase(
                        _imageBytes!,
                        _imageName!,
                      );
                    }

                    await updateBook(imageUrl);
                    AppSnackBar.show(
                      context,
                      message: "Product updated successfully!",
                      type: AppSnackBarType.success,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text("Update Product"),
              ),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
            ],
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
    int maxLength = 20
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        counter: SizedBox.shrink()
      ),
      maxLength: maxLength,
      validator: (value) =>
          value == null || value.isEmpty ? "$label is required" : null,
    );
  }
}
