import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/design_tuning_controller.dart';

/// DialKit Interactive Design Tuning Root Overlay
/// Provides a development-only design tuning panel for real-time calibration of
/// Glass Surfaces, 3D Sculpted Tiles, Globe Animation, Layout, and Palette Presets.
class DialKitTuningOverlay extends StatefulWidget {
  final Widget child;

  const DialKitTuningOverlay({super.key, required this.child});

  @override
  State<DialKitTuningOverlay> createState() => _DialKitTuningOverlayState();
}

class _DialKitTuningOverlayState extends State<DialKitTuningOverlay> {
  final dt = DesignTuningController.instance;
  int _activeCategoryIndex = 0; // 0: Glass, 1: 3D Tiles, 2: Globe, 3: Layout, 4: Diff & Export

  @override
  void initState() {
    super.initState();
    dt.addListener(_onTuningChanged);
  }

  @override
  void dispose() {
    dt.removeListener(_onTuningChanged);
    super.dispose();
  }

  void _onTuningChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Hide completely in production release mode to avoid exposing internal controls
    if (!dt.isEnabled) {
      return widget.child;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // 1. The main application child
          widget.child,

          // 2. Floating Dev Badge (Bottom Right Trigger)
          Positioned(
            bottom: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => dt.togglePanel(),
                borderRadius: BorderRadius.circular(30),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: dt.currentNavy,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: dt.currentSecondary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: dt.currentNavy.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        dt.isPanelOpen ? Icons.close_rounded : Icons.tune_rounded,
                        color: dt.currentSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dt.isPanelOpen ? "CLOSE TUNING" : "DIALKIT TUNER",
                        style: TextStyle(
                          fontFamily: AppTypography.fontHeading,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: dt.currentCream,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Slide-in DialKit Design Tuning Drawer
          if (dt.isPanelOpen)
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: isMobile ? screenWidth * 0.94 : 440,
              child: Material(
                color: Colors.transparent,
                child: _buildTuningDrawer(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTuningDrawer(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: dt.currentCream.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
            border: Border(
              left: BorderSide(color: dt.currentSecondary, width: 2.0),
            ),
            boxShadow: [
              BoxShadow(
                color: dt.currentNavy.withValues(alpha: 0.20),
                blurRadius: 40,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header
              _buildHeader(context),

              // Category Switcher Strip
              _buildCategoryTabs(),

              // Active Control Section Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: _buildActiveControls(),
                ),
              ),

              // Bottom Actions (Reset & Copy Code)
              _buildFooterActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 16),
      decoration: BoxDecoration(
        color: dt.currentNavy,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(26)),
        border: Border(bottom: BorderSide(color: dt.currentSecondary, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: dt.currentNavy,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: dt.currentSecondary, width: 1.2),
                ),
                child: Icon(Icons.tune_rounded, color: dt.currentSecondary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DIALKIT DESIGN TUNER",
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: dt.currentCream,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Live Medical Logistics Interface Studio",
                    style: TextStyle(
                      fontFamily: AppTypography.fontBody,
                      fontSize: 11,
                      color: dt.currentSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: dt.currentCream, size: 22),
            onPressed: () => dt.togglePanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {"icon": Icons.blur_on_rounded, "label": "Glass"},
      {"icon": Icons.layers_rounded, "label": "3D Tiles"},
      {"icon": Icons.public_rounded, "label": "Globe"},
      {"icon": Icons.dashboard_customize_rounded, "label": "Layout"},
      {"icon": Icons.code_rounded, "label": "Export"},
    ];

    return Container(
      height: 52,
      color: dt.currentNavy.withValues(alpha: 0.06),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _activeCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeCategoryIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? dt.currentNavy : dt.currentCream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? dt.currentSecondary : dt.currentSecondary.withValues(alpha: 0.4),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      categories[index]["icon"] as IconData,
                      size: 15,
                      color: isSelected ? dt.currentSecondary : dt.currentNavy,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      categories[index]["label"] as String,
                      style: TextStyle(
                        fontFamily: AppTypography.fontHeading,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? dt.currentCream : dt.currentNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveControls() {
    switch (_activeCategoryIndex) {
      case 0:
        return _buildGlassSurfaceControls();
      case 1:
        return _buildTileControls();
      case 2:
        return _buildGlobeControls();
      case 3:
        return _buildLayoutControls();
      case 4:
      default:
        return _buildExportAndDiffControls();
    }
  }

  // 1. GLASS SURFACE CONTROLS
  Widget _buildGlassSurfaceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Glass Surface Dynamics", "Tuning blur, translucency, and edge highlights"),
        const SizedBox(height: 14),

        _sliderRow(
          title: "Blur Strength",
          value: dt.glassBlur,
          min: 0.0,
          max: 40.0,
          unit: "px",
          onChanged: (v) => dt.updateGlass(blur: v),
        ),
        _sliderRow(
          title: "Surface Opacity",
          value: dt.glassSurfaceOpacity,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => dt.updateGlass(surfaceOpacity: v),
        ),
        _sliderRow(
          title: "Border Opacity",
          value: dt.glassBorderOpacity,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => dt.updateGlass(borderOpacity: v),
        ),
        _sliderRow(
          title: "Corner Radius",
          value: dt.glassCornerRadius,
          min: 8.0,
          max: 48.0,
          unit: "px",
          onChanged: (v) => dt.updateGlass(cornerRadius: v),
        ),
        _sliderRow(
          title: "Shadow Blur",
          value: dt.glassShadowBlur,
          min: 4.0,
          max: 60.0,
          unit: "px",
          onChanged: (v) => dt.updateGlass(shadowBlur: v),
        ),
        _sliderRow(
          title: "Shadow Opacity",
          value: dt.glassShadowOpacity,
          min: 0.0,
          max: 0.5,
          onChanged: (v) => dt.updateGlass(shadowOpacity: v),
        ),
      ],
    );
  }

  // 2. THREE-DIMENSIONAL TILES CONTROLS
  Widget _buildTileControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("3D Sculpted Tiles", "Elevation, lighting direction, and physical depth"),
        const SizedBox(height: 14),

        _sliderRow(
          title: "Tile Elevation",
          value: dt.tileElevation,
          min: 1.0,
          max: 10.0,
          onChanged: (v) => dt.updateTiles(elevation: v),
        ),
        _sliderRow(
          title: "Shadow Offset",
          value: dt.tileShadowOffset,
          min: 0.0,
          max: 24.0,
          unit: "px",
          onChanged: (v) => dt.updateTiles(shadowOffset: v),
        ),
        _sliderRow(
          title: "Highlight Intensity",
          value: dt.tileHighlightIntensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => dt.updateTiles(highlightIntensity: v),
        ),
        _sliderRow(
          title: "Tile Radius",
          value: dt.tileRadius,
          min: 8.0,
          max: 40.0,
          unit: "px",
          onChanged: (v) => dt.updateTiles(radius: v),
        ),
        _sliderRow(
          title: "Card Padding",
          value: dt.cardPadding,
          min: 10.0,
          max: 48.0,
          unit: "px",
          onChanged: (v) => dt.updateTiles(padding: v),
        ),
        _sliderRow(
          title: "Hover Scale Factor",
          value: dt.tileHoverScale,
          min: 1.0,
          max: 1.15,
          onChanged: (v) => dt.updateTiles(hoverScale: v),
        ),
      ],
    );
  }

  // 3. GLOBE ANIMATION CONTROLS
  Widget _buildGlobeControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("3D Globe & Scroll Animation", "Scroll ratio, sphere scale, and transit routes"),
        const SizedBox(height: 14),

        _sliderRow(
          title: "Rotation Range Multiplier",
          value: dt.globeRotationRange,
          min: 0.5,
          max: 5.0,
          unit: "x",
          onChanged: (v) => dt.updateGlobe(rotationRange: v),
        ),
        _sliderRow(
          title: "Globe Scale",
          value: dt.globeScale,
          min: 0.5,
          max: 2.0,
          unit: "x",
          onChanged: (v) => dt.updateGlobe(scale: v),
        ),
        _sliderRow(
          title: "Vertical Position (Y Offset)",
          value: dt.globeVerticalPosition,
          min: -100.0,
          max: 100.0,
          unit: "px",
          onChanged: (v) => dt.updateGlobe(verticalPosition: v),
        ),
        _sliderRow(
          title: "Route Visibility Opacity",
          value: dt.globeRouteVisibility,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => dt.updateGlobe(routeVisibility: v),
        ),
        _sliderRow(
          title: "Transition Duration",
          value: dt.globeTransitionTiming,
          min: 200.0,
          max: 2000.0,
          unit: "ms",
          onChanged: (v) => dt.updateGlobe(transitionTiming: v),
        ),
        const SizedBox(height: 12),

        // Easing Segmented Selector
        Text(
          "Animation Easing Curve",
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: dt.currentNavy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _easingButton("EaseInOut", DialKitEasing.easeInOut),
            const SizedBox(width: 6),
            _easingButton("FastOutSlowIn", DialKitEasing.fastOutSlowIn),
            const SizedBox(width: 6),
            _easingButton("Linear", DialKitEasing.linear),
          ],
        ),
      ],
    );
  }

  Widget _easingButton(String label, DialKitEasing easing) {
    final isSelected = dt.globeAnimationEasing == easing;
    return Expanded(
      child: InkWell(
        onTap: () => dt.updateGlobe(easing: easing),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? dt.currentNavy : dt.currentCream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? dt.currentSecondary : dt.currentSecondary.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? dt.currentCream : dt.currentNavy,
            ),
          ),
        ),
      ),
    );
  }

  // 4. LAYOUT CONTROLS
  Widget _buildLayoutControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Layout & Grid Spacing", "Container boundaries, section spacing, and nav bar height"),
        const SizedBox(height: 14),

        _sliderRow(
          title: "Max Content Width",
          value: dt.layoutContentWidth,
          min: 800.0,
          max: 1600.0,
          unit: "px",
          onChanged: (v) => dt.updateLayout(contentWidth: v),
        ),
        _sliderRow(
          title: "Section Spacing",
          value: dt.layoutSectionSpacing,
          min: 20.0,
          max: 140.0,
          unit: "px",
          onChanged: (v) => dt.updateLayout(sectionSpacing: v),
        ),
        _sliderRow(
          title: "Navigation Height",
          value: dt.layoutNavHeight,
          min: 56.0,
          max: 100.0,
          unit: "px",
          onChanged: (v) => dt.updateLayout(navHeight: v),
        ),
        _sliderRow(
          title: "Grid Gap",
          value: dt.layoutGridGap,
          min: 8.0,
          max: 40.0,
          unit: "px",
          onChanged: (v) => dt.updateLayout(gridGap: v),
        ),
        _sliderRow(
          title: "Min Card Width",
          value: dt.layoutCardSizing,
          min: 240.0,
          max: 450.0,
          unit: "px",
          onChanged: (v) => dt.updateLayout(cardSizing: v),
        ),
      ],
    );
  }

  // 5. EXPORT & DIFF CONTROLS
  Widget _buildExportAndDiffControls() {
    final dartCode = dt.exportToDartCode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Version Diff & Production Export", "Inspect tuned tokens or copy constants"),
        const SizedBox(height: 14),

        // Palette Preset Selector
        Text(
          "Color Palette Preset",
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: dt.currentNavy,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _presetChip(
                "Tri-Tone Core (#0F357C, #FFFEDF, #86CAF3)",
                "Tri-Tone Core",
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _presetChip(
                "Velvet Botanical (#502D55, #935073, #F6DBC0)",
                "Velvet Botanical",
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Live Token Export Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dt.currentNavy,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: dt.currentSecondary, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "GENERATED DART TOKENS",
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: dt.currentSecondary,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: dartCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: dt.currentNavy,
                          behavior: SnackBarBehavior.floating,
                          content: const Text("Copied Dart tokens to clipboard!"),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: dt.currentCream, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "COPY",
                          style: TextStyle(
                            fontFamily: AppTypography.fontBody,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: dt.currentCream,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                dartCode,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: dt.currentCream.withValues(alpha: 0.9),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetChip(String label, String presetId) {
    final isSelected = dt.activePalettePreset == presetId;
    return InkWell(
      onTap: () => dt.setPalettePreset(presetId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? dt.currentNavy : dt.currentCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? dt.currentSecondary : dt.currentSecondary.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? dt.currentCream : dt.currentNavy,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTypography.fontHeading,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: dt.currentNavy,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: AppTypography.fontBody,
            fontSize: 12,
            color: dt.currentNavy.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _sliderRow({
    required String title,
    required double value,
    required double min,
    required double max,
    String unit = "",
    required ValueChanged<double> onChanged,
  }) {
    final displayStr = unit.isEmpty
        ? value.toStringAsFixed(2)
        : "${value.toStringAsFixed(1)} $unit";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: dt.currentNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: dt.currentNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  displayStr,
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: dt.currentNavy,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: dt.currentNavy,
              inactiveTrackColor: dt.currentSecondary.withValues(alpha: 0.4),
              thumbColor: dt.currentNavy,
              overlayColor: dt.currentSecondary.withValues(alpha: 0.2),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dt.currentCream,
        border: Border(top: BorderSide(color: dt.currentSecondary.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                dt.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: dt.currentNavy,
                    content: const Text("Tuning restored to initial defaults!"),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: dt.currentNavy,
                side: BorderSide(color: dt.currentNavy),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Reset Defaults"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: dt.exportToDartCode()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: dt.currentNavy,
                    content: const Text("Copied Dart configuration to clipboard!"),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dt.currentNavy,
                foregroundColor: dt.currentCream,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Copy Config"),
            ),
          ),
        ],
      ),
    );
  }
}
