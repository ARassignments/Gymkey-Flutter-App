import '/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/services.dart';
import '/screens/cart.dart';
import '/screens/catalog.dart';
import '/screens/categories/action_page.dart';
import '/screens/categories/fantasy_page.dart';
import '/screens/categories/history_page.dart';
import '/screens/categories/novels_page.dart';
import '/screens/categories/poetry_page.dart';
import '/screens/categories/romance_page.dart';
import '/screens/categories/science_page.dart';
import '/screens/categories/self_love_page.dart';
import '/screens/home.dart';
import '/screens/profile.dart';
import '/screens/splashscreen.dart';
import '/screens/wishlist.dart';
import '/screens/admin/screens/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '/utils/themes/themes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ThemeController.loadTheme();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://gnuysoelfiqurqlhcmrt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdudXlzb2VsZmlxdXJxbGhjbXJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA3NjkzMzAsImV4cCI6MjA2NjM0NTMzMH0.PT_UHlxC_yXfHwiT6v5MXYZaf34EGvcZ3POC6vNlGxk',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          title: 'GymKey',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: MyTheme.lightTheme,
          darkTheme: MyTheme.darkTheme,
          initialRoute: '/',
          routes: {
            '/home': (context) => const DashboardScreen(),
            '/catalog': (context) => const CatalogScreen(),
            '/cart': (context) => const CartScreen(),
            '/wishlist': (context) => const WishListScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/novels': (context) => const NovelsPage(),
            '/self-love': (context) => const SelfLovePage(),
            '/science': (context) => const SciencePage(),
            '/romance': (context) => const RomancePage(),
            '/history': (context) => const HistoryPage(),
            '/fantasy': (context) => const FantasyPage(),
            '/poetry': (context) => const PoetryPage(),
            '/action': (context) => const ActionPage(),
          },
          builder: (context, child) {
            return ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 500) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: child,
                      ),
                    );
                  } else {
                    return child!;
                  }
                },
              ),
            );
          },
          home: FutureBuilder<String?>(
            future: _checkUserRole(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SplashScreen(); // Show SplashScreen while waiting for user role
              } else if (snapshot.hasError) {
                print("Error during role check: ${snapshot.error}");
                return SplashScreen();
              } else if (snapshot.hasData) {
                String? role = snapshot.data;
                final user = fb_auth.FirebaseAuth.instance.currentUser;
                print("Firebase UID: ${user?.uid}");

                if (role == "Admin") {
                  // Use WidgetsBinding to trigger navigation after widget has been built
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => Dashboard(),
                        transitionsBuilder: (_, a, __, c) =>
                            FadeTransition(opacity: a, child: c),
                      ),
                      (route) => false,
                    );
                  });
                  return const SizedBox(); // Return empty widget until navigation happens
                } else if (role == "User") {
                  // Use WidgetsBinding to trigger navigation after widget has been built
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => DashboardScreen(),
                        transitionsBuilder: (_, a, __, c) =>
                            FadeTransition(opacity: a, child: c),
                      ),
                      (route) => false,
                    );
                  });

                  return const SizedBox(); // Return empty widget until navigation happens
                } else {
                  // Fallback if no role found
                  return SplashScreen();
                }
              } else {
                return SplashScreen(); // Fallback if no data
              }
            },
          ),
        );
      },
    );
  }

  Future<String?> _checkUserRole() async {
    fb_auth.User? user = fb_auth.FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("Logged-in user UID: ${user.uid}");
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        print("User role: ${userDoc['role']}");
        return userDoc['role'];
      } else {
        print("User document does not exist");
      }
    } else {
      print("No user logged in");
    }

    return null;
  }
}
