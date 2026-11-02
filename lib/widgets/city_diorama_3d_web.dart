// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

bool _cityDioramaRegistered = false;
const String _cityDioramaViewType = 'green-corridor-city-diorama-view';
html.IFrameElement? _activeCityIframe;

void updateCityDioramaScroll(double progress) {
  try {
    _activeCityIframe?.contentWindow?.postMessage({
      'type': 'SCROLL_UPDATE',
      'scrollProgress': progress,
    }, '*');
  } catch (_) {}
}

bool _wheelListenerAttached = false;

void _ensureWheelListener() {
  if (_wheelListenerAttached) return;
  html.window.addEventListener('message', (event) {
    if (event is html.MessageEvent && event.data is Map) {
      final data = event.data as Map;
      if (data['type'] == 'GC_FORWARD_WHEEL') {
        final num? dy = data['deltaY'] as num?;
        if (dy != null) {
          html.window.scrollBy(0, dy.toInt());
        }
      }
    }
  });
  _wheelListenerAttached = true;
}

Widget buildCityDioramaWebPlatformView(double width, double height) {
  _ensureWheelListener();
  if (!_cityDioramaRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      _cityDioramaViewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'city-diorama.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent'
          ..style.overflow = 'hidden'
          ..allow = 'autoplay';
        _activeCityIframe = iframe;
        return iframe;
      },
    );
    _cityDioramaRegistered = true;
  }

  return SizedBox(
    width: width,
    height: height,
    child: const HtmlElementView(viewType: _cityDioramaViewType),
  );
}
