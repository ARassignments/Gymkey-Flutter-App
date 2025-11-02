import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/theme/theme.dart';

enum AppSnackBarType { success, error, warning, info }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final capitalizedMessage = message
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _AnimatedSnackBar(
        message: capitalizedMessage,
        type: type,
        onDismissed: () => entry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }
}

class _AnimatedSnackBar extends StatefulWidget {
  final String message;
  final AppSnackBarType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AnimatedSnackBar({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<_AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      _controller.reverse().then((_) => widget.onDismissed());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get backgroundColor {
    switch (widget.type) {
      case AppSnackBarType.success:
        return Colors.green;
      case AppSnackBarType.error:
        return Colors.redAccent;
      case AppSnackBarType.warning:
        return Colors.orange;
      case AppSnackBarType.info:
        return Colors.blueAccent;
    }
  }

  IconData get icon {
    switch (widget.type) {
      case AppSnackBarType.success:
        return HugeIconsSolid.checkmarkCircle01;
      case AppSnackBarType.error:
        return HugeIconsSolid.alert01;
      case AppSnackBarType.warning:
        return HugeIconsSolid.alert01;
      case AppSnackBarType.info:
        return HugeIconsSolid.informationCircle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 30,
      right: 30,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            elevation: 0,
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppTheme.textLabel(
                        context,
                      ).copyWith(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
