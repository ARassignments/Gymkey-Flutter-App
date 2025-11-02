import 'package:flutter/material.dart';
import '../theme/theme.dart';

class EmailSentScreen extends StatefulWidget {
  final String email;
  const EmailSentScreen({super.key, required this.email});

  @override
  _EmailSentState createState() => _EmailSentState();
}

class _EmailSentState extends State<EmailSentScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String maskEmail(
      String email, {
      int visibleChars = 3,
      String maskChar = '*',
    }) {
      if (email.isEmpty) return email;

      final parts = email.split('@');
      if (parts.length != 2) return email;

      final name = parts[0];
      final domain = parts[1];

      final maskedName = name.length > visibleChars
          ? '${name.substring(0, visibleChars)}${maskChar * (name.length - visibleChars)}'
          : name;

      return '$maskedName@$domain';
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        AppTheme.appLogo(context),
                        height: 100,
                        width: 100,
                      ),
                      SizedBox(height: 40),
                      Text(
                        "Forget Password",
                        style: AppTheme.textTitle(context),
                      ),
                      SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          style: AppTheme.textLabel(context),
                          children: [
                            TextSpan(text: "We sent an email to "),
                            TextSpan(
                              text: maskEmail(widget.email),
                              style: AppTheme.textLink(context),
                            ),
                            TextSpan(
                              text:
                                  " with a link to get back into your account.",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      OutlineButton(
                        text: 'Cancel',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
