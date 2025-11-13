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
      Future.delayed(Duration(seconds: 7), () {
        if (!mounted) return; // ✅ check before navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      });
    } else {
      Future.delayed(Duration(seconds: 7), () {
        if (!mounted) return; // ✅ check before navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnBoarding()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/Splash_Screen.json', fit: BoxFit.cover, width: double.infinity, alignment: Alignment.bottomCenter),
      ),
    );
  }
}
