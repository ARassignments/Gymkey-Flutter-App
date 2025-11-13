import 'package:bookify/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '/screens/auth/users/sign_in.dart';
import '/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/utils/constants/colors.dart';
import '/utils/themes/custom_themes/text_theme.dart';

class ForgetPass extends StatefulWidget {
  const ForgetPass({super.key});

  @override
  State<ForgetPass> createState() => _ForgetPassState();
}

class _ForgetPassState extends State<ForgetPass> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(HugeIconsSolid.arrowLeft01,),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Forgot Password",
                        style: AppTheme.textTitle(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              /// Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.customListBg(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.iconColorTwo(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "We will send the OTP code to your email for security in forgetting your password",
                        style: AppTheme.textSearchInfo(context).copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              /// Label
              Text(
                "E-mail",
                style: AppTheme.textLabel(context).copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),

              /// Email Input
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    prefixIcon: Icon(HugeIconsSolid.mail01),
                    labelText: "Email Address*",
                    hintText: "Shariq@gmail.com",
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
              ),

              const Spacer(),

              /// Submit Button
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _auth.sendPasswordResetEmail(
                      email: emailController.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Email Send Successfully")),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignIn()),
                    );
                  }
                },
                child: const Text(
                  "Submit",
                  style: TextStyle(fontSize: 18, letterSpacing: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
