import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/screens/login_screen.dart';
import '/screens/splash_screen.dart';
import '/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await ThemeController.loadTheme();
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
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory, // removes ripple globally
            highlightColor: Colors.transparent, // removes highlight globally
            splashColor: Colors.transparent, // removes splash globally
            hoverColor: Colors.transparent,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColor.white,
            inputDecorationTheme: AppInputDecoration.inputDecorationTheme(
              false,
            ),
            iconTheme: IconThemeData(color: AppColor.neutral_10),
            primaryColor: AppColor.black,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            splashFactory: NoSplash.splashFactory, // removes ripple globally
            highlightColor: Colors.transparent, // removes highlight globally
            splashColor: Colors.transparent, // removes splash globally
            hoverColor: Colors.transparent,
            // brightness: Brightness.light,
            // scaffoldBackgroundColor: AppColor.white,
            // inputDecorationTheme: AppInputDecoration.inputDecorationTheme(false),
            iconTheme: IconThemeData(color: AppColor.neutral_70),
            primaryColor: AppColor.black,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColor.neutral_100,
            inputDecorationTheme: AppInputDecoration.inputDecorationTheme(true),
          ),
          themeMode: themeMode, // 👈 controlled by ThemeController
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
          home: SplashScreen(
            nextScreen: const LoginScreen(),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }
}