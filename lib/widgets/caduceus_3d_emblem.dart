// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Conditional web platform import
import 'caduceus_3d_emblem_web.dart'
    if (dart.library.io) 'caduceus_3d_emblem_stub.dart' as platform_impl;

/// Three-Dimensional Medical Emblem (Caduceus)
/// Rendered using an embedded Three.js WebGL PBR viewport on web, with
/// an immediate layered dimensional vector sculpture as fallback.
class Caduceus3DEmblem extends StatefulWidget {
  final double size;
  final bool enableInteractiveTilt;
  final double scrollProgress;
  final double opacity;
  final VoidCallback? onTap;

  const Caduceus3DEmblem({
    super.key,
    this.size = 380,
    this.enableInteractiveTilt = true,
    this.scrollProgress = 0.0,
    this.opacity = 1.0,
    this.onTap,
  });

  @override
  State<Caduceus3DEmblem> createState() => _Caduceus3DEmblemState();
}

class _Caduceus3DEmblemState extends State<Caduceus3DEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverAnimController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _hoverAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    if (kIsWeb) {
      platform_impl.updateCaduceusScroll(widget.scrollProgress, opacity: widget.opacity);
    }
  }

  @override
  void didUpdateWidget(covariant Caduceus3DEmblem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.scrollProgress != oldWidget.scrollProgress || widget.opacity != oldWidget.opacity) && kIsWeb) {
      platform_impl.updateCaduceusScroll(widget.scrollProgress, opacity: widget.opacity);
    }
  }

  @override
  void dispose() {
    _hoverAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.size;

    return MouseRegion(
      onHover: (event) {
        if (!widget.enableInteractiveTilt) return;
        final size = context.size;
        if (size == null || size.width == 0 || size.height == 0) return;
        setState(() {
          _tiltX = ((event.localPosition.dx / size.width) - 0.5) * 0.35;
          _tiltY = -((event.localPosition.dy / size.height) - 0.5) * 0.25;
        });
      },
      onExit: (_) {
        setState(() {
          _tiltX = 0.0;
          _tiltY = 0.0;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Primary 3D WebGL / Native Emblem with Scroll-Linked Rotation
              AnimatedBuilder(
                animation: _hoverAnimController,
                builder: (context, _) {
                  final t = _hoverAnimController.value;
                  final floatY = math.sin(t * math.pi * 2) * 5.0;

                  // Continuous rotation tied to scroll progress (reverses on scroll up)
                  final scrollRotY = widget.scrollProgress * math.pi * 1.6;
                  final scrollTiltX = widget.scrollProgress * 0.22;
                  final scrollScale = (1.0 - widget.scrollProgress * 0.12).clamp(0.78, 1.0);

                  if (kIsWeb) {
                    // On Web: Translate and subtle float/scale. The Three.js WebGL canvas
                    // inside the iframe performs true 3D rotation via postMessage.
                    // DO NOT rotate the iframe container in CSS 3D space, which would flatten it into an edge-on strip.
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(0.0, floatY - (widget.scrollProgress * 16.0))
                        ..scale(scrollScale),
                      child: platform_impl.buildCaduceusWebPlatformView(s, s),
                    );
                  }

                  // Non-web / Mobile fallback: custom painter with 3D matrix transform
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..translate(0.0, floatY - (widget.scrollProgress * 16.0))
                      ..scale(scrollScale)
                      ..rotateY(_tiltX + scrollRotY + math.sin(t * math.pi) * 0.04)
                      ..rotateX(_tiltY + scrollTiltX),
                    child: CustomPaint(
                      size: Size(s, s),
                      painter: CaduceusSculptedVectorPainter(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback / Mobile Native Layered 3D Vector Sculpture of Caduceus
class CaduceusSculptedVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);

    // Coordinate transforms normalized around center
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final double scale = w / 340.0;
    canvas.scale(scale);

    // 0. Contact ambient occlusion shadow on white canvas
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 155), width: 230, height: 42),
      Paint()
        ..color = AppColors.nearBlack.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // ------------------------------------------------------------
    // A. SYMMETRICAL WINGS (MULTI-FEATHERED)
    // ------------------------------------------------------------
    _drawWing(canvas, isRight: false);
    _drawWing(canvas, isRight: true);

    // ------------------------------------------------------------
    // B. CENTRAL METALLIC STAFF & FINIAL ORB
    // ------------------------------------------------------------
    final staffPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.brown,
          AppColors.greyLight,
          AppColors.white,
          AppColors.nearBlack,
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(const Rect.fromLTWH(-10, -110, 20, 220));

    // Shaft
    final staffPath = Path()
      ..moveTo(-7, -70)
      ..lineTo(7, -70)
      ..lineTo(4, 95)
      ..lineTo(-4, 95)
      ..close();
    canvas.drawPath(staffPath, staffPaint);

    // Lower tapered tip
    final tipPath = Path()
      ..moveTo(-4, 95)
      ..lineTo(4, 95)
      ..lineTo(0, 115)
      ..close();
    canvas.drawPath(tipPath, staffPaint);

    // Collar under orb
    final collarPaint = Paint()..color = AppColors.orange;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -78, 22, 9),
        const Radius.circular(3),
      ),
      collarPaint,
    );

    // Crowning Orb (Finial Sphere with 3D radial specular highlight)
    final orbPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.35, -0.4),
        radius: 0.9,
        colors: [
          AppColors.white,
          AppColors.greyLight,
          AppColors.brown,
          AppColors.nearBlack,
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: const Offset(0, -92), radius: 22));
    canvas.drawCircle(const Offset(0, -92), 19, orbPaint);

    // ------------------------------------------------------------
    // C. TWO INTERTWINED SERPENTS (DOUBLE HELIX)
    // ------------------------------------------------------------
    _drawSerpents(canvas);

    canvas.restore();
  }

  void _drawWing(Canvas canvas, {required bool isRight}) {
    final double sign = isRight ? 1 : -1;

    // Layered feathers (primary to tertiary)
    final feathers = [
      // {start, ctrl1, ctrl2, end, width}
      [Offset(sign * 14, -65), Offset(sign * 70, -115), Offset(sign * 125, -95), Offset(sign * 145, -70)],
      [Offset(sign * 14, -50), Offset(sign * 75, -95), Offset(sign * 125, -75), Offset(sign * 138, -48)],
      [Offset(sign * 14, -35), Offset(sign * 70, -75), Offset(sign * 115, -55), Offset(sign * 124, -28)],
      [Offset(sign * 14, -20), Offset(sign * 65, -55), Offset(sign * 100, -35), Offset(sign * 108, -10)],
      [Offset(sign * 14, -5), Offset(sign * 55, -35), Offset(sign * 85, -15), Offset(sign * 88, 8)],
      [Offset(sign * 14, 10), Offset(sign * 45, -15), Offset(sign * 68, 2), Offset(sign * 70, 22)],
    ];

    for (int i = 0; i < feathers.length; i++) {
      final f = feathers[i];
      final path = Path()..moveTo(f[0].dx, f[0].dy);
      path.cubicTo(f[1].dx, f[1].dy, f[2].dx, f[2].dy, f[3].dx, f[3].dy);
      // Return curve to give feather volume
      path.cubicTo(
        f[2].dx - sign * 14,
        f[2].dy + 14,
        f[1].dx - sign * 8,
        f[1].dy + 12,
        f[0].dx,
        f[0].dy + 8,
      );
      path.close();

      // Dimensional metallic feather gradient
      final featherPaint = Paint()
        ..shader = LinearGradient(
          begin: isRight ? Alignment.topLeft : Alignment.topRight,
          end: isRight ? Alignment.bottomRight : Alignment.bottomLeft,
          colors: [
            Colors.white,
            AppColors.greyLight,
            AppColors.brown.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(path.getBounds());

      canvas.drawPath(path, featherPaint);

      // Feather spine highlight
      final spinePaint = Paint()
        ..color = (i == 0 ? AppColors.orange : Colors.white).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      final spine = Path()..moveTo(f[0].dx, f[0].dy);
      spine.cubicTo(f[1].dx, f[1].dy, f[2].dx, f[2].dy, f[3].dx, f[3].dy);
      canvas.drawPath(spine, spinePaint);
    }
  }

  void _drawSerpents(Canvas canvas) {
    // Left & Right intertwined serpentine curves
    final serpentPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.orange,
          AppColors.orangeDark,
          AppColors.brown,
          AppColors.nearBlack,
        ],
      ).createShader(const Rect.fromLTWH(-40, -60, 80, 160))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Serpent 1 (Left to Right intertwining helix)
    final path1 = Path()
      ..moveTo(0, 88)
      ..cubicTo(-28, 70, -32, 50, -4, 32)
      ..cubicTo(26, 14, 28, -6, 0, -24)
      ..cubicTo(-26, -42, -24, -58, -12, -64);
    canvas.drawPath(path1, serpentPaint);

    // Serpent 2 (Right to Left intertwining helix)
    final path2 = Path()
      ..moveTo(0, 88)
      ..cubicTo(28, 70, 32, 50, 4, 32)
      ..cubicTo(-26, 14, -28, -6, 0, -24)
      ..cubicTo(26, -42, 24, -58, 12, -64);
    canvas.drawPath(path2, serpentPaint);

    // Serpent Heads facing inward at top
    final headPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        colors: [AppColors.white, AppColors.orange, AppColors.brown],
      ).createShader(const Rect.fromLTWH(-20, -74, 40, 20));

    // Left Head
    final leftHead = Path()
      ..moveTo(-12, -64)
      ..lineTo(-18, -69)
      ..lineTo(-8, -73)
      ..lineTo(-5, -67)
      ..close();
    canvas.drawPath(leftHead, headPaint);

    // Right Head
    final rightHead = Path()
      ..moveTo(12, -64)
      ..lineTo(18, -69)
      ..lineTo(8, -73)
      ..lineTo(5, -67)
      ..close();
    canvas.drawPath(rightHead, headPaint);

    // Jewel eyes on serpent heads (Orange faceted highlight)
    final eyePaint = Paint()..color = AppColors.orange;
    canvas.drawCircle(const Offset(-11, -69), 1.6, eyePaint);
    canvas.drawCircle(const Offset(11, -69), 1.6, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
