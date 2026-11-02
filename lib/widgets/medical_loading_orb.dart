import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Dimensional Animated Medical Loading Orb
/// A custom 3D spherical medical coordination orb with layered specular highlights,
/// rotating orbital telemetry rings, and pulsating transit signal nodes.
class MedicalLoadingOrb extends StatefulWidget {
  final double size;
  final String? statusMessage;
  final double? progress; // 0.0 to 1.0, null for indeterminate

  const MedicalLoadingOrb({
    super.key,
    this.size = 80,
    this.statusMessage,
    this.progress,
  });

  @override
  State<MedicalLoadingOrb> createState() => _MedicalLoadingOrbState();
}

class _MedicalLoadingOrbState extends State<MedicalLoadingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: s,
          height: s,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(s, s),
                painter: _SphericalOrbPainter(
                  animationValue: _animController.value,
                  progress: widget.progress,
                ),
              );
            },
          ),
        ),
        if (widget.statusMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.statusMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.nearBlackMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _SphericalOrbPainter extends CustomPainter {
  final double animationValue;
  final double? progress;

  _SphericalOrbPainter({
    required this.animationValue,
    this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double orbRadius = radius * 0.76;

    // 1. Soft bottom contact shadow
    final shadowRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + orbRadius * 0.95),
      width: orbRadius * 1.5,
      height: orbRadius * 0.32,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = AppColors.nearBlack.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // 2. Ambient radial backlight in brand Orange/Brown
    final ambientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.orange.withValues(alpha: 0.22),
          AppColors.brown.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, ambientPaint);

    // 3. Spherical Dimensional Core (Key light at top-left)
    final sphereRect = Rect.fromCircle(center: center, radius: orbRadius);
    final coreGradient = RadialGradient(
      center: const Alignment(-0.35, -0.38),
      radius: 0.95,
      colors: const [
        AppColors.white,
        AppColors.greyLight,
        AppColors.brown,
        AppColors.nearBlack,
      ],
      stops: const [0.0, 0.32, 0.72, 1.0],
    );
    final spherePaint = Paint()..shader = coreGradient.createShader(sphereRect);
    canvas.drawCircle(center, orbRadius, spherePaint);

    // Clip to spherical boundary for inner 3D lattice
    canvas.save();
    canvas.clipPath(Path()..addOval(sphereRect));

    // 4. Rotating 3D Internal Transit Grid Rings (Orange telemetry lines)
    final ringPaint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final brightRingPaint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final double rotAngle = animationValue * math.pi * 2;

    // Draw 3 tilted orbital rings revolving around sphere
    for (int i = 0; i < 3; i++) {
      final double phase = rotAngle + (i * math.pi / 1.5);
      final double widthFactor = math.cos(phase);
      final double currentWidth = (orbRadius * 0.88 * widthFactor.abs()).clamp(1.0, orbRadius * 0.88);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-math.pi / 6 + (i * 0.22));

      final ellipseRect = Rect.fromCenter(
        center: Offset.zero,
        width: currentWidth * 2,
        height: orbRadius * 1.6,
      );

      // Only draw with full brightness if facing front
      if (widthFactor >= 0) {
        canvas.drawOval(ellipseRect, brightRingPaint);
        // Add animated traveling signal node
        final double nodeT = (animationValue * 2 + (i * 0.33)) % 1.0;
        final double nodeAngle = nodeT * math.pi * 2;
        final double nodeX = math.cos(nodeAngle) * currentWidth;
        final double nodeY = math.sin(nodeAngle) * (orbRadius * 0.8);
        canvas.drawCircle(
          Offset(nodeX, nodeY),
          2.6,
          Paint()..color = AppColors.white,
        );
        canvas.drawCircle(
          Offset(nodeX, nodeY),
          4.5,
          Paint()..color = AppColors.orange.withValues(alpha: 0.6),
        );
      } else {
        canvas.drawOval(ellipseRect, ringPaint);
      }
      canvas.restore();
    }

    // Horizontal equator pulse ring
    final equatorRect = Rect.fromCenter(
      center: center,
      width: orbRadius * 1.85,
      height: orbRadius * 0.45,
    );
    canvas.drawOval(
      equatorRect,
      Paint()
        ..color = AppColors.orange.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 5. Directional Surface Specular Crescent (Gloss sheen)
    final glossRect = Rect.fromCircle(
      center: Offset(center.dx - orbRadius * 0.26, center.dy - orbRadius * 0.28),
      radius: orbRadius * 0.42,
    );
    final glossPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.82),
          Colors.white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(glossRect);
    canvas.drawOval(glossRect, glossPaint);

    canvas.restore(); // Restore clip

    // 6. External Rim Highlight Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.8),
          AppColors.orange.withValues(alpha: 0.6),
          AppColors.brown.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(sphereRect);
    canvas.drawCircle(center, orbRadius, rimPaint);

    // 7. Deterministic progress arc if provided
    if (progress != null) {
      final double p = progress!.clamp(0.0, 1.0);
      final progressRect = Rect.fromCircle(center: center, radius: orbRadius + 4);
      final progressPaint = Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(progressRect, -math.pi / 2, p * math.pi * 2, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SphericalOrbPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.progress != progress;
  }
}
