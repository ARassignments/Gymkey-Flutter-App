import 'package:flutter/material.dart';

class LoginFailDialog extends StatelessWidget {
  const LoginFailDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.red, Colors.redAccent],
                  ),
                ),
                child: const Icon(Icons.close, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Login Failed",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showLoginFailDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const LoginFailDialog(),
  );

  // Automatically close the dialog after 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    Navigator.of(context).pop(); // Close dialog
  });
}
