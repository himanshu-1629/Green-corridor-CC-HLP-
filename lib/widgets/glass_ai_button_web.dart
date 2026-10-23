// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class GlassAiButtonWidget extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onPressed;

  const GlassAiButtonWidget({
    super.key,
    this.width = 460,
    this.height = 150,
    this.onPressed,
  });

  @override
  State<GlassAiButtonWidget> createState() => _GlassAiButtonWidgetState();
}

class _GlassAiButtonWidgetState extends State<GlassAiButtonWidget> {
  static bool _registered = false;
  static const String _viewType = 'glass-ai-button-threejs-view';

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = 'glass-ai-button.html'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.backgroundColor = 'transparent'
            ..style.overflow = 'hidden'
            ..allow = 'autoplay';
          return iframe;
        },
      );
      _registered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: const HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
