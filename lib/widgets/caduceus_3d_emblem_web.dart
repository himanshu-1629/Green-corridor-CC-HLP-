// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _caduceusRegistered = false;
const String _caduceusViewType = 'green-corridor-caduceus-3d-view';
html.IFrameElement? _activeIframe;

void updateCaduceusScroll(double progress, {double? opacity}) {
  try {
    if (opacity != null && _activeIframe != null) {
      _activeIframe!.style.opacity = opacity.clamp(0.0, 1.0).toStringAsFixed(3);
    }
    _activeIframe?.contentWindow?.postMessage({
      'type': 'SCROLL_UPDATE',
      'scrollProgress': progress,
      'opacity': opacity,
    }, '*');
  } catch (_) {}
}

Widget buildCaduceusWebPlatformView(double width, double height) {
  if (!_caduceusRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      _caduceusViewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'caduceus-emblem.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent'
          ..style.overflow = 'hidden'
          ..style.pointerEvents = 'none'
          ..style.opacity = '0'
          ..allow = 'autoplay';
        _activeIframe = iframe;
        return iframe;
      },
    );
    _caduceusRegistered = true;
  }

  // On Web, return strictly non-interactive background platform view
  return IgnorePointer(
    child: SizedBox(
      width: width,
      height: height,
      child: const HtmlElementView(viewType: _caduceusViewType),
    ),
  );
}
