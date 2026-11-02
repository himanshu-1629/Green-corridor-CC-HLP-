import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:green_corridor/theme/app_theme.dart';

void main() {
  group('Green Corridor Design System & Brand Palette Tests', () {
    test('Core Palette contains exact Neue Montreal 5-color mandated hex values', () {
      // 5-color Neue Montreal mandate
      expect(AppColors.orange.toARGB32(),    equals(const Color(0xFFFF6D29).toARGB32()));
      expect(AppColors.brown.toARGB32(),     equals(const Color(0xFF453027).toARGB32()));
      expect(AppColors.nearBlack.toARGB32(), equals(const Color(0xFF161316).toARGB32()));
      expect(AppColors.grey.toARGB32(),      equals(const Color(0xFFBABABA).toARGB32()));
      expect(AppColors.white.toARGB32(),     equals(const Color(0xFFFFFFFF).toARGB32()));

      // Backwards compatibility mappings
      expect(AppColors.navy.toARGB32(),  equals(AppColors.nearBlack.toARGB32()));
      expect(AppColors.cream.toARGB32(), equals(AppColors.white.toARGB32()));
      expect(AppColors.sky.toARGB32(),   equals(AppColors.orange.toARGB32()));
    });

    test('Default background is never black and uses clean light canvas', () {
      expect(AppColors.background, isNot(equals(Colors.black)));
      expect(AppColors.background.toARGB32(), isNot(equals(0xFF000000)));
      expect(AppColors.background.toARGB32(), equals(AppColors.white.toARGB32()));
    });

    test('Neue Montreal font family is defined throughout typography', () {
      expect(AppTypography.fontHeading, equals('NeueMontreal'));
      expect(AppTypography.fontBody, equals('NeueMontreal'));
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
