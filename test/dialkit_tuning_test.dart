import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_corridor/theme/app_theme.dart';
import 'package:green_corridor/theme/design_tuning_controller.dart';
import 'package:green_corridor/widgets/dialkit_tuning_panel.dart';

void main() {
  group('DialKit Interactive Design Tuning Controller Tests', () {
    late DesignTuningController controller;

    setUp(() {
      controller = DesignTuningController.instance;
      controller.resetToDefaults();
    });

    test('Initial defaults match approved design specifications', () {
      // 1. Glass Surface
      expect(controller.glassBlur, 20.0);
      expect(controller.glassSurfaceOpacity, 0.28);
      expect(controller.glassBorderOpacity, 0.70);
      expect(controller.glassCornerRadius, 28.0);
      expect(controller.glassShadowBlur, 32.0);
      expect(controller.glassShadowOpacity, 0.14);

      // 2. Three-Dimensional Tiles
      expect(controller.tileElevation, 3.0);
      expect(controller.tileShadowOffset, 8.0);
      expect(controller.tileHighlightIntensity, 0.70);
      expect(controller.tileRadius, 22.0);
      expect(controller.tileCardPadding, 24.0);
      expect(controller.tileHoverScale, 1.03);

      // 3. Globe Animation
      expect(controller.globeRotationRange, 1.6);
      expect(controller.globeScale, 1.0);
      expect(controller.globeVerticalPosition, 0.0);
      expect(controller.globeRouteVisibility, 1.0);
      expect(controller.globeAnimationEasing, DialKitEasing.easeInOut);
      expect(controller.globeTransitionTiming, 600.0);

      // 4. Layout
      expect(controller.layoutContentWidth, 1240.0);
      expect(controller.layoutSectionSpacing, 64.0);
      expect(controller.layoutNavHeight, 72.0);
      expect(controller.layoutGridGap, 20.0);
      expect(controller.layoutCardSizing, 320.0);
    });

    test('Updating Glass Surface triggers notification and diff tracking', () {
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.updateGlassSurface(
        blur: 24.0,
        surfaceOpacity: 0.88,
        borderOpacity: 0.65,
        cornerRadius: 32.0,
        shadowBlur: 44.0,
        shadowOpacity: 0.14,
      );

      expect(notifyCount, 1);
      expect(controller.glassBlur, 24.0);
      expect(controller.glassSurfaceOpacity, 0.88);
      expect(controller.glassBorderOpacity, 0.65);
      expect(controller.glassCornerRadius, 32.0);
      expect(controller.glassShadowBlur, 44.0);
      expect(controller.glassShadowOpacity, 0.14);

      final diffs = controller.getDiffsFromDefaults();
      expect(diffs.containsKey('glassBlur'), isTrue);
      expect(diffs['glassBlur']!['current'], 24.0);
    });

    test('Updating 3D Tiles modifies elevation and hover scale', () {
      controller.update3DTiles(
        elevation: 6.0,
        shadowOffset: 14.0,
        highlightIntensity: 0.90,
        radius: 26.0,
        padding: 30.0,
        hoverScale: 1.08,
      );

      expect(controller.tileElevation, 6.0);
      expect(controller.tileShadowOffset, 14.0);
      expect(controller.tileHighlightIntensity, 0.90);
      expect(controller.tileRadius, 26.0);
      expect(controller.tileCardPadding, 30.0);
      expect(controller.tileHoverScale, 1.08);
    });

    test('Updating Globe Animation controls modifies scale, route, and timing', () {
      controller.updateGlobeAnimation(
        rotationRange: 2.5,
        scale: 1.3,
        verticalPosition: 25.0,
        routeVisibility: 0.85,
        easing: DialKitEasing.fastOutSlowIn,
        transitionTiming: 1800.0,
      );

      expect(controller.globeRotationRange, 2.5);
      expect(controller.globeScale, 1.3);
      expect(controller.globeVerticalPosition, 25.0);
      expect(controller.globeRouteVisibility, 0.85);
      expect(controller.globeAnimationEasing, DialKitEasing.fastOutSlowIn);
      expect(controller.globeTransitionTiming, 1800.0);
    });

    test('Updating Layout controls updates dimensions', () {
      controller.updateLayout(
        contentWidth: 1400.0,
        sectionSpacing: 120.0,
        navHeight: 80.0,
        gridGap: 32.0,
        cardSizing: 350.0,
      );

      expect(controller.layoutContentWidth, 1400.0);
      expect(controller.layoutSectionSpacing, 120.0);
      expect(controller.layoutNavHeight, 80.0);
      expect(controller.layoutGridGap, 32.0);
      expect(controller.layoutCardSizing, 350.0);
    });

    test('Active color preset applies approved Neue Montreal 5 brand colors', () {
      expect(controller.currentNavy.toARGB32(), AppColors.nearBlack.toARGB32());
      expect(controller.currentSecondary.toARGB32(), AppColors.brown.toARGB32());
      expect(controller.currentAccentWarm.toARGB32(), AppColors.orange.toARGB32());
      expect(controller.currentCream.toARGB32(), AppColors.white.toARGB32());

      // Ensure NO black backgrounds exist
      expect(controller.currentCream.toARGB32() != const Color(0xFF000000).toARGB32(), isTrue);
    });

    test('Export to Dart code generates valid compile-ready tokens', () {
      final dartCode = controller.exportToDartCode();
      expect(dartCode.contains('class AppTunedTokens'), isTrue);
      expect(dartCode.contains('glassBlur'), isTrue);
      expect(dartCode.contains('tileElevation'), isTrue);
      expect(dartCode.contains('globeScale'), isTrue);
      expect(dartCode.contains('layoutContentWidth'), isTrue);
    });

    test('Export to JSON generates valid JSON object string', () {
      final jsonCode = controller.exportToJson();
      expect(jsonCode.contains('"blur":'), isTrue);
      expect(jsonCode.contains('"elevation":'), isTrue);
      expect(jsonCode.contains('"scale":'), isTrue);
      expect(jsonCode.contains('"contentWidth":'), isTrue);
    });

    test('Reset to defaults clears diffs', () {
      controller.updateGlassSurface(blur: 30.0);
      expect(controller.getDiffsFromDefaults().isNotEmpty, isTrue);

      controller.resetToDefaults();
      expect(controller.getDiffsFromDefaults().isEmpty, isTrue);
      expect(controller.glassBlur, 20.0);
    });
  });

  group('DialKit Overlay Widget Tests', () {
    testWidgets('Renders child content normally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DialKitTuningOverlay(
            child: const Scaffold(
              body: Center(child: Text('Green Corridor Application')),
            ),
          ),
        ),
      );

      expect(find.text('Green Corridor Application'), findsOneWidget);
    });
  });
}
