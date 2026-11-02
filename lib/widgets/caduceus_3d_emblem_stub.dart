import 'package:flutter/material.dart';
import 'caduceus_3d_emblem.dart';

Widget buildCaduceusWebPlatformView(double width, double height) {
  return CustomPaint(
    size: Size(width, height),
    painter: CaduceusSculptedVectorPainter(),
  );
}

void updateCaduceusScroll(double progress, {double? opacity}) {}
