import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedTopDockWidget extends StatefulWidget {
  final ValueChanged<String>? onItemSelected;
  final double width;
  final double height;

  const AnimatedTopDockWidget({
    super.key,
    this.onItemSelected,
    this.width = 710,
    this.height = 56,
  });

  @override
  State<AnimatedTopDockWidget> createState() => _AnimatedTopDockWidgetState();
}

class _DockItemData {
  final String id;
  final String label;
  final IconData icon;

  const _DockItemData(this.id, this.label, this.icon);
}

class _AnimatedTopDockWidgetState extends State<AnimatedTopDockWidget>
    with SingleTickerProviderStateMixin {
  static const List<_DockItemData> _items = [
    _DockItemData('system', 'SYSTEM', Icons.grid_view_rounded),
    _DockItemData('method', 'METHOD', Icons.alt_route_rounded),
    _DockItemData('work', 'WORK', Icons.local_hospital_rounded),
    _DockItemData('access', 'ACCESS', Icons.emergency_share_rounded),
    _DockItemData('notes', 'NOTES', Icons.radar_rounded),
  ];

  String _activeId = 'system';
  late AnimationController _ticker;

  final List<double> _values = List.filled(6, 0.0);
  final List<double> _velocities = List.filled(6, 0.0);
  final List<double> _targets = List.filled(6, 0.0);

  static const double _proximity = 122.0;
  static const double _spring = 0.19;
  static const double _damping = 0.70;
  static const double _widthGrowth = 17.0;
  static const double _heightGrowth = 16.0;
  static const double _drop = 3.5;

  final GlobalKey _dockKey = GlobalKey();
  final List<GlobalKey> _itemKeys = List.generate(6, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(_tickSprings);
  }

  @override
  void dispose() {
    _ticker.removeListener(_tickSprings);
    _ticker.dispose();
    super.dispose();
  }

  void _tickSprings() {
    bool isMoving = false;
    for (int i = 0; i < 6; i++) {
      _velocities[i] += (_targets[i] - _values[i]) * _spring;
      _velocities[i] *= _damping;
      _values[i] += _velocities[i];
      if ((_targets[i] - _values[i]).abs() < 0.001 && _velocities[i].abs() < 0.001) {
        _values[i] = _targets[i];
        _velocities[i] = 0.0;
      } else {
        isMoving = true;
      }
    }
    if (mounted) setState(() {});
    if (!isMoving && _ticker.isAnimating) {
      _ticker.stop();
    }
  }

  void _ensureAnimating() {
    if (!_ticker.isAnimating) {
      _ticker.repeat(period: const Duration(seconds: 1));
    }
  }

  void _onPointerHover(PointerEvent event) {
    for (int i = 0; i < 6; i++) {
      final key = _itemKeys[i];
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final center = renderBox.localToGlobal(Offset(renderBox.size.width / 2, 0)).dx;
        final d = (event.position.dx - center).abs();
        final p = (1.0 - d / _proximity).clamp(0.0, 1.0);
        final influence = p * p * (3.0 - 2.0 * p);
        _targets[i] = influence;
      }
    }
    _ensureAnimating();
  }

  void _onPointerExit(PointerEvent event) {
    for (int i = 0; i < 6; i++) {
      _targets[i] = 0.0;
    }
    _ensureAnimating();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MouseRegion(
        onHover: _onPointerHover,
        onExit: _onPointerExit,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              key: _dockKey,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x142A1635),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  _buildLogoItem(0),
                  const SizedBox(width: 5),
                  // Items
                  for (int i = 0; i < _items.length; i++) ...[
                    _buildLinkItem(i + 1, _items[i]),
                    if (i < _items.length - 1) const SizedBox(width: 5),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoItem(int index) {
    final v = _values[index].clamp(0.0, 1.08);
    final width = 34.0 + _widthGrowth * (14.0 / 17.0) * v;
    final height = 34.0 + _heightGrowth * (14.0 / 16.0) * v;
    final drop = v * _drop;

    return Transform.translate(
      offset: Offset(0, drop),
      child: InkWell(
        key: _itemKeys[index],
        onTap: () {
          widget.onItemSelected?.call('home');
        },
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1635), Color(0xFF4D265C)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE89D7E).withValues(alpha: 0.75), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332A1635),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.emergency_rounded, size: 16, color: Color(0xFFFAF7F2)),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkItem(int index, _DockItemData item) {
    final v = _values[index].clamp(0.0, 1.08);
    final isActive = _activeId == item.id;
    final extraWidth = (114.0 * 0.20).clamp(0.0, _widthGrowth);
    final width = 114.0 + extraWidth * v;
    final height = 34.0 + _heightGrowth * v;
    final drop = v * _drop;
    final isNear = v > 0.08;

    Color bg;
    Color textColor;
    Color borderColor;

    if (isActive) {
      bg = const Color(0xFF2A1635);
      textColor = const Color(0xFFFAF7F2);
      borderColor = const Color(0xFFE89D7E);
    } else if (isNear) {
      bg = Colors.white.withValues(alpha: 0.95);
      textColor = const Color(0xFF2A1635);
      borderColor = const Color(0xFFE89D7E).withValues(alpha: 0.95);
    } else {
      bg = Colors.white.withValues(alpha: 0.60);
      textColor = const Color(0xFF381E46);
      borderColor = Colors.white.withValues(alpha: 0.85);
    }

    return Transform.translate(
      offset: Offset(0, drop),
      child: InkWell(
        key: _itemKeys[index],
        onTap: () {
          setState(() => _activeId = item.id);
          widget.onItemSelected?.call(item.id);
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: isNear || isActive
                ? [
                    BoxShadow(
                      color: isActive
                          ? const Color(0x402A1635)
                          : const Color(0x3AE89D7E),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0A2A1635),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 14,
                color: isActive
                    ? const Color(0xFFE89D7E)
                    : (isNear ? const Color(0xFFE89D7E) : textColor.withValues(alpha: 0.75)),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
