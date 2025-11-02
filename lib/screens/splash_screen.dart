import 'package:flutter/material.dart';
import '/screens/dashboard_screen.dart';
import '/utils/session_manager.dart';
import '../theme/theme.dart';
// For advanced animations

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.nextScreen,
    this.duration = const Duration(seconds: 3),
  });

  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    Future.delayed(widget.duration, () async {
      await _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    final remember = await SessionManager.getRememberMe();
    final token = await SessionManager.getUserToken();
    final user = await SessionManager.getUser();

    if (!mounted) return;

    if (remember && token != null && user != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(seconds: 1),
          pageBuilder: (_, __, ___) => DashboardScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(seconds: 1),
          pageBuilder: (_, __, ___) => widget.nextScreen,
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Option 1: Animated logo with scale and fade
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  AppTheme.appLogo(context),
                  width: 160,
                  height: 160,
                ),
              ),
            ),

            // const SizedBox(height: 30),

            // Option 2: Lottie animation
            // Lottie.asset(
            //   'assets/animations/splash_animation.json',
            //   width: 300,
            //   height: 300,
            //   fit: BoxFit.contain,
            // ),
          ],
        ),
      ),
    );
  }
}
