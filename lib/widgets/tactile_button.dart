import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum TactileButtonVariant {
  primary,   // Tactile Orange base with White text and specular metallic rim
  secondary, // Pure White base with Near-black text and crisp tactile drop shadow
  accent,    // Near-black base with Orange rim and White text
  berry,     // Rich Brown base with White text and Orange specular accent
}

/// A genuinely skeuomorphic physical button widget.
/// Features:
/// - Real physical elevation with directional drop shadow and bevel highlights.
/// - Interactive hover lift with specular highlight expansion.
/// - Mechanical pressed-in state (elevation collapses, surface translates down).
/// - Full keyboard focus indicator and mobile touch responsiveness.
class TactileButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final dynamic icon; // Widget or IconData
  final String? label;
  final String? text;
  final Widget? child;
  final TactileButtonVariant variant;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isLoading;

  const TactileButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.text,
    this.child,
    this.variant = TactileButtonVariant.primary,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    this.borderRadius = 50.0,
    this.fontSize = 15.0,
    this.fontWeight = FontWeight.w600,
    this.isLoading = false,
  });

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    // Determine colors and gradients based on Neue Montreal 5-color palette
    List<Color> gradientColors;
    Color borderColor;
    Color textColor;
    Color shadowColor;
    Color highlightColor;

    switch (widget.variant) {
      case TactileButtonVariant.primary:
        // Orange tactile button
        gradientColors = _isPressed
            ? [AppColors.orangeDark, AppColors.orange]
            : _isHovered
                ? [const Color(0xFFFF8547), AppColors.orange]
                : [AppColors.orange, AppColors.orangeDark];
        borderColor = _isHovered ? Colors.white : const Color(0xFFFF9E6C);
        textColor = Colors.white;
        shadowColor = AppColors.orange.withValues(alpha: 0.35);
        highlightColor = Colors.white.withValues(alpha: 0.40);
        break;

      case TactileButtonVariant.secondary:
        // White light surface tactile button
        gradientColors = _isPressed
            ? [const Color(0xFFEDEDED), Colors.white]
            : _isHovered
                ? [Colors.white, const Color(0xFFFAFAFA)]
                : [Colors.white, const Color(0xFFF2F2F2)];
        borderColor = _isHovered ? AppColors.orange : AppColors.greyLight;
        textColor = AppColors.nearBlack;
        shadowColor = AppColors.nearBlack.withValues(alpha: 0.10);
        highlightColor = Colors.white;
        break;

      case TactileButtonVariant.accent:
        // Near-black dark surface tactile button
        gradientColors = _isPressed
            ? [AppColors.nearBlackDark, AppColors.nearBlack]
            : _isHovered
                ? [AppColors.nearBlackLight, AppColors.nearBlack]
                : [AppColors.nearBlackLight, AppColors.nearBlackDark];
        borderColor = _isHovered ? AppColors.orange : AppColors.brown.withValues(alpha: 0.50);
        textColor = Colors.white;
        shadowColor = Colors.black.withValues(alpha: 0.45);
        highlightColor = Colors.white.withValues(alpha: 0.15);
        break;

      case TactileButtonVariant.berry:
        // Rich Brown tactile button
        gradientColors = _isPressed
            ? [AppColors.brownDark, AppColors.brown]
            : _isHovered
                ? [AppColors.brownLight, AppColors.brown]
                : [AppColors.brown, AppColors.brownDark];
        borderColor = _isHovered ? AppColors.orange : AppColors.brownLight;
        textColor = Colors.white;
        shadowColor = AppColors.brownDark.withValues(alpha: 0.40);
        highlightColor = Colors.white.withValues(alpha: 0.20);
        break;
    }

    // Skeuomorphic shadow calculations
    final double elevationOffset = _isPressed ? 1.0 : (_isHovered ? 7.0 : 4.0);
    final double elevationBlur = _isPressed ? 3.0 : (_isHovered ? 18.0 : 12.0);

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) {
            if (isEnabled) setState(() => _isPressed = true);
          },
          onTapUp: (_) {
            if (isEnabled) setState(() => _isPressed = false);
          },
          onTapCancel: () {
            if (isEnabled) setState(() => _isPressed = false);
          },
          onTap: isEnabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              // ignore: deprecated_member_use
              ..translate(0.0, _isPressed ? 2.5 : (_isHovered ? -1.5 : 0.0)),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isFocused ? AppColors.orange : borderColor,
                width: _isFocused ? 2.0 : 1.4,
              ),
              boxShadow: [
                // Directional tactile drop shadow
                BoxShadow(
                  color: shadowColor,
                  offset: Offset(0, elevationOffset),
                  blurRadius: elevationBlur,
                  spreadRadius: _isHovered ? 1.0 : 0.0,
                ),
                // Top specular highlight (bevel reflection)
                if (!_isPressed)
                  BoxShadow(
                    color: highlightColor,
                    offset: const Offset(0, -1),
                    blurRadius: 1,
                  ),
                // Soft bottom rim bevel reflection
                if (!_isPressed && widget.variant == TactileButtonVariant.primary)
                  BoxShadow(
                    color: AppColors.orangeDark.withValues(alpha: 0.50),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: widget.padding,
                child: widget.child ??
                    (widget.isLoading
                        ? SizedBox(
                            width: widget.fontSize + 4,
                            height: widget.fontSize + 4,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(textColor),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                if (widget.icon is Widget)
                                  widget.icon as Widget
                                else if (widget.icon is IconData)
                                  Icon(
                                    widget.icon as IconData,
                                    color: textColor,
                                    size: widget.fontSize + 3,
                                  ),
                                const SizedBox(width: 8),
                              ],
                              if (widget.label != null || widget.text != null)
                                Text(
                                  widget.label ?? widget.text!,
                                  style: TextStyle(
                                    fontFamily: 'NeueMontreal',
                                    color: textColor,
                                    fontSize: widget.fontSize,
                                    fontWeight: widget.fontWeight,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      if (widget.variant == TactileButtonVariant.primary ||
                                          widget.variant == TactileButtonVariant.berry ||
                                          widget.variant == TactileButtonVariant.accent)
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.30),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          )),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
