import 'package:flutter/material.dart';

class GlassAiButtonWidget extends StatefulWidget {
  final double width;
  final double height;
  final VoidCallback? onPressed;

  const GlassAiButtonWidget({
    super.key,
    this.width = 380,
    this.height = 120,
    this.onPressed,
  });

  @override
  State<GlassAiButtonWidget> createState() => _GlassAiButtonWidgetState();
}

class _GlassAiButtonWidgetState extends State<GlassAiButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: _isHovered ? 0.35 : 0.22),
                const Color(0xFF502D55).withValues(alpha: 0.15),
                const Color(0xFF1E3A8A).withValues(alpha: 0.25),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: _isHovered ? 0.45 : 0.2),
                blurRadius: _isHovered ? 32 : 20,
                spreadRadius: _isHovered ? 4 : 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: _isHovered ? 0.8 : 0.4),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Galaxy Orb Simulation
              Positioned(
                left: 24,
                child: Container(
                  width: widget.height * 0.65,
                  height: widget.height * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF60A5FA),
                        Color(0xFF2563EB),
                        Color(0xFF1E1B4B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // Typography
              const Positioned(
                left: 110,
                child: Text(
                  'GPT 6 Sol',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Brain / Tech Icon
              const Positioned(
                right: 28,
                child: Icon(
                  Icons.psychology_outlined,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
