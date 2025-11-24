import 'dart:typed_data';
import '/components/appsnackbar.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/utils/constants/colors.dart';
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
                "Add Product",
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
              _buildTextField(
                titleController,
                'Title',
                'Enter Product Name',
                HugeIconsSolid.textFont,
              ),
              _buildTextField(
                priceController,
                'Price',
                'Enter Product Price',
                HugeIconsSolid.money01,
                isNumber: true,
              ),
              _buildTextField(
                quantityController,
                'Quantity',
                'Enter Product quantity',
                HugeIconsSolid.package,
                isNumber: true,
              ),
              _buildTextField(
                descriptionController,
                'Description',
                'Enter Product Description',
                HugeIconsSolid.documentValidation,
                maxLines: 4,
              ),

              DropdownButtonHideUnderline(
                child: DropdownButton2(
                  isExpanded: true,
                  hint: Row(
                    spacing: 12,
                    children: [
                      Icon(
                        HugeIconsSolid.catalogue,
                        size: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutral_70
                            : AppColor.neutral_20,
                      ),
                      Text(
                        "Select Category",
                        style: Theme.of(context).brightness == Brightness.dark
                            ? TextStyle(
                                fontSize: 14,
                                color: AppColor.neutral_60,
                              )
                            : TextStyle(
                                fontSize: 14,
                                color: AppColor.neutral_40,
                              ),
                      ),
                    ],
                  ),
                  value: selectedCategory,
                  onChanged: (value) =>
                      setState(() => selectedCategory = value),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        spacing: 12,
                        children: [
                          Icon(
                            HugeIconsSolid.catalogue,
                            size: 24,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColor.neutral_70
                                : AppColor.neutral_20,
                          ),
                          Expanded(
                            child: Text(
                              cat,
                              style:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? TextStyle(
                                      fontSize: 14,
                                      color: AppColor.neutral_60,
                                    )
                                  : TextStyle(
                                      fontSize: 14,
                                      color: AppColor.neutral_40,
                                    ),
                            ),
                          ),
                          if (selectedCategory == cat)
                            Icon(
                              HugeIconsSolid.checkmarkCircle01,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColor.neutral_70
                                  : AppColor.neutral_20,
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  buttonStyleData: ButtonStyleData(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_90
                          : AppColor.neutral_5,
                    ),
                    elevation: 0,
                  ),
                  iconStyleData: IconStyleData(
                    icon: Icon(
                      HugeIconsSolid.arrowDown01,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColor.neutral_70
                          : AppColor.neutral_20,
                    ),
                    iconSize: 24,
                  ),

                  dropdownStyleData: DropdownStyleData(
                    maxHeight: 250,
                    elevation: 0,
                    width: MediaQuery.of(context).size.width - 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.sliderHighlightBg(context),
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

              Divider(height: 1, color: AppTheme.dividerBg(context)),

              ElevatedButton(
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
                      AppSnackBar.show(
                        context,
                        message: "Product added successfully",
                        type: AppSnackBarType.success,
                      );
                      Navigator.pop(context);
                    } else {
                      AppSnackBar.show(
                        context,
                        message: "Image upload failed",
                        type: AppSnackBarType.error,
                      );
                    }
                  } else {
                    AppSnackBar.show(
                      context,
                      message: "Please complete all fields and upload image",
                      type: AppSnackBarType.error,
                    );
                  }
                },
                child: Text("Add Product"),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "$label is required" : null,
    );
  }
}
