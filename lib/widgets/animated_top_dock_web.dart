// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class AnimatedTopDockWidget extends StatefulWidget {
  final ValueChanged<String>? onItemSelected;
  final double width;
  final double height;

  const AnimatedTopDockWidget({
    super.key,
    this.onItemSelected,
    this.width = 620,
    this.height = 76,
  });

  @override
  State<AnimatedTopDockWidget> createState() => _AnimatedTopDockWidgetState();
}

class _AnimatedTopDockWidgetState extends State<AnimatedTopDockWidget> {
  static bool _registered = false;
  static const String _viewType = 'threeui-animated-top-dock-view';
  StreamSubscription<html.MessageEvent>? _messageSub;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = 'animated-top-dock.html'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = 'transparent'
            ..style.overflow = 'visible'
            ..allow = 'autoplay';
          return iframe;
        },
      );
      _registered = true;
    }

    _messageSub = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data != null && data is Map) {
        if (data['type'] == 'dock_navigate') {
          final id = data['id']?.toString() ?? '';
          if (mounted && widget.onItemSelected != null) {
            widget.onItemSelected!(id);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: const HtmlElementView(viewType: _viewType),
    );
  }
}
