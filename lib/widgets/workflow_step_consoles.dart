import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Interactive cyber-physical mini-consoles embedded inside each of the 4 "How It Works" workflow cards.
/// Medical-grade executive hospital admin interface styled with Navy Blue, Pale Cream, and Sky Blue.
class WorkflowStepConsole extends StatefulWidget {
  final String stepNum;
  final Color accentColor;

  const WorkflowStepConsole({
    super.key,
    required this.stepNum,
    required this.accentColor,
  });

  @override
  State<WorkflowStepConsole> createState() => _WorkflowStepConsoleState();
}

class _WorkflowStepConsoleState extends State<WorkflowStepConsole>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

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
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.sky,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          switch (widget.stepNum) {
            case '01':
              return _buildStepOneSosConsole();
            case '02':
              return _buildStepTwoSignalPreemptionConsole();
            case '03':
              return _buildStepThreeAcousticRadarConsole();
            case '04':
              return _buildStepFourTraumaEcgConsole();
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  // ==========================================
  // STEP 01: SOS & GPS TRILATERATION CONSOLE
  // ==========================================
  Widget _buildStepOneSosConsole() {
    final double t = _animController.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live SOS Dispatch Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(
                          alpha: 0.5 + 0.5 * math.sin(t * 2 * math.pi),
                        ),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SOS 911 / 108 ACTIVE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFCA5A5),
                ),
              ),
              child: Text(
                'PRIORITY 1',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Visual Radar Pulse Screen
        Container(
          height: 64,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.sky.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid crosshairs
              CustomPaint(
                size: const Size(double.infinity, 64),
                painter: _RadarGridPainter(progress: t),
              ),
              // Center blinking vehicle beacon
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 8),
              ),
              // Dispatch GPS Pill
              Positioned(
                bottom: 6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.sky.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    'LAT 37.7749° LON -122.4194°',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Telemetry readout
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniMetric(
              label: 'DISPATCH SYNC',
              value: '142ms',
              valueColor: AppColors.navy,
            ),
            _buildMiniMetric(
              label: 'DISPATCHED UNIT',
              value: 'AMB-MED-04',
              valueColor: AppColors.navy,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 02: AI SIGNAL PREEMPTION & HUD CONSOLE
  // ==========================================
  Widget _buildStepTwoSignalPreemptionConsole() {
    final double t = _animController.value;
    final int countdown = 40 - (t * 15).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Green Wave Preemption Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'GREEN-WAVE ACTIVE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF6EE7B7),
                ),
              ),
              child: Text(
                'T-${countdown}s LOCK',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Traffic Light & Corridor Corridor Flow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.sky.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Mini Traffic Light Housing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.creamDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sky, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Red (Off)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFECACA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Amber (Off)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Green (Pulsing bright ON)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.6 + 0.4 * math.sin(t * 4 * math.pi),
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Signal Preemption Telemetry
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INTERSECTION #04 CLEARED',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI phase override engaged (zero stopping)',
                      style: AppFonts.neueMontreal(
                        fontSize: 9,
                        color: AppColors.navyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Pilot HUD speed recommendation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniMetric(
              label: 'TARGET VELOCITY',
              value: '82 km/h',
              valueColor: AppColors.navy,
            ),
            _buildMiniMetric(
              label: 'SIGNALS SYNCED',
              value: '12 / 12',
              valueColor: AppColors.navy,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 03: ACOUSTIC RADAR & CITIZEN YIELD CONSOLE
  // ==========================================
  Widget _buildStepThreeAcousticRadarConsole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Acoustic siren warning header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withValues(alpha: 0.9),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'V2X SIREN RADAR (800m)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.skyLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.sky,
                ),
              ),
              child: Text(
                'LANE CLEAR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Driver mobile alert HUD preview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.sky.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Animated sound wave icon
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.skyLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_tethering_rounded,
                  color: AppColors.navy,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 AMBULANCE 450M BEHIND',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Civilians alerted via Push/GPS: Merged Right',
                      style: AppFonts.neueMontreal(
                        fontSize: 9,
                        color: AppColors.navyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Compliance metric
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniMetric(
              label: 'VEHICLES CLEARED',
              value: '42 Cars',
              valueColor: AppColors.navy,
            ),
            _buildMiniMetric(
              label: 'LANE COMPLIANCE',
              value: '99.4%',
              valueColor: AppColors.navy,
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 04: REAL-TIME ECG & TRAUMA BAY INGESTION CONSOLE
  // ==========================================
  Widget _buildStepFourTraumaEcgConsole() {
    final double t = _animController.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live trauma bay header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.9),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TRAUMA BAY 01 LOCKED',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF6EE7B7),
                ),
              ),
              child: Text(
                'TEAM READY',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Real-time animated ECG rhythm wave
        Container(
          height: 48,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.sky.withValues(alpha: 0.5),
            ),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 48),
            painter: _EcgWavePainter(sweepProgress: t),
          ),
        ),
        const SizedBox(height: 10),

        // Live clinical patient vitals
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniMetric(
              label: 'HR PULSE',
              value: '76 BPM',
              valueColor: AppColors.navy,
            ),
            _buildMiniMetric(
              label: 'SPO2 LEVEL',
              value: '99%',
              valueColor: AppColors.navy,
            ),
            _buildMiniMetric(
              label: 'DOOR-TO-CT',
              value: '0 MIN DELAY',
              valueColor: AppColors.navy,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: AppColors.navyMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for Step 01 Radar crosshairs and pulse rings (Clean Light Medical)
class _RadarGridPainter extends CustomPainter {
  final double progress;

  _RadarGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    // Crosshairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), linePaint);

    // Expanding concentric radar rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + (i * 0.33)) % 1.0;
      final radius = ringProgress * (size.height * 0.7);
      final alpha = (1.0 - ringProgress).clamp(0.0, 1.0);

      final ringPaint = Paint()
        ..color = AppColors.navy.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter for Step 04 continuous animated ECG cardiac wave (Clean Light Medical)
class _EcgWavePainter extends CustomPainter {
  final double sweepProgress;

  _EcgWavePainter({required this.sweepProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final midY = height / 2;

    // Background grid dots
    final gridPaint = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (double x = 0; x < width; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // ECG waveform path
    final wavePath = Path();
    wavePath.moveTo(0, midY);

    final numPoints = 80;
    for (int i = 0; i <= numPoints; i++) {
      final double x = (i / numPoints) * width;
      // Cycle through ECG pattern: baseline -> P wave -> Q dip -> R spike -> S drop -> T wave -> baseline
      final double normalized = ((x / 90.0) - (sweepProgress * 2.0)) % 1.0;
      double yOffset = 0;

      if (normalized > 0.15 && normalized < 0.25) {
        // P-wave
        yOffset = -3.5 * math.sin((normalized - 0.15) / 0.10 * math.pi);
      } else if (normalized >= 0.25 && normalized < 0.28) {
        // Q dip
        yOffset = 3.0;
      } else if (normalized >= 0.28 && normalized < 0.33) {
        // R spike
        final spikeNorm = (normalized - 0.28) / 0.05;
        yOffset = -18.0 * math.sin(spikeNorm * math.pi);
      } else if (normalized >= 0.33 && normalized < 0.37) {
        // S dip
        yOffset = 4.0;
      } else if (normalized >= 0.45 && normalized < 0.60) {
        // T wave
        yOffset = -5.0 * math.sin((normalized - 0.45) / 0.15 * math.pi);
      }

      wavePath.lineTo(x, midY + yOffset);
    }

    // Draw glowing shadow
    final glowPaint = Paint()
      ..color = AppColors.sky.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(wavePath, glowPaint);

    // Draw crisp core wave in Navy Blue
    final corePaint = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(wavePath, corePaint);

    // Sweep cursor line
    final double sweepX = sweepProgress * width;
    final sweepPaint = Paint()
      ..color = AppColors.sky
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(sweepX, 4), Offset(sweepX, height - 4), sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _EcgWavePainter oldDelegate) =>
      oldDelegate.sweepProgress != sweepProgress;
}
