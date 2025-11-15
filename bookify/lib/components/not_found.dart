import '/utils/themes/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotFoundWidget extends StatelessWidget {
  final String title;
  final String message;
  final double size;

  const NotFoundWidget({
    super.key,
    required this.title,
    required this.message,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(AppTheme.notFoundImage(context), width: size),
          const SizedBox(height: 13),
          Text(
            title,
            style: AppTheme.textTitle(context).copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (message.isNotEmpty)
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.textSearchInfo(
                context,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }
}
