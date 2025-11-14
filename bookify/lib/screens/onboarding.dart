import '/screens/auth/users/sign_in.dart';
import '/utils/constants/sizes.dart';
import '/utils/themes/themes.dart';
import 'package:flutter/material.dart';

class OnBoarding extends StatelessWidget {
  const OnBoarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        spacing: 30,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Image.asset(AppTheme.appLogo(context))),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg(context),
              borderRadius: BorderRadius.circular(fSizes.borderRadiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// Centered Title
                Text(
                  'Shop Everything You Need',
                  textAlign: TextAlign.center,
                  style: AppTheme.textTitle(context).copyWith(fontSize: 20),
                ),

                SizedBox(height: 16),

                /// Centered Subtitle
                Text(
                  'From protein powders to dumbbells, find everything to reach your goals',
                  textAlign: TextAlign.center,
                  style: AppTheme.textSearchInfoLabeled(
                    context,
                  ).copyWith(fontSize: 13),
                ),

                SizedBox(height: 24),

                /// Centered Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => SignIn(),
                        transitionsBuilder: (_, a, __, c) =>
                            FadeTransition(opacity: a, child: c),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text('Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
