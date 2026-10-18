import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand & Emergency Accents
  static const Color primary = Color(0xFFE11D48); // Modern Emergency Crimson
  static const Color primaryDark = Color(0xFFBE123C);
  static const Color primaryLight = Color(0xFFFFE4E6);

  // Fast-Track Green Corridor Accents
  static const Color emerald = Color(0xFF10B981); // Active Corridor Green
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFFD1FAE5);

  // Tech Navy / Slate Accents
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Canvas & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;

  // Alerts & Statuses
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color amber = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Status Color Helper
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

class AppGradients {
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

  static const LinearGradient dark = LinearGradient(
    colors: [AppColors.slate900, AppColors.slate800],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppDecorations {
  static BoxDecoration card({
    Color color = AppColors.surface,
    double radius = 20,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: showBorder ? Border.all(color: AppColors.slate200, width: 1) : null,
      boxShadow: [
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration cardElevated({
    Color color = AppColors.surface,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.slate200.withValues(alpha: 0.8), width: 1),
      boxShadow: [
        BoxShadow(
          color: AppColors.slate900.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
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
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.slate600, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class AppTypography {
  // Primary Emergency Environment Font: Plus Jakarta Sans / Inter style
  static TextStyle headlineLarge({Color color = AppColors.slate900, double size = 36}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -1.0,
        height: 1.15,
      );

  static TextStyle titleMedium({Color color = AppColors.slate900, double size = 18}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle bodyMedium({Color color = AppColors.slate600, double size = 15}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.55,
      );

  // Tactical / Telemetry Monospace & Pill Font for Emergency Metrics
  static TextStyle tacticalBadge({Color color = AppColors.primary, double size = 12}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.2,
      );

  static TextStyle metricValue({Color color = AppColors.slate900, double size = 32}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.emerald,
        surface: AppColors.surface,
      ),
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseTheme.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
