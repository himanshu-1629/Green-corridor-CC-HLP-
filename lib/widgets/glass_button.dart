import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/design_tuning_controller.dart';

enum GlassButtonVariant {
  primary,   // Violet Dusk / Deep Violet glass with glow
  secondary, // Frosted Ivory / Peach glass with specular rim
  accent,    // Emerald / Cyan emergency priority glass
  ghost,     // Ultra-clean transparent glass
}

class GlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final String? label;
  final Widget? child;
  final GlassButtonVariant variant;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;

  const GlassButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.child,
    this.variant = GlassButtonVariant.primary,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.borderRadius = 50.0,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w700,
  });

  GlassButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required Widget label,
    this.variant = GlassButtonVariant.primary,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.borderRadius = 50.0,
    this.fontSize = 14.0,
    this.fontWeight = FontWeight.w700,
  })  : icon = icon,
        label = null,
        child = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            label,
          ],
        );

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final dt = DesignTuningController.instance;
    final isEnabled = widget.onPressed != null;

    // Palette & Colors based on Variant
    Color baseBg;
    Color endBg;
    Color borderColor;
    Color textColor;
    Color glowColor;

    switch (widget.variant) {
      case GlassButtonVariant.primary:
        baseBg = AppColors.deepViolet.withValues(alpha: _isHovered ? 0.92 : 0.82);
        endBg = AppColors.mutedBerry.withValues(alpha: _isHovered ? 0.85 : 0.70);
        borderColor = AppColors.warmPeach.withValues(alpha: _isHovered ? 0.85 : 0.45);
        textColor = AppColors.softIvory;
        glowColor = AppColors.deepViolet.withValues(alpha: _isHovered ? 0.45 : 0.25);
        break;
      case GlassButtonVariant.secondary:
        baseBg = Colors.white.withValues(alpha: _isHovered ? 0.65 : 0.45);
        endBg = AppColors.softIvory.withValues(alpha: _isHovered ? 0.45 : 0.25);
        borderColor = Colors.white.withValues(alpha: _isHovered ? 0.90 : 0.60);
        textColor = AppColors.deepViolet;
        glowColor = AppColors.warmPeach.withValues(alpha: _isHovered ? 0.35 : 0.15);
        break;
      case GlassButtonVariant.accent:
        baseBg = AppColors.emerald.withValues(alpha: _isHovered ? 0.92 : 0.80);
        endBg = const Color(0xFF047857).withValues(alpha: _isHovered ? 0.85 : 0.70);
        borderColor = const Color(0xFF6EE7B7).withValues(alpha: _isHovered ? 0.90 : 0.50);
        textColor = Colors.white;
        glowColor = AppColors.emerald.withValues(alpha: _isHovered ? 0.50 : 0.25);
        break;
      case GlassButtonVariant.ghost:
        baseBg = Colors.white.withValues(alpha: _isHovered ? 0.25 : 0.12);
        endBg = Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.04);
        borderColor = Colors.white.withValues(alpha: _isHovered ? 0.60 : 0.25);
        textColor = AppColors.softIvory;
        glowColor = Colors.white.withValues(alpha: _isHovered ? 0.20 : 0.05);
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.025 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: _isHovered ? 24 : 14,
                  offset: Offset(0, _isHovered ? 8 : 4),
                  spreadRadius: _isHovered ? 2 : 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: dt.glassBlur * 0.9,
                  sigmaY: dt.glassBlur * 0.9,
                ),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [baseBg, endBg],
                    ),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: borderColor,
                      width: _isHovered ? 1.5 : 1.2,
                    ),
                  ),
                  child: widget.child ??
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 8),
                          ],
                          if (widget.label != null)
                            Text(
                              widget.label!,
                              style: GoogleFonts.plusJakartaSans(
                                color: textColor,
                                fontSize: widget.fontSize,
                                fontWeight: widget.fontWeight,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
