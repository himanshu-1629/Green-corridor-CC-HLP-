// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Conditional web platform import
import 'city_diorama_3d_web.dart'
    if (dart.library.io) 'city_diorama_3d_stub.dart' as platform_impl;

/// Three-Dimensional Emergency City Diorama
/// Miniature isometric world rendered via Three.js WebGL featuring:
/// - Recognizable multi-storey hospital landmark with rooftop helipad & ER dock
/// - Road network, intersections, sidewalks, and crosswalks
/// - Miniature ambulances with emergency accents and rooftop strobes
/// - Glowing orange active corridor ribbon (#FF6D29) with transit pulses
/// - Signal preemption nodes and floating 3D HUD annotations
class CityDiorama3D extends StatefulWidget {
  final double? width;
  final double height;
  final double scrollProgress;

  const CityDiorama3D({
    super.key,
    this.width,
    this.height = 560,
    this.scrollProgress = 0.0,
  });

  @override
  State<CityDiorama3D> createState() => _CityDiorama3DState();
}

class _CityDiorama3DState extends State<CityDiorama3D> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      platform_impl.updateCityDioramaScroll(widget.scrollProgress);
    }
  }

  @override
  void didUpdateWidget(covariant CityDiorama3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollProgress != oldWidget.scrollProgress && kIsWeb) {
      platform_impl.updateCityDioramaScroll(widget.scrollProgress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (widget.width ?? 680.0);
        final renderHeight = widget.height;

        if (kIsWeb) {
          return SizedBox(
            width: renderWidth,
            height: renderHeight,
            child: platform_impl.buildCityDioramaWebPlatformView(
              renderWidth,
              renderHeight,
            ),
          );
        }

        // Native platform graceful fallback
        return Container(
          width: renderWidth,
          height: renderHeight,
          decoration: BoxDecoration(
            color: AppColors.greyFaint,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_city_rounded, size: 48, color: AppColors.orange),
                SizedBox(height: 12),
                Text(
                  '3D Emergency City Diorama',
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.nearBlack,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
