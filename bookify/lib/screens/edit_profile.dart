import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/user_provider.dart';
import '../utils/constants/colors.dart';
import '../utils/themes/themes.dart';
import '../components/appsnackbar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final _storageSupabase = Supabase.instance.client.storage.from("images");

  Uint8List? _imageBytes;
  String? _imageName;
  bool isSaving = false;

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    addressController = TextEditingController(text: user?.address ?? '');
  }

  Future<void> getProfileImage() async {
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

  Future<String?> uploadImage(Uint8List imageBytes, String imageName) async {
    try {
      final fileName =
          'bkfy_${DateTime.now().microsecondsSinceEpoch}_$imageName';
      await _storageSupabase.uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      return _storageSupabase.getPublicUrl(fileName);
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.screenBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          "Edit Profile",
          style: AppTheme.textTitle(context).copyWith(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(HugeIconsStroke.arrowLeft01, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.customListBg(context),
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (user.profileImage.isNotEmpty
                                    ? NetworkImage(user.profileImage)
                                    : null)
                                as ImageProvider?,
                      child: _imageBytes == null && user.profileImage.isEmpty
                          ? Icon(
                              HugeIconsSolid.user03,
                              size: 60,
                              color: AppTheme.cardBg(context),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: InkWell(
                        onTap: getProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: MyColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            HugeIconsSolid.camera01,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Form Fields
                TextFormField(
                  controller: nameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    hintText: 'e.g. David Smith',
                    prefixIcon: Icon(HugeIconsSolid.user03),
                    counter: const SizedBox.shrink(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    } else if (value.length < 3) {
                      return 'Name must be at least 3 characters long';
                    } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                      return 'Name must contain only letters';
                    }
                    return null;
                  },
                  maxLength: 20,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(HugeIconsSolid.mail01),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Contact",
                    hintText: 'e.g. 012345678910',
                    prefixIcon: Icon(HugeIconsSolid.call02),
                    counter: const SizedBox.shrink(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your contact';
                    } else if (value.length < 10) {
                      return 'Contact must be at least 10 digits long';
                    } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Contact must contain only number';
                    }
                    return null;
                  },
                  maxLength: 15,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: "Address",
                    hintText: 'e.g. House no/Street/City',
                    prefixIcon: Icon(HugeIconsSolid.mapsLocation01),
                    counter: const SizedBox.shrink(),
                  ),
                  keyboardType: TextInputType.text,
                  maxLines: 5,
                  maxLength: 200,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => isSaving = true);

                            String? imageUrl;
                            if (_imageBytes != null && _imageName != null) {
                              imageUrl = await uploadImage(
                                _imageBytes!,
                                _imageName!,
                              );
                            }

                            final updates = {
                              'name': nameController.text,
                              'email': emailController.text,
                              'phone': phoneController.text,
                              'address': addressController.text,
                              if (imageUrl != null)
                                'profile_image_url': imageUrl,
                            };

                            await ref
                                .read(userProvider.notifier)
                                .updateUser(updates);

                            AppSnackBar.show(
                              context,
                              message: "Profile updated successfully",
                              type: AppSnackBarType.success,
                            );

                            setState(() => isSaving = false);

                            Navigator.pop(context);
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
