import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class LoadingLogo extends StatefulWidget {
  final double size;

  const LoadingLogo({super.key, this.size = 100});

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _flipAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // 👈 Makes this widget take up all vertical space in parent
      child: Center(
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value),
              child: child,
            );
          },
          child: Image.asset(
            AppTheme.appLogo(context),
            width: widget.size,
            height: widget.size,
          ),
        ),
      ),
    );
  }
}
