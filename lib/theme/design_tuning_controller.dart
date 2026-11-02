import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

enum DialKitEasing { easeInOut, fastOutSlowIn, linear }

/// DialKit Interactive Design Tuning Controller
/// Stores and broadcasts live design tokens across Glass Surfaces, 3D Tiles,
/// Globe Animation, Layout Metrics, and Palette Presets.
class DesignTuningController extends ChangeNotifier {
  static final DesignTuningController instance = DesignTuningController._();
  DesignTuningController._();

  // Visibility state of the development panel
  bool isPanelOpen = false;
  bool isEnabled = !kReleaseMode; // Active in development mode only

  // ==========================================
  // 1. GLASS SURFACE CONTROLS
  // ==========================================
  double glassBlur = 20.0;           // 0.0 .. 50.0
  double glassSurfaceOpacity = 0.28; // 0.05 .. 0.80 (28% translucent frosted glass)
  double glassBorderOpacity = 0.70;  // 0.1 .. 1.0 (crisp specular rim)
  double glassCornerRadius = 28.0;   // 8.0 .. 50.0
  double glassShadowBlur = 32.0;     // 4.0 .. 60.0
  double glassShadowOpacity = 0.14;  // 0.0 .. 0.5

  // ==========================================
  // 2. THREE-DIMENSIONAL TILES CONTROLS
  // ==========================================
  double tileElevation = 3.0;           // 1.0 .. 10.0
  double tileShadowOffset = 8.0;        // 0.0 .. 24.0
  double tileHighlightIntensity = 0.70; // 0.0 .. 1.0
  double tileRadius = 22.0;             // 8.0 .. 40.0
  double cardPadding = 24.0;            // 10.0 .. 48.0
  double get tileCardPadding => cardPadding;
  double tileHoverScale = 1.03;         // 1.0 .. 1.15

  // ==========================================
  // 3. GLOBE ANIMATION CONTROLS
  // ==========================================
  double globeRotationRange = 1.6;        // 0.5 .. 5.0 (speed/range multiplier)
  double globeScale = 1.0;                // 0.5 .. 2.0
  double globeVerticalPosition = 0.0;     // -100.0 .. 100.0 px
  double globeRouteVisibility = 1.0;      // 0.0 .. 1.0 (opacity)
  DialKitEasing globeAnimationEasing = DialKitEasing.easeInOut;
  double globeTransitionTiming = 600.0;   // 200.0 .. 2000.0 ms

  // ==========================================
  // 4. LAYOUT CONTROLS
  // ==========================================
  double layoutContentWidth = 1240.0;   // 800.0 .. 1600.0 px
  double layoutSectionSpacing = 64.0;   // 20.0 .. 140.0 px
  double layoutNavHeight = 72.0;        // 56.0 .. 100.0 px
  double layoutGridGap = 20.0;          // 8.0 .. 40.0 px
  double layoutCardSizing = 320.0;      // 240.0 .. 450.0 px (min width)

  // ==========================================
  // 5. COLOR PALETTE PRESETS
  // ==========================================
  // Neue Montreal Brand Palette — Orange, Brown, Near-black, Grey, White
  String activePalettePreset = "Neue Montreal";

  Color get currentNavy => AppColors.nearBlack;

  Color get currentSecondary => AppColors.brown;

  Color get currentCream => AppColors.white;

  Color get currentAccentWarm => AppColors.orange;

  // Setters with notifyListeners()
  void updateGlass({
    double? blur,
    double? surfaceOpacity,
    double? borderOpacity,
    double? cornerRadius,
    double? shadowBlur,
    double? shadowOpacity,
  }) {
    if (blur != null) glassBlur = blur;
    if (surfaceOpacity != null) glassSurfaceOpacity = surfaceOpacity;
    if (borderOpacity != null) glassBorderOpacity = borderOpacity;
    if (cornerRadius != null) glassCornerRadius = cornerRadius;
    if (shadowBlur != null) glassShadowBlur = shadowBlur;
    if (shadowOpacity != null) glassShadowOpacity = shadowOpacity;
    notifyListeners();
  }

  void updateTiles({
    double? elevation,
    double? shadowOffset,
    double? highlightIntensity,
    double? radius,
    double? padding,
    double? hoverScale,
  }) {
    if (elevation != null) tileElevation = elevation;
    if (shadowOffset != null) tileShadowOffset = shadowOffset;
    if (highlightIntensity != null) tileHighlightIntensity = highlightIntensity;
    if (radius != null) tileRadius = radius;
    if (padding != null) cardPadding = padding;
    if (hoverScale != null) tileHoverScale = hoverScale;
    notifyListeners();
  }

  void updateGlobe({
    double? rotationRange,
    double? scale,
    double? verticalPosition,
    double? routeVisibility,
    DialKitEasing? easing,
    double? transitionTiming,
  }) {
    if (rotationRange != null) globeRotationRange = rotationRange;
    if (scale != null) globeScale = scale;
    if (verticalPosition != null) globeVerticalPosition = verticalPosition;
    if (routeVisibility != null) globeRouteVisibility = routeVisibility;
    if (easing != null) globeAnimationEasing = easing;
    if (transitionTiming != null) globeTransitionTiming = transitionTiming;
    notifyListeners();
  }

  void updateLayout({
    double? contentWidth,
    double? sectionSpacing,
    double? navHeight,
    double? gridGap,
    double? cardSizing,
  }) {
    if (contentWidth != null) layoutContentWidth = contentWidth;
    if (sectionSpacing != null) layoutSectionSpacing = sectionSpacing;
    if (navHeight != null) layoutNavHeight = navHeight;
    if (gridGap != null) layoutGridGap = gridGap;
    if (cardSizing != null) layoutCardSizing = cardSizing;
    notifyListeners();
  }

  void setPalettePreset(String preset) {
    activePalettePreset = preset;
    notifyListeners();
  }

  void togglePanel() {
    isPanelOpen = !isPanelOpen;
    notifyListeners();
  }

  void resetToDefaults() {
    glassBlur = 20.0;
    glassSurfaceOpacity = 0.28;
    glassBorderOpacity = 0.70;
    glassCornerRadius = 28.0;
    glassShadowBlur = 32.0;
    glassShadowOpacity = 0.14;

    tileElevation = 3.0;
    tileShadowOffset = 8.0;
    tileHighlightIntensity = 0.70;
    tileRadius = 22.0;
    cardPadding = 24.0;
    tileHoverScale = 1.03;

    globeRotationRange = 1.6;
    globeScale = 1.0;
    globeVerticalPosition = 0.0;
    globeRouteVisibility = 1.0;
    globeAnimationEasing = DialKitEasing.easeInOut;
    globeTransitionTiming = 600.0;

    layoutContentWidth = 1240.0;
    layoutSectionSpacing = 64.0;
    layoutNavHeight = 72.0;
    layoutGridGap = 20.0;
    layoutCardSizing = 320.0;

    activePalettePreset = "Velvet Botanical";
    notifyListeners();
  }

  /// Exports current tuning parameters as production Dart code
  String exportToDartCode() {
    return '''
// === DIALKIT GENERATED PRODUCTION DESIGN TOKENS ===
class AppTunedTokens {
  // Glass Surface
  static const double glassBlur = ${glassBlur.toStringAsFixed(1)};
  static const double glassSurfaceOpacity = ${glassSurfaceOpacity.toStringAsFixed(2)};
  static const double glassBorderOpacity = ${glassBorderOpacity.toStringAsFixed(2)};
  static const double glassCornerRadius = ${glassCornerRadius.toStringAsFixed(1)};
  static const double glassShadowBlur = ${glassShadowBlur.toStringAsFixed(1)};
  static const double glassShadowOpacity = ${glassShadowOpacity.toStringAsFixed(2)};

  // 3D Tiles
  static const double tileElevation = ${tileElevation.toStringAsFixed(1)};
  static const double tileShadowOffset = ${tileShadowOffset.toStringAsFixed(1)};
  static const double tileHighlightIntensity = ${tileHighlightIntensity.toStringAsFixed(2)};
  static const double tileRadius = ${tileRadius.toStringAsFixed(1)};
  static const double cardPadding = ${cardPadding.toStringAsFixed(1)};
  static const double tileHoverScale = ${tileHoverScale.toStringAsFixed(2)};

  // Globe Animation
  static const double globeRotationRange = ${globeRotationRange.toStringAsFixed(2)};
  static const double globeScale = ${globeScale.toStringAsFixed(2)};
  static const double globeVerticalPosition = ${globeVerticalPosition.toStringAsFixed(1)};
  static const double globeRouteVisibility = ${globeRouteVisibility.toStringAsFixed(2)};
  static const String globeEasing = '${globeAnimationEasing.name}';
  static const int globeTransitionTimingMs = ${globeTransitionTiming.toInt()};

  // Layout
  static const double layoutContentWidth = ${layoutContentWidth.toStringAsFixed(1)};
  static const double layoutSectionSpacing = ${layoutSectionSpacing.toStringAsFixed(1)};
  static const double layoutNavHeight = ${layoutNavHeight.toStringAsFixed(1)};
  static const double layoutGridGap = ${layoutGridGap.toStringAsFixed(1)};
  static const double layoutCardSizing = ${layoutCardSizing.toStringAsFixed(1)};
}
''';
  }

  /// Exports current tuning parameters as JSON
  String exportToJson() {
    return '''
{
  "glass": {
    "blur": ${glassBlur.toStringAsFixed(1)},
    "surfaceOpacity": ${glassSurfaceOpacity.toStringAsFixed(2)},
    "borderOpacity": ${glassBorderOpacity.toStringAsFixed(2)},
    "cornerRadius": ${glassCornerRadius.toStringAsFixed(1)},
    "shadowBlur": ${glassShadowBlur.toStringAsFixed(1)},
    "shadowOpacity": ${glassShadowOpacity.toStringAsFixed(2)}
  },
  "tiles": {
    "elevation": ${tileElevation.toStringAsFixed(1)},
    "shadowOffset": ${tileShadowOffset.toStringAsFixed(1)},
    "highlightIntensity": ${tileHighlightIntensity.toStringAsFixed(2)},
    "radius": ${tileRadius.toStringAsFixed(1)},
    "cardPadding": ${cardPadding.toStringAsFixed(1)},
    "hoverScale": ${tileHoverScale.toStringAsFixed(2)}
  },
  "globe": {
    "rotationRange": ${globeRotationRange.toStringAsFixed(2)},
    "scale": ${globeScale.toStringAsFixed(2)},
    "verticalPosition": ${globeVerticalPosition.toStringAsFixed(1)},
    "routeVisibility": ${globeRouteVisibility.toStringAsFixed(2)},
    "easing": "${globeAnimationEasing.name}",
    "transitionTiming": ${globeTransitionTiming.toInt()}
  },
  "layout": {
    "contentWidth": ${layoutContentWidth.toStringAsFixed(1)},
    "sectionSpacing": ${layoutSectionSpacing.toStringAsFixed(1)},
    "navHeight": ${layoutNavHeight.toStringAsFixed(1)},
    "gridGap": ${layoutGridGap.toStringAsFixed(1)},
    "cardSizing": ${layoutCardSizing.toStringAsFixed(1)}
  },
  "palettePreset": "$activePalettePreset"
}
''';
  }

  // Aliases for comprehensive API consistency
  void updateGlassSurface({
    double? blur,
    double? surfaceOpacity,
    double? borderOpacity,
    double? cornerRadius,
    double? shadowBlur,
    double? shadowOpacity,
  }) => updateGlass(
    blur: blur,
    surfaceOpacity: surfaceOpacity,
    borderOpacity: borderOpacity,
    cornerRadius: cornerRadius,
    shadowBlur: shadowBlur,
    shadowOpacity: shadowOpacity,
  );

  void update3DTiles({
    double? elevation,
    double? shadowOffset,
    double? highlightIntensity,
    double? radius,
    double? padding,
    double? hoverScale,
  }) => updateTiles(
    elevation: elevation,
    shadowOffset: shadowOffset,
    highlightIntensity: highlightIntensity,
    radius: radius,
    padding: padding,
    hoverScale: hoverScale,
  );

  void updateGlobeAnimation({
    double? rotationRange,
    double? scale,
    double? verticalPosition,
    double? routeVisibility,
    DialKitEasing? easing,
    double? transitionTiming,
  }) => updateGlobe(
    rotationRange: rotationRange,
    scale: scale,
    verticalPosition: verticalPosition,
    routeVisibility: routeVisibility,
    easing: easing,
    transitionTiming: transitionTiming,
  );

  int get diffCount => getDiffsFromDefaults().length;

  Map<String, Map<String, dynamic>> getDiffsFromDefaults() {
    final Map<String, Map<String, dynamic>> diffs = {};
    if (glassBlur != 20.0) diffs['glassBlur'] = {'default': 20.0, 'current': glassBlur};
    if (glassSurfaceOpacity != 0.28) diffs['glassSurfaceOpacity'] = {'default': 0.28, 'current': glassSurfaceOpacity};
    if (glassBorderOpacity != 0.70) diffs['glassBorderOpacity'] = {'default': 0.70, 'current': glassBorderOpacity};
    if (glassCornerRadius != 28.0) diffs['glassCornerRadius'] = {'default': 28.0, 'current': glassCornerRadius};
    if (glassShadowBlur != 32.0) diffs['glassShadowBlur'] = {'default': 32.0, 'current': glassShadowBlur};
    if (glassShadowOpacity != 0.14) diffs['glassShadowOpacity'] = {'default': 0.14, 'current': glassShadowOpacity};
    if (tileElevation != 3.0) diffs['tileElevation'] = {'default': 3.0, 'current': tileElevation};
    if (tileShadowOffset != 8.0) diffs['tileShadowOffset'] = {'default': 8.0, 'current': tileShadowOffset};
    if (tileHighlightIntensity != 0.70) diffs['tileHighlightIntensity'] = {'default': 0.70, 'current': tileHighlightIntensity};
    if (tileRadius != 22.0) diffs['tileRadius'] = {'default': 22.0, 'current': tileRadius};
    if (cardPadding != 24.0) diffs['cardPadding'] = {'default': 24.0, 'current': cardPadding};
    if (tileHoverScale != 1.03) diffs['tileHoverScale'] = {'default': 1.03, 'current': tileHoverScale};
    if (globeRotationRange != 1.6) diffs['globeRotationRange'] = {'default': 1.6, 'current': globeRotationRange};
    if (globeScale != 1.0) diffs['globeScale'] = {'default': 1.0, 'current': globeScale};
    if (globeVerticalPosition != 0.0) diffs['globeVerticalPosition'] = {'default': 0.0, 'current': globeVerticalPosition};
    if (globeRouteVisibility != 1.0) diffs['globeRouteVisibility'] = {'default': 1.0, 'current': globeRouteVisibility};
    if (globeAnimationEasing != DialKitEasing.easeInOut) diffs['globeAnimationEasing'] = {'default': 'easeInOut', 'current': globeAnimationEasing.name};
    if (globeTransitionTiming != 600.0) diffs['globeTransitionTiming'] = {'default': 600.0, 'current': globeTransitionTiming};
    if (layoutContentWidth != 1240.0) diffs['layoutContentWidth'] = {'default': 1240.0, 'current': layoutContentWidth};
    if (layoutSectionSpacing != 64.0) diffs['layoutSectionSpacing'] = {'default': 64.0, 'current': layoutSectionSpacing};
    if (layoutNavHeight != 72.0) diffs['layoutNavHeight'] = {'default': 72.0, 'current': layoutNavHeight};
    if (layoutGridGap != 20.0) diffs['layoutGridGap'] = {'default': 20.0, 'current': layoutGridGap};
    if (layoutCardSizing != 320.0) diffs['layoutCardSizing'] = {'default': 320.0, 'current': layoutCardSizing};
    if (activePalettePreset != "Velvet Botanical") diffs['palettePreset'] = {'default': 'Velvet Botanical', 'current': activePalettePreset};
    return diffs;
  }
}
