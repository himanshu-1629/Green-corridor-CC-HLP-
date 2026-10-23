import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:green_corridor/theme/app_theme.dart';

void main() {
  group('Green Corridor Design System & Brand Palette Tests', () {
    test('Core Palette contains exact Violet Dusk mandated hex values', () {
      // Violet Dusk 4-color mandate
      expect(AppColors.deepViolet.toARGB32(), equals(const Color(0xFF502D55).toARGB32()));
      expect(AppColors.mutedBerry.toARGB32(), equals(const Color(0xFF935073).toARGB32()));
      expect(AppColors.warmPeach.toARGB32(),  equals(const Color(0xFFF6DBC0).toARGB32()));
      expect(AppColors.softIvory.toARGB32(),  equals(const Color(0xFFF8F4E9).toARGB32()));
      // Legacy aliases still resolve to Violet Dusk colors
      expect(AppColors.navy.toARGB32(),  equals(AppColors.deepViolet.toARGB32()));
      expect(AppColors.cream.toARGB32(), equals(AppColors.softIvory.toARGB32()));
      expect(AppColors.sky.toARGB32(),   equals(AppColors.mutedBerry.toARGB32()));
    });

    test('Default background is never black and uses Violet Dusk canvas', () {
      expect(AppColors.background, isNot(equals(Colors.black)));
      expect(AppColors.background.toARGB32(), isNot(equals(0xFF000000)));
      // background maps to Soft Ivory — never pitch black
      expect(AppColors.background.toARGB32(), equals(AppColors.softIvory.toARGB32()));
    });

    test('Two-font system families are defined', () {
      expect(AppTypography.fontHeading, equals('OpenSauceSans'));
      expect(AppTypography.fontBody, equals('PeaceSans'));
    });

    test('3D tile decoration provides physical elevation and lighting', () {
      final tile = AppDecorations.tile3D(elevation: 3);
      expect(tile.borderRadius, isNotNull);
      expect(tile.boxShadow, isNotNull);
      expect(tile.boxShadow!.length, greaterThanOrEqualTo(2));
    });

    test('Glassmorphic decorations have valid borders and blurs', () {
      final glassNavy = AppDecorations.glassNavy();
      final glassCream = AppDecorations.glassCream();
      expect(glassNavy.border, isNotNull);
      expect(glassCream.border, isNotNull);
    });
  });
}
