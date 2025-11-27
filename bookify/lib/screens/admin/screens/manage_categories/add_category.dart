import 'dart:typed_data';
import '/components/appsnackbar.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/themes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  const AddCategoryBottomSheet({super.key});

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  final ImagePicker picker = ImagePicker();
  final supabase = Supabase.instance.client;

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(
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

      await supabase.storage
          .from('images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return supabase.storage.from('images').getPublicUrl(fileName);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> addCategory() async {
    if (_imageBytes == null) {
      AppSnackBar.show(
        context,
        message: "Please select an image",
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await uploadImageToSupabase(_imageBytes!, _imageName!);

      await FirebaseFirestore.instance.collection('categories').add({
        'name': nameController.text.trim(),
        'image_url': imageUrl ?? '',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // close bottom sheet
      AppSnackBar.show(
        context,
        message: "Category Added Successfully",
        type: AppSnackBarType.success,
      );
    } catch (e) {
      print("Add category error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to add category")));
    }

    setState(() => _isLoading = false);
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
                "Add Category",
                textAlign: TextAlign.center,
                style: AppTheme.textLabel(
                  context,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w600),
              ),

              Divider(height: 1, color: AppTheme.dividerBg(context)),
              InkWell(
                onTap: pickImage,
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
                    : Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.customListBg(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
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
                    : () {
                        if (_formKey.currentState!.validate()) addCategory();
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
                    : Text("Add Category"),
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
