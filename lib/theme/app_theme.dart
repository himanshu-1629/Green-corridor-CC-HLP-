import 'package:flutter/material.dart';
import 'design_tuning_controller.dart';

// ============================================================
// NEUE MONTREAL BRAND DESIGN SYSTEM — GREEN CORRIDOR
// Five mandated brand colors:
// - Orange:      #FF6D29
// - Brown:       #453027
// - Near-black:  #161316
// - Grey:        #BABABA
// - White:       #FFFFFF
// ============================================================
class AppColors {
  // CORE FIVE BRAND COLORS
  static const Color orange     = Color(0xFFFF6D29); // Accent, tactical alert, primary call-to-action
  static const Color brown      = Color(0xFF453027); // Deep dimensional structure, secondary shadows
  static const Color nearBlack  = Color(0xFF161316); // High-contrast structural dark, titles & chassis
  static const Color grey       = Color(0xFFBABABA); // Subtle borders, secondary text, metallic bevels
  static const Color white      = Color(0xFFFFFFFF); // Canvas, light surfaces, specular highlights

  // TONAL VARIANTS & SURFACES
  static const Color nearBlackDark   = Color(0xFF0F0D0F);
  static const Color nearBlackLight  = Color(0xFF282328);
  static const Color nearBlackMuted  = Color(0xFF5A525A);

  static const Color brownDark       = Color(0xFF33231C);
  static const Color brownLight      = Color(0xFF6B4D3F);
  static const Color brownFaint      = Color(0xFFF7F2EF);

  static const Color orangeDark      = Color(0xFFD65213);
  static const Color orangeLight     = Color(0xFFFF8B54);
  static const Color orangeFaint     = Color(0xFFFFF0E8);

  static const Color greyDark        = Color(0xFF8F8F8F);
  static const Color greyLight       = Color(0xFFEBEBEB);
  static const Color greyFaint       = Color(0xFFF7F7F7);

  // BACKWARDS-COMPATIBILITY SYSTEM (mapped directly to Neue Montreal brand colors)
  static const Color deepViolet      = nearBlack;
  static const Color deepVioletDark  = nearBlackDark;
  static const Color deepVioletLight = nearBlackLight;
  static const Color deepVioletMuted = nearBlackMuted;

  static const Color mutedBerry      = brown;
  static const Color mutedBerryDark  = brownDark;
  static const Color mutedBerryLight = brownLight;
  static const Color mutedBerryFaint = brownFaint;

  static const Color warmPeach       = grey;
  static const Color warmPeachDark   = greyDark;
  static const Color warmPeachLight  = greyLight;
  static const Color warmPeachFaint  = greyFaint;

  static const Color softIvory       = white;
  static const Color softIvoryDark   = greyLight;
  static const Color softIvoryLight  = white;
  static const Color softIvoryBorder = greyLight;

  // LEGACY ALIASES
  static const Color navy         = nearBlack;
  static const Color cream        = white;
  static const Color sky          = orange;
  static const Color navyDark     = nearBlackDark;
  static const Color navyLight    = nearBlackLight;
  static const Color creamLight   = white;
  static const Color creamDark    = greyLight;
  static const Color skyLight     = orangeFaint;
  static const Color skyDark      = orangeDark;
  static const Color skyTint      = greyFaint;
  static const Color navyText     = nearBlack;
  static const Color navyMuted    = nearBlackMuted;
  static const Color borderLight  = greyLight;

  // SURFACE & CANVAS
  static const Color background       = white;
  static const Color surface          = white;
  static const Color surfaceElevated  = white;

  // SEMANTIC STATUS
  static const Color primary       = orange;
  static const Color primaryDark   = orangeDark;
  static const Color primaryLight  = orangeFaint;
  static const Color emerald       = Color(0xFF10B981);
  static const Color emeraldDark   = Color(0xFF059669);
  static const Color emeraldLight  = Color(0xFFD1FAE5);

  // NEUTRAL SCALE
  static const Color slate900 = nearBlack;
  static const Color slate800 = Color(0xFF221D22);
  static const Color slate700 = Color(0xFF3B333B);
  static const Color slate600 = Color(0xFF5A525A);
  static const Color slate500 = Color(0xFF7E767E);
  static const Color slate400 = grey;
  static const Color slate300 = Color(0xFFDCDCDC);
  static const Color slate200 = greyLight;
  static const Color slate100 = greyFaint;
  static const Color slate50  = white;

  // STATUS ALERTS
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color amber        = Color(0xFFF59E0B);
  static const Color info         = Color(0xFF3B82F6);
  static const Color infoLight    = Color(0xFFDBEAFE);

  static Color forStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'in transit':
      case 'active':
        return emerald;
      case 'assigned':
      case 'pending':
        return warning;
      case 'completed':
        return info;
      case 'critical':
        return orange;
      default:
        return slate500;
    }
  }

  static Color forStatusBg(String? status) {
    switch (status?.toLowerCase()) {
      case 'in transit':
      case 'active':
        return emeraldLight;
      case 'assigned':
      case 'pending':
        return warningLight;
      case 'completed':
        return infoLight;
      case 'critical':
        return orangeFaint;
      default:
        return slate100;
    }
  }
}

// ============================================================
// GRADIENTS
// ============================================================
class AppGradients {
  static const LinearGradient brandHero = LinearGradient(
    colors: [AppColors.nearBlack, AppColors.brown],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient orangeAccent = LinearGradient(
    colors: [AppColors.orange, AppColors.orangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceLight = LinearGradient(
    colors: [AppColors.white, AppColors.greyFaint],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient emergency = LinearGradient(
    colors: [AppColors.orange, AppColors.orangeDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient emerald = LinearGradient(
    colors: [AppColors.emerald, AppColors.emeraldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy aliases
  static const LinearGradient violetDusk     = brandHero;
  static const LinearGradient peachIvory     = surfaceLight;
  static const LinearGradient ivoryCanvas    = surfaceLight;
  static const LinearGradient navyHero       = brandHero;
  static const LinearGradient creamCanvas    = surfaceLight;
  static const LinearGradient skyAccent      = orangeAccent;
  static const LinearGradient headerGradient = brandHero;
  static const LinearGradient dark           = brandHero;
  static const LinearGradient darkCard       = brandHero;
}

// ============================================================
// DECORATIONS (Skeuomorphic tactile surfaces & bevels)
// ============================================================
class AppDecorations {
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = 20,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: showBorder
          ? Border.all(color: AppColors.greyLight, width: 1.2)
          : null,
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration cardElevated({
    Color color = AppColors.surface,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.greyLight, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // SKEUOMORPHIC DESIGN SYSTEM SURFACES (NEUE MONTREAL 5-COLOR)
  static BoxDecoration skeuomorphicRaised({
    Color? surfaceColor,
    double radius = 24,
    bool isHovered = false,
    bool isDarkSurface = false,
  }) {
    if (isDarkSurface) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.nearBlackLight,
            AppColors.nearBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isHovered
              ? AppColors.orange
              : AppColors.brown.withValues(alpha: 0.50),
          width: isHovered ? 1.6 : 1.2,
        ),
        boxShadow: [
          // Deep tactile drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isHovered ? 0.60 : 0.40),
            blurRadius: isHovered ? 28 : 20,
            offset: Offset(0, isHovered ? 12 : 8),
          ),
          // Top rim highlight (bevel simulation)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
          // Soft bottom rim glow
          BoxShadow(
            color: AppColors.orange.withValues(alpha: isHovered ? 0.25 : 0.10),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          surfaceColor ?? Colors.white,
          AppColors.greyFaint,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isHovered
            ? AppColors.orange
            : AppColors.greyLight,
        width: isHovered ? 1.5 : 1.2,
      ),
      boxShadow: [
        // Primary tactile drop shadow (visible depth on pure white)
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: isHovered ? 0.12 : 0.06),
          blurRadius: isHovered ? 28 : 18,
          offset: Offset(0, isHovered ? 12 : 7),
        ),
        // Secondary soft ambient spread
        BoxShadow(
          color: AppColors.brown.withValues(alpha: isHovered ? 0.06 : 0.03),
          blurRadius: isHovered ? 10 : 5,
          offset: Offset(0, isHovered ? 4 : 2),
        ),
        // Top specular bevel edge highlight
        const BoxShadow(
          color: Colors.white,
          blurRadius: 2,
          offset: Offset(0, -1),
        ),
        // Subtle bottom inset bevel reflection
        BoxShadow(
          color: AppColors.grey.withValues(alpha: 0.25),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration iconMedallion({
    bool isDark = false,
    Color? bg,
    Color? borderColor,
    double radius = 14,
    double? size,
  }) {
    if (bg != null) {
      return BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (borderColor ?? AppColors.greyLight).withValues(alpha: 0.60),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.nearBlack.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      );
    }
    if (isDark) {
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.nearBlackLight,
            AppColors.nearBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.brownLight.withValues(alpha: 0.50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.10),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      );
    }
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppColors.greyFaint,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.greyLight,
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        const BoxShadow(
          color: Colors.white,
          blurRadius: 1,
          offset: Offset(0, -1),
        ),
      ],
    );
  }

  static BoxDecoration skeuomorphicInset({
    double radius = 16,
    bool isDarkSurface = false,
  }) {
    if (isDarkSurface) {
      return BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D0B0D), // Recessed shadow top
            AppColors.nearBlack,
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFF1E1A1E),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      );
    }

    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFEDEDED), // Shadowed top of recessed well
          AppColors.white,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.greyLight,
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: 0.06),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
        const BoxShadow(
          color: Colors.white,
          blurRadius: 1,
          offset: Offset(0, -1),
        ),
      ],
    );
  }

  static BoxDecoration skeuomorphicButton({
    bool isPrimary = true,
    bool isHovered = false,
    double radius = 30,
  }) {
    if (isPrimary) {
      // Tactile Brand Orange button with metallic specular sheen
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovered
              ? [const Color(0xFFFF8547), AppColors.orange]
              : [AppColors.orange, AppColors.orangeDark],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: const Color(0xFFFF9E6C),
          width: 1.4,
        ),
        boxShadow: [
          // Tactile button drop shadow
          BoxShadow(
            color: AppColors.orange.withValues(alpha: isHovered ? 0.40 : 0.25),
            blurRadius: isHovered ? 18 : 12,
            offset: Offset(0, isHovered ? 6 : 4),
          ),
          // Top specular highlight
          const BoxShadow(
            color: Colors.white,
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      );
    }

    // Secondary / Outlined tactile button
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.nearBlackLight,
          AppColors.nearBlack,
        ],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isHovered
            ? AppColors.orange
            : AppColors.grey.withValues(alpha: 0.40),
        width: 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: isHovered ? 14 : 8,
          offset: Offset(0, isHovered ? 5 : 3),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.10),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
    );
  }

  static BoxDecoration subtleCard({
    Color color = AppColors.white,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.greyLight, width: 1),
    );
  }

  static BoxDecoration tile3D({
    Color? color,
    double? radius,
    bool isHovered = false,
    double? elevation,
  }) {
    final dt = DesignTuningController.instance;
    final effColor = color ?? AppColors.white;
    final effRadius = radius ?? dt.tileRadius;
    final effElevation = elevation ?? dt.tileElevation;
    final effOffset = dt.tileShadowOffset;

    return BoxDecoration(
      color: effColor,
      borderRadius: BorderRadius.circular(effRadius),
      border: Border.all(
        color: isHovered
            ? AppColors.orange
            : AppColors.greyLight,
        width: isHovered ? 1.8 : 1.3,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: isHovered ? 0.14 : 0.06),
          blurRadius: (isHovered ? 32 : 20) * (effElevation / 2),
          offset: Offset(0, (isHovered ? effOffset * 1.5 : effOffset) * (effElevation / 2)),
        ),
        BoxShadow(
          color: Colors.white,
          blurRadius: 2,
          offset: const Offset(0, -1),
        ),
        BoxShadow(
          color: AppColors.grey.withValues(alpha: 0.15),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration glassViolet({double? radius, double? alpha}) {
    final dt = DesignTuningController.instance;
    final effRadius = radius ?? dt.glassCornerRadius;
    final effAlpha = alpha ?? dt.glassSurfaceOpacity;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.nearBlackLight.withValues(alpha: (effAlpha * 1.8).clamp(0.40, 0.95)),
          AppColors.nearBlack.withValues(alpha: (effAlpha * 1.6).clamp(0.40, 0.98)),
        ],
      ),
      borderRadius: BorderRadius.circular(effRadius),
      border: Border.all(
        color: AppColors.orange.withValues(alpha: dt.glassBorderOpacity * 0.8),
        width: 1.3 * dt.tileHighlightIntensity,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dt.glassShadowOpacity * 2.0),
          blurRadius: dt.glassShadowBlur * 1.2,
          offset: Offset(0, dt.tileShadowOffset * 1.2),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.10),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration glassIvory({double? radius, double? alpha}) {
    final dt = DesignTuningController.instance;
    final effRadius = radius ?? dt.glassCornerRadius;
    final effAlpha = alpha ?? dt.glassSurfaceOpacity;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.white.withValues(alpha: (effAlpha * 1.8).clamp(0.60, 0.96)),
          AppColors.greyFaint.withValues(alpha: (effAlpha * 1.4).clamp(0.40, 0.90)),
        ],
      ),
      borderRadius: BorderRadius.circular(effRadius),
      border: Border.all(
        color: AppColors.greyLight.withValues(alpha: dt.glassBorderOpacity),
        width: 1.3 * dt.tileHighlightIntensity,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.nearBlack.withValues(alpha: dt.glassShadowOpacity * 0.8),
          blurRadius: dt.glassShadowBlur,
          offset: Offset(0, dt.tileShadowOffset),
        ),
        const BoxShadow(
          color: Colors.white,
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  // Legacy aliases
  static BoxDecoration glassNavy({double? radius, double? alpha}) =>
      glassViolet(radius: radius, alpha: alpha);
  static BoxDecoration glassCream({double? radius, double? alpha}) =>
      glassIvory(radius: radius, alpha: alpha);

  static BoxDecoration badge({required Color color, double radius = 10}) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
    );
  }

  static InputDecoration input({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.greyFaint,
      labelStyle: const TextStyle(
        fontFamily: 'NeueMontreal',
        color: AppColors.nearBlackMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'NeueMontreal',
        color: AppColors.greyDark,
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.greyLight, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.greyLight, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orangeDark, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.orangeDark, width: 2),
      ),
    );
  }
}

class AppFonts {
  static TextStyle neueMontreal({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    return TextStyle(
      fontFamily: 'NeueMontreal',
      color: color ?? textStyle?.color,
      backgroundColor: backgroundColor ?? textStyle?.backgroundColor,
      fontSize: fontSize ?? textStyle?.fontSize,
      fontWeight: fontWeight ?? textStyle?.fontWeight,
      fontStyle: fontStyle ?? textStyle?.fontStyle,
      letterSpacing: letterSpacing ?? textStyle?.letterSpacing,
      wordSpacing: wordSpacing ?? textStyle?.wordSpacing,
      textBaseline: textBaseline ?? textStyle?.textBaseline,
      height: height ?? textStyle?.height,
      locale: locale ?? textStyle?.locale,
      foreground: foreground ?? textStyle?.foreground,
      background: background ?? textStyle?.background,
      shadows: shadows ?? textStyle?.shadows,
      fontFeatures: fontFeatures ?? textStyle?.fontFeatures,
      decoration: decoration ?? textStyle?.decoration,
      decorationColor: decorationColor ?? textStyle?.decorationColor,
      decorationStyle: decorationStyle ?? textStyle?.decorationStyle,
      decorationThickness: decorationThickness ?? textStyle?.decorationThickness,
    );
  }
}

// ============================================================
// TYPOGRAPHY (NEUE MONTREAL)
// Weights: Regular (400), Medium (500), Semibold (600/700)
// ============================================================
class AppTypography {
  static const String fontHeading = 'NeueMontreal';
  static const String fontBody    = 'NeueMontreal';

  static TextStyle headlineHero({
    Color color = AppColors.nearBlack,
    double size = 52,
    double height = 1.05,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -1.2,
    height: height,
  );

  static TextStyle headlineLarge({
    Color color = AppColors.nearBlack,
    double size = 36,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: -0.8,
    height: 1.16,
  );

  static TextStyle sectionTitle({
    Color color = AppColors.nearBlack,
    double size = 28,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: -0.5,
  );

  static TextStyle titleMedium({
    Color color = AppColors.nearBlack,
    double size = 18,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    letterSpacing: -0.2,
  );

  static TextStyle bodyMedium({
    Color color = AppColors.nearBlackMuted,
    double size = 14,
    double height = 1.60,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  static TextStyle bodyStrong({
    Color color = AppColors.nearBlack,
    double size = 14,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle buttonText({
    Color color = AppColors.white,
    double size = 14,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.3,
  );

  static TextStyle tacticalBadge({
    Color color = AppColors.nearBlack,
    double size = 11,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.9,
  );

  static TextStyle metricValue({
    Color color = AppColors.nearBlack,
    double size = 32,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.8,
  );

  static TextStyle wordmark({
    Color color = AppColors.nearBlack,
    double size = 18,
  }) => TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 1.2,
  );
}

// ============================================================
// MATERIAL THEME
// ============================================================
class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'NeueMontreal',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.orange,
        primary: AppColors.orange,
        secondary: AppColors.brown,
        tertiary: AppColors.nearBlack,
        surface: AppColors.white,
        brightness: Brightness.light,
      ),
    );

    return baseTheme.copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.orange,
        selectionColor: AppColors.orange.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.orange,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.greyLight,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.nearBlack,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'NeueMontreal',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.greyLight, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NeueMontreal',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.nearBlack,
        contentTextStyle: const TextStyle(
          fontFamily: 'NeueMontreal',
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.orange, width: 1.2),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
