import 'package:flutter/material.dart';
import 'design_tuning_controller.dart';

// ============================================================
// VIOLET DUSK — GREEN CORRIDOR DESIGN SYSTEM
// Four mandated core colors + semantic palette
// ============================================================
class AppColors {
  // VIOLET DUSK CORE PALETTE
  static const Color deepViolet = Color(0xFF502D55);
  static const Color mutedBerry = Color(0xFF935073);
  static const Color warmPeach  = Color(0xFFF6DBC0);
  static const Color softIvory  = Color(0xFFF8F4E9);

  // TONAL VARIANTS
  static const Color deepVioletDark   = Color(0xFF3A1E3E);
  static const Color deepVioletLight  = Color(0xFF6B3F72);
  static const Color deepVioletMuted  = Color(0xFF6E4B74);
  static const Color mutedBerryDark   = Color(0xFF72375A);
  static const Color mutedBerryLight  = Color(0xFFBA7DA0);
  static const Color mutedBerryFaint  = Color(0xFFF2DCE8);
  static const Color warmPeachDark    = Color(0xFFE8C09C);
  static const Color warmPeachLight   = Color(0xFFFBEEDE);
  static const Color warmPeachFaint   = Color(0xFFFDF6EE);
  static const Color softIvoryDark    = Color(0xFFEDE7D3);
  static const Color softIvoryLight   = Color(0xFFFDFBF6);
  static const Color softIvoryBorder  = Color(0xFFE5DCC8);

  // LEGACY ALIASES
  static const Color navy         = deepViolet;
  static const Color cream        = softIvory;
  static const Color sky          = mutedBerry;
  static const Color navyDark     = deepVioletDark;
  static const Color navyLight    = deepVioletLight;
  static const Color creamLight   = softIvoryLight;
  static const Color creamDark    = softIvoryDark;
  static const Color skyLight     = mutedBerryFaint;
  static const Color skyDark      = mutedBerryDark;
  static const Color skyTint      = warmPeachFaint;
  static const Color navyText     = deepViolet;
  static const Color navyMuted    = deepVioletMuted;
  static const Color borderLight  = softIvoryBorder;

  // SURFACE & CANVAS
  static const Color background       = softIvory;
  static const Color surface          = softIvoryLight;
  static const Color surfaceElevated  = Color(0xFFFFFFFF);

  // SEMANTIC STATUS
  static const Color primary       = Color(0xFFE11D48);
  static const Color primaryDark   = Color(0xFFBE123C);
  static const Color primaryLight  = Color(0xFFFFE4E6);
  static const Color emerald       = Color(0xFF10B981);
  static const Color emeraldDark   = Color(0xFF059669);
  static const Color emeraldLight  = Color(0xFFD1FAE5);

  // NEUTRAL SCALE
  static const Color slate900 = Color(0xFF3A1E3E);
  static const Color slate800 = Color(0xFF4A2B50);
  static const Color slate700 = Color(0xFF5E3B63);
  static const Color slate600 = Color(0xFF6E4B74);
  static const Color slate500 = Color(0xFF8F6B94);
  static const Color slate400 = Color(0xFFB59AB8);
  static const Color slate300 = Color(0xFFD4BDD6);
  static const Color slate200 = Color(0xFFE8D8EA);
  static const Color slate100 = Color(0xFFF4EBF5);
  static const Color slate50  = Color(0xFFFAF5FB);

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
        return primary;
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
        return primaryLight;
      default:
        return slate100;
    }
  }
}

// ============================================================
// GRADIENTS
// ============================================================
class AppGradients {
  static const LinearGradient violetDusk = LinearGradient(
    colors: [AppColors.deepViolet, AppColors.mutedBerry],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient peachIvory = LinearGradient(
    colors: [AppColors.warmPeach, AppColors.softIvory],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient ivoryCanvas = LinearGradient(
    colors: [AppColors.softIvory, AppColors.warmPeachFaint],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient emergency = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient emerald = LinearGradient(
    colors: [AppColors.emerald, AppColors.emeraldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  // Legacy aliases
  static const LinearGradient navyHero       = violetDusk;
  static const LinearGradient creamCanvas    = ivoryCanvas;
  static const LinearGradient skyAccent      = peachIvory;
  static const LinearGradient headerGradient = violetDusk;
  static const LinearGradient dark           = violetDusk;
  static const LinearGradient darkCard       = violetDusk;
}

// ============================================================
// DECORATIONS
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
          ? Border.all(color: AppColors.mutedBerry.withValues(alpha: 0.25), width: 1.2)
          : null,
      boxShadow: [
        BoxShadow(
          color: AppColors.deepViolet.withValues(alpha: 0.06),
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
      border: Border.all(color: AppColors.mutedBerry.withValues(alpha: 0.30), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: AppColors.deepViolet.withValues(alpha: 0.10),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.deepViolet.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration subtleCard({
    Color color = AppColors.softIvoryLight,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.softIvoryBorder, width: 1),
    );
  }

  static BoxDecoration tile3D({
    Color? color,
    double? radius,
    bool isHovered = false,
    double? elevation,
  }) {
    final dt = DesignTuningController.instance;
    final effColor = color ?? AppColors.softIvoryLight;
    final effRadius = radius ?? dt.tileRadius;
    final effElevation = elevation ?? dt.tileElevation;
    final effOffset = dt.tileShadowOffset;
    final effViolet = dt.currentNavy;
    final effBerry = dt.currentSecondary;

    return BoxDecoration(
      color: effColor,
      borderRadius: BorderRadius.circular(effRadius),
      border: Border.all(
        color: isHovered
            ? effViolet.withValues(alpha: 0.55)
            : effBerry.withValues(alpha: 0.30),
        width: isHovered ? 1.8 : 1.3,
      ),
      boxShadow: [
        BoxShadow(
          color: effViolet.withValues(alpha: isHovered ? 0.18 : 0.08),
          blurRadius: (isHovered ? 32 : 20) * (effElevation / 2),
          offset: Offset(0, (isHovered ? effOffset * 1.5 : effOffset) * (effElevation / 2)),
        ),
        BoxShadow(
          color: AppColors.warmPeach.withValues(alpha: dt.tileHighlightIntensity * 0.5),
          blurRadius: 4,
          offset: const Offset(0, -1),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.60),
          blurRadius: 1,
          offset: const Offset(0, 1),
          spreadRadius: 0,
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
          AppColors.deepViolet.withValues(alpha: (effAlpha * 1.8).clamp(0.35, 0.90)),
          AppColors.mutedBerry.withValues(alpha: (effAlpha * 1.3).clamp(0.25, 0.75)),
        ],
      ),
      borderRadius: BorderRadius.circular(effRadius),
      border: Border.all(
        color: AppColors.warmPeach.withValues(alpha: dt.glassBorderOpacity * 0.8),
        width: 1.3 * dt.tileHighlightIntensity,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.deepViolet.withValues(alpha: dt.glassShadowOpacity * 2.0),
          blurRadius: dt.glassShadowBlur * 1.2,
          offset: Offset(0, dt.tileShadowOffset * 1.2),
        ),
        BoxShadow(
          color: AppColors.warmPeach.withValues(alpha: 0.15),
          blurRadius: 1,
          offset: const Offset(0, 1),
          spreadRadius: 0,
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
          AppColors.softIvoryLight.withValues(alpha: (effAlpha * 1.8).clamp(0.35, 0.90)),
          AppColors.warmPeach.withValues(alpha: (effAlpha * 0.8).clamp(0.10, 0.45)),
        ],
      ),
      borderRadius: BorderRadius.circular(effRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: dt.glassBorderOpacity),
        width: 1.3 * dt.tileHighlightIntensity,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.deepViolet.withValues(alpha: dt.glassShadowOpacity * 1.4),
          blurRadius: dt.glassShadowBlur,
          offset: Offset(0, dt.tileShadowOffset),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: (dt.glassBorderOpacity * 0.85).clamp(0.2, 0.8)),
          blurRadius: 1,
          offset: const Offset(0, 1),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Legacy aliases
  static BoxDecoration glassNavy({double? radius, double? alpha}) =>
      glassViolet(radius: radius, alpha: alpha);
  static BoxDecoration glassCream({double? radius, double? alpha}) =>
      glassIvory(radius: radius, alpha: alpha);

  static BoxDecoration iconMedallion({
    Color bg = AppColors.mutedBerryFaint,
    Color borderColor = AppColors.mutedBerry,
    double radius = 14,
    double? size,
  }) {
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor.withValues(alpha: 0.40), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: AppColors.deepViolet.withValues(alpha: 0.10),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.warmPeach.withValues(alpha: 0.30),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
    );
  }

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
      fillColor: AppColors.softIvoryLight,
      labelStyle: const TextStyle(
        fontFamily: 'PeaceSans',
        color: AppColors.deepVioletMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        fontFamily: 'PeaceSans',
        color: AppColors.mutedBerry.withValues(alpha: 0.55),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.mutedBerry.withValues(alpha: 0.40), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.softIvoryBorder, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.deepViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

// ============================================================
// TYPOGRAPHY
// ============================================================
class AppTypography {
  static const String fontHeading = 'OpenSauceSans';
  static const String fontBody    = 'PeaceSans';

  static TextStyle headlineHero({
    Color color = AppColors.deepViolet,
    double size = 52,
    double height = 1.05,
  }) => TextStyle(
    fontFamily: 'OpenSauceSans',
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
    letterSpacing: -1.5,
    height: height,
  );

  static TextStyle headlineLarge({
    Color color = AppColors.deepViolet,
    double size = 36,
  }) => TextStyle(
    fontFamily: 'OpenSauceSans',
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -0.9,
    height: 1.16,
  );

  static TextStyle sectionTitle({
    Color color = AppColors.deepViolet,
    double size = 28,
  }) => TextStyle(
    fontFamily: 'OpenSauceSans',
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -0.5,
  );

  static TextStyle titleMedium({
    Color color = AppColors.deepViolet,
    double size = 18,
  }) => TextStyle(
    fontFamily: 'OpenSauceSans',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.2,
  );

  static TextStyle bodyMedium({
    Color color = AppColors.deepVioletMuted,
    double size = 14,
    double height = 1.60,
  }) => TextStyle(
    fontFamily: 'PeaceSans',
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: color,
    height: height,
  );

  static TextStyle bodyStrong({
    Color color = AppColors.deepViolet,
    double size = 14,
  }) => TextStyle(
    fontFamily: 'PeaceSans',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle buttonText({
    Color color = AppColors.softIvory,
    double size = 14,
  }) => TextStyle(
    fontFamily: 'PeaceSans',
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.3,
  );

  static TextStyle tacticalBadge({
    Color color = AppColors.deepViolet,
    double size = 11,
  }) => TextStyle(
    fontFamily: 'PeaceSans',
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: 0.9,
  );

  static TextStyle metricValue({
    Color color = AppColors.deepViolet,
    double size = 32,
  }) => TextStyle(
    fontFamily: 'OpenSauceSans',
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
    letterSpacing: -1.0,
  );

  static TextStyle wordmark({
    Color color = AppColors.deepViolet,
    double size = 18,
  }) => TextStyle(
    fontFamily: 'OpenSauceSans',
    fontSize: size,
    fontWeight: FontWeight.w900,
    color: color,
    letterSpacing: 1.4,
  );
}

// ============================================================
// MATERIAL THEME
// ============================================================
class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.softIvory,
      fontFamily: 'PeaceSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepViolet,
        primary: AppColors.deepViolet,
        secondary: AppColors.mutedBerry,
        tertiary: AppColors.warmPeach,
        surface: AppColors.softIvoryLight,
        brightness: Brightness.light,
      ),
    );

    return baseTheme.copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.deepViolet,
        selectionColor: AppColors.mutedBerry.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.deepViolet,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.softIvoryBorder,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepViolet,
        foregroundColor: AppColors.softIvory,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'OpenSauceSans',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.softIvory,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.softIvoryLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.mutedBerry.withValues(alpha: 0.20), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepViolet,
          foregroundColor: AppColors.softIvory,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PeaceSans',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepViolet,
        contentTextStyle: const TextStyle(
          fontFamily: 'PeaceSans',
          color: AppColors.softIvory,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.warmPeach.withValues(alpha: 0.50), width: 1.2),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
