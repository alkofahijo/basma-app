import 'dart:math';

import 'package:flutter/material.dart';
import 'package:basma_app/theme/app_colors.dart';
import 'package:basma_app/widgets/app_logo.dart';

class LoadingCenter extends StatefulWidget {
  const LoadingCenter({super.key});

  @override
  State<LoadingCenter> createState() => _LoadingCenterState();
}

class _LoadingCenterState extends State<LoadingCenter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F1),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final boxSize = min(150.0, screenWidth * 0.5);

            return SizedBox(
              width: boxSize,
              height: boxSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // keep logo relative to the box size
                  AppLogo(sizeFactor: boxSize / (screenWidth * 8)),

                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, child) {
                      return Transform.rotate(
                        angle: _controller.value * 6.28318,
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      size: Size(boxSize, boxSize),
                      painter: _CirclePainter(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const primaryColor = kPrimaryColor;

    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawArc(rect, 0, 3.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
