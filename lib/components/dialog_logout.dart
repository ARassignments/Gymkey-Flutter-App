import 'package:flutter/material.dart';
import '../theme/theme.dart';

class DialogLogout {
  void showDialog(BuildContext context, VoidCallback onLogout) {
    showModalBottomSheet(
      showDragHandle: true,
      isScrollControlled: true,
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: Wrap(
            children: [
              Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Logout",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(context).copyWith(
                      fontSize: 16,
                      fontFamily: AppFontFamily.poppinsBold,
                    ),
                  ),
                  const Divider(),
                  Text(
                    "Are you sure you want to log out?",
                    textAlign: TextAlign.center,
                    style: AppTheme.textLabel(context),
                  ),
                  OutlineErrorButton(
                    text: "Yes, Logout",
                    onPressed: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                  FlatButton(
                    text: "Cancel",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
