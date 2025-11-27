import 'dart:typed_data';
import '/components/appsnackbar.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCategoryBottomSheet extends StatefulWidget {
  final String categoryId;
  final Map<String, dynamic> categoryData;

  const EditCategoryBottomSheet({
    super.key,
    required this.categoryId,
    required this.categoryData,
  });

  @override
  State<EditCategoryBottomSheet> createState() =>
      _EditCategoryBottomSheetState();
}

class _EditCategoryBottomSheetState extends State<EditCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
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

      AppSnackBar.show(
        context,
        message: "Category updated successfully!",
        type: AppSnackBarType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      print("Update error: $e");
      AppSnackBar.show(
        context,
        message: "Failed to update category!",
        type: AppSnackBarType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
                "Edit Category",
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
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            currentImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: AppTheme.customListBg(context),
                                  child: Icon(
                                    HugeIconsSolid.imageNotFound01,
                                    color: AppTheme.iconColorThree(context),
                                  ),
                                ),
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

              TextFormField(
                controller: nameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: "Category Name",
                  hintText: 'e.g. Shirts/Bottles/Bags...',
                  prefixIcon: Icon(HugeIconsSolid.catalogue),
                  counter: const SizedBox.shrink(),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category Name is required';
                  } else if (value.length < 4) {
                    return 'Category Name must be at least 4 characters long';
                  } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                    return 'Category Name must contain only letters';
                  }
                  return null;
                },
                maxLength: 20,
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),

              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await updateCategory();
                        }
                      },
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          strokeCap: StrokeCap.round,
                          color: Colors.white,
                        ),
                      )
                    : Text("Update Category"),
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
}
