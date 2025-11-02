import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/theme.dart';

class NotFoundWidget extends StatelessWidget {
  final String title;
  final String message;

  const NotFoundWidget({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppTheme.notFoundImage(context),
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: AppTheme.textTitle(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.textSearchInfo(
              context,
            ).copyWith(fontSize: 10, fontFamily: AppFontFamily.poppinsRegular),
          ),
        ],
      ),
    );
  }
}
