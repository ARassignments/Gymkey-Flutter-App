import '/dashboard_screen.dart';
import '/screens/home.dart';
import '/screens/onboarding.dart';
import '/utils/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user != null) {
      Future.delayed(Duration(seconds: 10), () {
        if (!mounted) return; // ✅ check before navigation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      });
    } else {
      Future.delayed(Duration(seconds: 10), () {
        if (!mounted) return; // ✅ check before navigation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
          (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/animations/Splash_Screen.json',
          fit: BoxFit.contain,
          repeat: false,
          width: double.infinity,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}
