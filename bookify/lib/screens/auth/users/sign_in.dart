import '/components/appsnackbar.dart';
import '/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/dashboard_screen.dart';
import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/screens/admin/screens/dashboard.dart';
import '/screens/auth/users/forgetpass.dart';
import '/screens/auth/users/sign_up.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignIn extends ConsumerStatefulWidget {
  const SignIn({super.key});

  @override
  ConsumerState<SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<SignIn> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithEmailAndPassword() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1️⃣ Clear Old User Data
        ref.read(userProvider.notifier).clearUser();

        // 2️⃣ Firebase Sign In
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // 3️⃣ Fetch User Document
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            await _auth.signOut();
            AppSnackBar.show(
              context,
              message: "User record not found",
              type: AppSnackBarType.error,
            );
            return;
          }

          final data = userDoc.data() as Map<String, dynamic>;

          // 4️⃣ Check user blocked
          if (data['enabled'] == false) {
            await _auth.signOut();
            AppSnackBar.show(
              context,
              message: "This user is blocked by admin",
              type: AppSnackBarType.error,
            );
            return;
          }

          // 5️⃣ Important — Fetch into Riverpod Provider
          await ref.read(userProvider.notifier).fetchUser();

          // 6️⃣ Navigate Based on Role
          final role = data['role'] ?? 'User';

          if (role == "User") {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => DashboardScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ),
            );
          } else if (role == "Admin") {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => Dashboard(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        AppSnackBar.show(
          context,
          message: _getErrorMessage(e),
          type: AppSnackBarType.error,
        );
        emailController.clear();
        passController.clear();
      } catch (e) {
        _showError("Error: $e");
        emailController.clear();
        passController.clear();
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Future<void> signInGoogle() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     final googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       setState(() => _isLoading = false);
  //       return;
  //     }

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;

  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     final UserCredential userCredential = await _auth.signInWithCredential(
  //       credential,
  //     );

  //     final User? user = userCredential.user;

  //     if (user != null) {
  //       await _handleGoogleUser(user);
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     _showError("Google sign in failed: ${_getErrorMessage(e)}");
  //   } catch (e) {
  //     _showError("Google sign in failed. Please try again.");
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _handleGoogleUser(User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // New user - create document
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName,
          'photoUrl': user.photoURL,
          'role': 'User',
          'enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (userDoc.data()?['enabled'] == false) {
        await _auth.signOut();
        AppSnackBar.show(
          context,
          message: "This user is blocked by admin",
          type: AppSnackBarType.error,
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => DashboardScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    } catch (e) {
      _showError("Error setting up user account");
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
              AppTheme.appLogo(context),
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
                    children: [
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: _inputDecoration(
                          label: 'Email*',
                          hint: 'Enter your email',
                          icon: HugeIconsSolid.mail01,
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
                      TextFormField(
                        controller: passController,
                        obscureText: _obscurePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration:
                            _inputDecoration(
                              label: 'Password*',
                              hint: 'Enter your password',
                              icon: HugeIconsSolid.lockPassword,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? HugeIconsSolid.viewOff
                                      : HugeIconsSolid.eye,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
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
                            return "Password must be at least 8 chars (upper, lower, digit, special)";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgetPass(),
                                    ),
                                  ),
                            child: Text(
                              "Forget Password?",
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : signInWithEmailAndPassword,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    strokeCap: StrokeCap.round,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppTheme.dividerBg(context),
                              thickness: 1,
                              endIndent: 10,
                            ),
                          ),
                          Text(
                            'Or continue with',
                            style: AppTheme.textSearchInfo(
                              context,
                            ).copyWith(fontSize: 14),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppTheme.dividerBg(context),
                              thickness: 1,
                              indent: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTheme.textLabel(context),
                          ),
                          InkWell(
                            onTap: _isLoading
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => SignUp()),
                                  ),
                            child: Text(
                              "Sign Up",
                              style: AppTheme.textSearchInfoLabeled(
                                context,
                              ).copyWith(fontSize: 14),
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    );
  }
}
