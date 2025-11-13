import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '/screens/auth/users/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SignUp extends StatefulWidget {
  SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();

  final emailController = TextEditingController();

  final passController = TextEditingController();

  final phoneController = TextEditingController();

  final addressController = TextEditingController();

  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/logo222.png',
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 220,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),

                      // Name
                      TextFormField(
                        controller: nameController,
                        keyboardType: TextInputType.text,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _inputDecoration(
                          'Name',
                          'Enter your name',
                          HugeIconsSolid.user03,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Name is required";
                          final nameRegex = RegExp(r"^[A-Za-z ]{3,}$");
                          if (!nameRegex.hasMatch(value))
                            return "Enter your valid name";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _inputDecoration(
                          'Email',
                          'Enter your email',
                          HugeIconsSolid.mail01,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Email is required";
                          final emailRegex = RegExp(
                            r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                          );
                          if (!emailRegex.hasMatch(value))
                            return "Enter a valid email address";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Password
                      TextFormField(
                        controller: passController,
                        obscureText: _obscurePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: const TextStyle(color: Colors.black),
                        decoration:
                            _inputDecoration(
                              'Password',
                              'Enter your password',
                              HugeIconsSolid.lockPassword,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? HugeIconsSolid.viewOff
                                      : HugeIconsSolid.eye,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Password is required";
                          final passRegex = RegExp(
                            r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
                          );
                          if (!passRegex.hasMatch(value)) {
                            return "Password must be 8+ chars w/ upper, lower, digit, special char";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _inputDecoration(
                          'Phone',
                          'Enter your phone no',
                          HugeIconsSolid.smartPhone01,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Phone number is required";
                          final phoneRegex = RegExp(
                            r"^(?:\+92|0092|92)?3[0-9]{9}$",
                          );
                          if (!phoneRegex.hasMatch(value))
                            return "Enter a valid Pakistani phone number";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Address
                      TextFormField(
                        controller: addressController,
                        keyboardType: TextInputType.text,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _inputDecoration(
                          'Address',
                          'Enter your address',
                          HugeIconsSolid.mapsLocation01,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return "Address is required";
                          final addressRegex = RegExp(
                            r"^[A-Za-z0-9\s,.\-\/]{5,}$",
                          );
                          if (!addressRegex.hasMatch(value))
                            return "Enter your valid address";
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final userCredential = await _auth
                                  .createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passController.text.trim(),
                                  );

                              final user = userCredential.user;

                              if (user != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .set({
                                      'name': nameController.text.trim(),
                                      'email': emailController.text.trim(),
                                      'role': "User",
                                      'phone': phoneController.text.trim(),
                                      'address': addressController.text.trim(),
                                      'uid': user.uid,
                                      'profile_image_url': '',
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });

                                // Clear form
                                nameController.clear();
                                emailController.clear();
                                passController.clear();
                                phoneController.clear();
                                addressController.clear();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("SignUp Successful")),
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignIn(),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Sign up failed: No user returned",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint("Error during sign up: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Sign up failed: $e")),
                              );
                            }
                          },
                          child: const Text('Sign Up'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: AppTheme.textLabel(context),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignIn(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign In",
                              style: AppTheme.textSearchInfoLabeled(context).copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    );
  }
}
