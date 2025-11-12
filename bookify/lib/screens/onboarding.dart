import 'package:bookify/screens/auth/users/sign_in.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/constants/sizes.dart';
import 'package:bookify/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:flutter/material.dart';

class OnBoarding extends StatelessWidget {
  const OnBoarding({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: MyColors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          /// Top Image
          Positioned(
            top: 100,
            left: screenWidth * 0.1,
            child: Container(
              width: screenWidth * 0.8,
              height: screenHeight * 0.5,
              child: Image.asset('assets/images/logo222.png'),
            ),
          ),

          /// Bottom Text Container (slightly overlapping)
          Positioned(
            top: screenHeight * 0.52,
            left: screenWidth * 0.08,
            child: Container(
              width: screenWidth * 0.84,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: MyColors.white,
                borderRadius: BorderRadius.circular(fSizes.borderRadiusLg),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Centered Title
                  Text(
                    'Shop Everything You Need',
                    textAlign: TextAlign.center,
                    style: MyTextTheme.lightTextTheme.headlineMedium,
                  ),

                  SizedBox(height: 16),

                  /// Centered Subtitle
                  Text(
                    'From protein powders to dumbbells, find everything to reach your goals',
                    textAlign: TextAlign.center,
                    style: MyTextTheme.lightTextTheme.bodySmall,
                  ),

                  SizedBox(height: 24),

                  /// Centered Button
                  SizedBox(
                    width: screenWidth * 0.6,
                    child: ElevatedButtonTheme(
                      data: MyElevatedButtonTheme.lightElevatedButtonTheme,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignIn()),
                          );
                        },
                        child: Text('Continue'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
