import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/design_tuning_controller.dart';

/// Real-world premier hospital node on the global trauma grid
class GlobalHospitalNode {
  final String id;
  final String name;
  final String city;
  final String country;
  final String flag;
  final double lat;
  final double lng;
  final String traumaRank;
  final String specialty;
  final String activeCorridors;
  final String preemptionLatency;
  final String bayReadiness;
  final Color accentColor;

  const GlobalHospitalNode({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.flag,
    required this.lat,
    required this.lng,
    required this.traumaRank,
    required this.specialty,
    required this.activeCorridors,
    required this.preemptionLatency,
    required this.bayReadiness,
    required this.accentColor,
  });
}

/// 10 Real-World Premier Hospitals Across The Globe
const List<GlobalHospitalNode> kGlobalHospitals = [
  GlobalHospitalNode(
    id: 'mayo',
    name: 'Mayo Clinic',
    city: 'Rochester, MN',
    country: 'United States',
    flag: '🇺🇸',
    lat: 44.0225,
    lng: -92.4666,
    traumaRank: '#1 Ranked Hospital in the World',
    specialty: 'Level-1 Comprehensive Adult & Pediatric Trauma',
    activeCorridors: 'Organ Transit & Cold Ischemia Sync',
    preemptionLatency: '0.0ms Cloud Latency',
    bayReadiness: 'Trauma Bay 1 & 2 Sterile',
    accentColor: AppColors.emerald,
  ),
  GlobalHospitalNode(
    id: 'cleveland',
    name: 'Cleveland Clinic',
    city: 'Cleveland, OH',
    country: 'United States',
    flag: '🇺🇸',
    lat: 41.5036,
    lng: -81.6215,
    traumaRank: 'Global Leader in Cardiovascular Care',
    specialty: 'Acute STEMI Code Red & Resuscitation Center',
    activeCorridors: 'Dynamic Arterial Signal Override',
    preemptionLatency: '0.0ms Cloud Latency',
    bayReadiness: 'Cath Lab 3 Pre-Armed',
    accentColor: Color(0xFF06B6D4), // Cyan
  ),
  GlobalHospitalNode(
    id: 'charite',
    name: 'Charité – Universitätsmedizin',
    city: 'Berlin',
    country: 'Germany',
    flag: '🇩🇪',
    lat: 52.5258,
    lng: 13.3777,
    traumaRank: "Europe's Largest University Medical Center",
    specialty: 'Cross-Jurisdiction Tele-Trauma Grid',
    activeCorridors: '22 Metropolitan Signals Locked',
    preemptionLatency: '0.0ms Cloud Latency',
    bayReadiness: 'Surgical OT-2 Scrubbed',
    accentColor: AppColors.emerald,
  ),
  GlobalHospitalNode(
    id: 'singapore_gen',
    name: 'Singapore General Hospital',
    city: 'Outram',
    country: 'Singapore',
    flag: '🇸🇬',
    lat: 1.2795,
    lng: 103.8347,
    traumaRank: 'Asia-Pacific Premier Emergency Node',
    specialty: 'Autonomous High-Density Urban Corridor Wave',
    activeCorridors: 'Zero Hard-Braking Transit',
    preemptionLatency: '8ms V2X Mesh',
    bayReadiness: 'Critical Resus Bay 1 Ready',
    accentColor: Color(0xFF10B981),
  ),
  GlobalHospitalNode(
    id: 'aiims',
    name: 'AIIMS Apex Trauma Center',
    city: 'New Delhi',
    country: 'India',
    flag: '🇮🇳',
    lat: 28.5672,
    lng: 77.2100,
    traumaRank: 'National Apex Level-1 Trauma Facility',
    specialty: 'High-Volume Multi-Arterial Transit Grid',
    activeCorridors: '4 Dedicated Corridors Active',
    preemptionLatency: '0.0ms Cloud Latency',
    bayReadiness: 'Trauma Bay 1 & 2 Primed',
    accentColor: AppColors.emerald,
  ),
  GlobalHospitalNode(
    id: 'toronto_gen',
    name: 'Toronto General Hospital',
    city: 'Toronto, ON',
    country: 'Canada',
    flag: '🇨🇦',
    lat: 43.6590,
    lng: -79.3879,
    traumaRank: 'Global Organ Transplant Pioneer',
    specialty: 'Extracorporeal Organ Perfusion Transit',
    activeCorridors: 'Airport-to-ER Green Wave Lock',
    preemptionLatency: '0.0ms Cloud Latency',
    bayReadiness: 'Perfusion Lab Sterile',
    accentColor: Color(0xFFEF4444), // Coral Red
  ),
  GlobalHospitalNode(
    id: 'karolinska',
    name: 'Karolinska University Hospital',
    city: 'Stockholm',
    country: 'Sweden',
    flag: '🇸🇪',
    lat: 59.3524,
    lng: 18.0335,
    traumaRank: 'Nobel Assembly Academic Medical Node',
    specialty: 'Nordic 5G Connected Emergency Fleet',
    activeCorridors: '14 Arterial Intersections Clear',
    preemptionLatency: '6ms C-V2X Sync',
    bayReadiness: 'Trauma Wing Ready',
    accentColor: Color(0xFF38BDF8),
  ),
  GlobalHospitalNode(
    id: 'tokyo_univ',
    name: 'The University of Tokyo Hospital',
    city: 'Bunkyo, Tokyo',
    country: 'Japan',
    flag: '🇯🇵',
    lat: 35.7126,
    lng: 139.7618,
    traumaRank: 'Advanced Robotics Emergency Center',
    specialty: 'Tokyo Metropolitan Rapid Green Wave',
    activeCorridors: 'Shuto Expressway Preemption',
    preemptionLatency: '0.0ms Cloud Latency',
    bayReadiness: 'Neurotrauma Bay Reserved',
    accentColor: Color(0xFFA855F7), // Purple
  ),
  GlobalHospitalNode(
    id: 'hopkins',
    name: 'The Johns Hopkins Hospital',
    city: 'Baltimore, MD',
    country: 'United States',
    flag: '🇺🇸',
    lat: 39.2974,
    lng: -76.5925,
    traumaRank: 'Historic Pioneer in Trauma Surgery',
    specialty: 'Level-1 Pediatric & Regional Trauma Hub',
    activeCorridors: 'Edge 5G Preemption Active',
    preemptionLatency: '12ms Edge Sync',
    bayReadiness: 'Trauma Resus 4 Ready',
    accentColor: Color(0xFF3B82F6), // Blue
  ),
  GlobalHospitalNode(
    id: 'pitie',
    name: 'Pitié-Salpêtrière Hospital',
    city: 'Paris',
    country: 'France',
    flag: '🇫🇷',
    lat: 48.8384,
    lng: 2.3639,
    traumaRank: 'AP-HP Acute Resuscitation Center',
    specialty: 'Rapid Neuro-Vascular & Emergency Transit',
    activeCorridors: 'Seine Arterial Corridor Lock',
    preemptionLatency: '10ms Edge Sync',
    bayReadiness: 'Stroke Unit Active',
    accentColor: Color(0xFFF59E0B), // Amber
  ),
];

/// Interactive 3D World Globe Widget with spherical drag & hospital focus
class InteractiveWorldGlobeWidget extends StatefulWidget {
  final VoidCallback? onOpenHospitalDashboard;
  final ScrollController? scrollController;

  const InteractiveWorldGlobeWidget({
    super.key,
    this.onOpenHospitalDashboard,
    this.scrollController,
  });

  @override
  State<InteractiveWorldGlobeWidget> createState() =>
      _InteractiveWorldGlobeWidgetState();
}

class _InteractiveWorldGlobeWidgetState extends State<InteractiveWorldGlobeWidget>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  AnimationController? _cameraAnimationController;

  // Rotation angles in radians
  double _rotY = -0.4;
  double _rotX = 0.22;
  bool _isUserDragging = false;
  double _lastScrollOffset = 0.0;

  GlobalHospitalNode _selectedHospital = kGlobalHospitals[0];

  @override
  void initState() {
    super.initState();

    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }

    // Slow ambient rotation when idle
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..addListener(() {
        if (!_isUserDragging &&
            (_cameraAnimationController == null ||
                !_cameraAnimationController!.isAnimating)) {
          setState(() {
            _rotY += 0.002;
          });
        }
      })
      ..repeat();

    // Pulse for radar beacon rings
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  void _onScroll() {
    if (!mounted || widget.scrollController == null) return;
    if (_isUserDragging ||
        (_cameraAnimationController != null &&
            _cameraAnimationController!.isAnimating)) {
      return;
    }

    final double currentOffset = widget.scrollController!.offset;
    final double delta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;

    final dt = DesignTuningController.instance;
    if (delta.abs() > 0.4) {
      setState(() {
        // Scroll down rotates forward, scroll up reverses rotation smoothly
        _rotY += delta * 0.0016 * dt.globeRotationRange;
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _spinController.dispose();
    _pulseController.dispose();
    _cameraAnimationController?.dispose();
    super.dispose();
  }

  void _selectHospital(GlobalHospitalNode hospital) {
    final dt = DesignTuningController.instance;
    setState(() {
      _selectedHospital = hospital;
    });

    // Target rotation to bring this hospital to front-center
    final double targetRotY = -(hospital.lng * math.pi / 180.0) + (math.pi / 2.0);
    final double targetRotX = (hospital.lat * math.pi / 180.0).clamp(-0.8, 0.8);

    // Normalize rotY difference
    double currentRotY = _rotY;
    double diff = (targetRotY - currentRotY) % (2 * math.pi);
    if (diff > math.pi) diff -= 2 * math.pi;
    final double endRotY = currentRotY + diff;

    final double startRotX = _rotX;

    _cameraAnimationController?.dispose();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: dt.globeTransitionTiming.toInt()),
    );

    Curve selectedCurve;
    switch (dt.globeAnimationEasing) {
      case DialKitEasing.linear:
        selectedCurve = Curves.linear;
        break;
      case DialKitEasing.fastOutSlowIn:
        selectedCurve = Curves.fastOutSlowIn;
        break;
      case DialKitEasing.easeInOut:
        selectedCurve = Curves.easeInOutCubic;
        break;
    }

    final curved = CurvedAnimation(
      parent: _cameraAnimationController!,
      curve: selectedCurve,
    );

    curved.addListener(() {
      setState(() {
        _rotY = currentRotY + (endRotY - currentRotY) * curved.value;
        _rotX = startRotX + (targetRotX - startRotX) * curved.value;
      });
    });

    _cameraAnimationController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Column(
      children: [
        // Horizontal Scrollable Hospital Node Selection Chips
        Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 28),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: kGlobalHospitals.length,
            itemBuilder: (context, index) {
              final h = kGlobalHospitals[index];
              final isSelected = h.id == _selectedHospital.id;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () => _selectHospital(h),
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.navy
                          : AppColors.cream,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.navy
                            : AppColors.sky,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.navy.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(h.flag, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(
                          h.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.cream : AppColors.navy,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.sky,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Main 3D Canvas + Hospital Dossier Flex Layout
        Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: The Interactive 3D World Globe Canvas
            Expanded(
              flex: isMobile ? 0 : 7,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: isMobile ? 380 : 520,
                  minHeight: isMobile ? 340 : 480,
                ),
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      _isUserDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _rotY += details.delta.dx * 0.007;
                      _rotX = (_rotX - details.delta.dy * 0.007).clamp(-1.1, 1.1);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _isUserDragging = false;
                    });
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseController, DesignTuningController.instance]),
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size.infinite,
                        painter: _GlobePainter(
                          rotY: _rotY,
                          rotX: _rotX,
                          pulseProgress: _pulseController.value,
                          selectedHospital: _selectedHospital,
                          hospitals: kGlobalHospitals,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            if (!isMobile) const SizedBox(width: 32),
            if (isMobile) const SizedBox(height: 28),

            // Right: Selected Hospital Clinical Dossier Card
            Expanded(
              flex: isMobile ? 0 : 5,
              child: _buildHospitalDossierCard(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHospitalDossierCard(BuildContext context) {
    final h = _selectedHospital;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.sky,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.10),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top City & Flag Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.sky.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.sky),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(h.flag, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          '${h.city.toUpperCase()}, ${h.country.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GRID ONLINE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Hospital Name
              Text(
                h.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                h.traumaRank,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyLight,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                h.specialty,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.navyMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Divider(color: AppColors.sky.withValues(alpha: 0.45), height: 1),
              const SizedBox(height: 20),

              // 4 Live Clinical Telemetry Boxes
              Row(
                children: [
                  Expanded(
                    child: _buildDossierKpiBox(
                      label: 'PREEMPTION LATENCY',
                      value: h.preemptionLatency,
                      icon: Icons.speed_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDossierKpiBox(
                      label: 'TRAUMA BAY PREP',
                      value: h.bayReadiness,
                      icon: Icons.medical_services_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDossierKpiBox(
                      label: 'ACTIVE CORRIDORS',
                      value: h.activeCorridors,
                      icon: Icons.alt_route_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDossierKpiBox(
                      label: 'SIGNAL COMPLIANCE',
                      value: '100% Green Wave',
                      icon: Icons.traffic_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // Action button to open Hospital Portal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onOpenHospitalDashboard,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.navy.withValues(alpha: 0.25),
                  ),
                  icon: const Icon(Icons.monitor_heart_rounded, size: 18, color: AppColors.sky),
                  label: Text(
                    'Open Level-1 Hospital Console',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDossierKpiBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.skyTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.navy),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyMuted,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Custom 3D Spherical Painter projecting rotating earth & hospital beacons
class _GlobePainter extends CustomPainter {
  final double rotY;
  final double rotX;
  final double pulseProgress;
  final GlobalHospitalNode selectedHospital;
  final List<GlobalHospitalNode> hospitals;

  _GlobePainter({
    required this.rotY,
    required this.rotX,
    required this.pulseProgress,
    required this.selectedHospital,
    required this.hospitals,
  });

  // Major continental seed points (lat, lng) to form realistic landmass point clouds
  static final List<math.Point<double>> _continentSeeds = [
    // North America
    const math.Point(40, -100), const math.Point(45, -75), const math.Point(35, -118),
    const math.Point(50, -120), const math.Point(30, -90), const math.Point(55, -105),
    const math.Point(62, -150), const math.Point(20, -100), const math.Point(45, -93),
    // South America
    const math.Point(-10, -55), const math.Point(-23, -46), const math.Point(-34, -58),
    const math.Point(5, -73), const math.Point(-12, -77), const math.Point(-2, -60),
    // Europe
    const math.Point(52, 13), const math.Point(48, 2), const math.Point(51, 0),
    const math.Point(59, 18), const math.Point(40, -3), const math.Point(41, 12),
    const math.Point(60, 10), const math.Point(55, 37), const math.Point(45, 15),
    // Africa
    const math.Point(0, 20), const math.Point(9, 8), const math.Point(-26, 28),
    const math.Point(30, 31), const math.Point(12, 38), const math.Point(-1, 37),
    // Asia
    const math.Point(28, 77), const math.Point(35, 139), const math.Point(1, 103),
    const math.Point(39, 116), const math.Point(31, 121), const math.Point(25, 85),
    const math.Point(13, 80), const math.Point(19, 72), const math.Point(35, 51),
    const math.Point(55, 83), const math.Point(60, 105), const math.Point(22, 114),
    // Australia
    const math.Point(-33, 151), const math.Point(-37, 144), const math.Point(-31, 115),
    const math.Point(-20, 133),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final dt = DesignTuningController.instance;
    final cx = size.width / 2.0;
    final cy = (size.height / 2.0) + dt.globeVerticalPosition;
    final radius = math.min(size.width, size.height) * 0.40 * dt.globeScale;

    // 1. Draw outer atmospheric glow halo (Radiant Sky Blue & Pale Cream)
    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        radius * 1.35,
        [
          AppColors.sky.withValues(alpha: 0.45),
          AppColors.cream.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        [0.70, 0.90, 1.0],
      );
    canvas.drawCircle(Offset(cx, cy), radius * 1.35, glowPaint);

    // 2. Draw 3D Shaded Sphere Background (Radiant Light Earth Sphere)
    final spherePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx - radius * 0.35, cy - radius * 0.35),
        radius * 1.4,
        [
          Colors.white,
          const Color(0xFFD8EFFC),
          AppColors.sky,
          const Color(0xFF5BAEE2),
        ],
        [0.0, 0.40, 0.80, 1.0],
      );
    canvas.drawCircle(Offset(cx, cy), radius, spherePaint);

    // Sphere subtle border rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColors.navy.withValues(alpha: 0.30);
    canvas.drawCircle(Offset(cx, cy), radius, rimPaint);

    // 3. Draw 3D Latitude Parallels
    final gridFrontPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.navy.withValues(alpha: 0.22);

    final gridBackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.navy.withValues(alpha: 0.08);

    const latSteps = [-60.0, -30.0, 0.0, 30.0, 60.0];
    for (final lat in latSteps) {
      _drawLatitudeRing(canvas, cx, cy, radius, lat, gridFrontPaint, gridBackPaint);
    }

    // 4. Draw 3D Longitude Meridians
    for (double lng = 0; lng < 360; lng += 30) {
      _drawLongitudeArc(canvas, cx, cy, radius, lng, gridFrontPaint, gridBackPaint);
    }

    // 5. Draw Rotating Continent Point-Cloud in Crisp Navy Blue
    final landFrontPaint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    for (final seed in _continentSeeds) {
      for (double dLat = -3.5; dLat <= 3.5; dLat += 3.5) {
        for (double dLng = -4.5; dLng <= 4.5; dLng += 4.5) {
          final p3d = _projectSpherical(seed.x + dLat, seed.y + dLng, radius);
          if (p3d.z > -radius * 0.1) {
            final double depthAlpha = ((p3d.z + radius * 0.1) / (radius * 1.1)).clamp(0.1, 1.0);
            landFrontPaint.color = AppColors.navy.withValues(alpha: depthAlpha * 0.80);
            canvas.drawCircle(
              Offset(cx + p3d.x, cy + p3d.y),
              (1.6 * depthAlpha).clamp(1.0, 2.4),
              landFrontPaint,
            );
          }
        }
      }
    }

    // 6. Draw Orbital Green Corridor Transit Arcs between major nodes
    _drawCorridorFlightArc(canvas, cx, cy, radius, hospitals[0], hospitals[2]); // Mayo to Charite
    _drawCorridorFlightArc(canvas, cx, cy, radius, hospitals[2], hospitals[4]); // Charite to AIIMS
    _drawCorridorFlightArc(canvas, cx, cy, radius, hospitals[4], hospitals[3]); // AIIMS to Singapore
    _drawCorridorFlightArc(canvas, cx, cy, radius, hospitals[3], hospitals[7]); // Singapore to Tokyo
    _drawCorridorFlightArc(canvas, cx, cy, radius, hospitals[7], hospitals[5]); // Tokyo to Toronto

    // 7. Draw Hospital Beacon Pins
    for (final h in hospitals) {
      final p3d = _projectSpherical(h.lat, h.lng, radius);

      if (p3d.z > 0) {
        final pos = Offset(cx + p3d.x, cy + p3d.y);
        final isSelected = h.id == selectedHospital.id;

        // Pulsing radar ripple
        final double rippleRadius = 8.0 + (pulseProgress * (isSelected ? 22.0 : 12.0));
        final ripplePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.8 : 1.2
          ..color = (isSelected ? AppColors.navy : AppColors.navyLight)
              .withValues(alpha: (1.0 - pulseProgress) * 0.8);
        canvas.drawCircle(pos, rippleRadius, ripplePaint);

        // Core Pin Dot
        final dotPaint = Paint()
          ..color = isSelected ? AppColors.navy : AppColors.navyLight
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, isSelected ? 6.0 : 4.0, dotPaint);

        final glowDotPaint = Paint()
          ..color = AppColors.sky
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, isSelected ? 8.5 : 5.0, glowDotPaint);

        // If selected: draw floating label on globe
        if (isSelected) {
          _drawHospitalGlobeLabel(canvas, pos, h);
        }
      }
    }
  }

  void _drawHospitalGlobeLabel(Canvas canvas, Offset pos, GlobalHospitalNode h) {
    final labelText = '${h.flag} ${h.name}';
    final textSpan = TextSpan(
      text: labelText,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = Offset(pos.dx + 12, pos.dy - 14);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelOffset.dx - 6, labelOffset.dy - 4, textPainter.width + 14, textPainter.height + 8),
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = AppColors.cream;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.navy;

    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);
    textPainter.paint(canvas, labelOffset);
  }

  void _drawCorridorFlightArc(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    GlobalHospitalNode h1,
    GlobalHospitalNode h2,
  ) {
    final dt = DesignTuningController.instance;
    if (dt.globeRouteVisibility <= 0.02) return;

    final p1 = _projectSpherical(h1.lat, h1.lng, radius);
    final p2 = _projectSpherical(h2.lat, h2.lng, radius);

    if (p1.z > -radius * 0.3 || p2.z > -radius * 0.3) {
      final midLat = (h1.lat + h2.lat) / 2.0;
      final midLng = (h1.lng + h2.lng) / 2.0;
      final pMid = _projectSpherical(midLat, midLng, radius * 1.18);

      final path = Path()
        ..moveTo(cx + p1.x, cy + p1.y)
        ..quadraticBezierTo(cx + pMid.x, cy + pMid.y, cx + p2.x, cy + p2.y);

      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = ui.Gradient.linear(
          Offset(cx + p1.x, cy + p1.y),
          Offset(cx + p2.x, cy + p2.y),
          [
            dt.currentNavy.withValues(alpha: 0.85 * dt.globeRouteVisibility),
            dt.currentSecondary.withValues(alpha: 0.90 * dt.globeRouteVisibility),
          ],
        );

      canvas.drawPath(path, arcPaint);
    }
  }

  void _drawLatitudeRing(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    double lat,
    Paint frontPaint,
    Paint backPaint,
  ) {
    const int segments = 60;
    for (int i = 0; i < segments; i++) {
      final double lng1 = (i * 360.0 / segments);
      final double lng2 = ((i + 1) * 360.0 / segments);

      final p1 = _projectSpherical(lat, lng1, radius);
      final p2 = _projectSpherical(lat, lng2, radius);

      final paint = (p1.z > 0 && p2.z > 0) ? frontPaint : backPaint;
      canvas.drawLine(
        Offset(cx + p1.x, cy + p1.y),
        Offset(cx + p2.x, cy + p2.y),
        paint,
      );
    }
  }

  void _drawLongitudeArc(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    double lng,
    Paint frontPaint,
    Paint backPaint,
  ) {
    const int segments = 36;
    for (int i = 0; i < segments; i++) {
      final double lat1 = -90.0 + (i * 180.0 / segments);
      final double lat2 = -90.0 + ((i + 1) * 180.0 / segments);

      final p1 = _projectSpherical(lat1, lng, radius);
      final p2 = _projectSpherical(lat2, lng, radius);

      final paint = (p1.z > 0 && p2.z > 0) ? frontPaint : backPaint;
      canvas.drawLine(
        Offset(cx + p1.x, cy + p1.y),
        Offset(cx + p2.x, cy + p2.y),
        paint,
      );
    }
  }

  /// 3D Spherical Coordinate Projection with Rotations
  _Point3D _projectSpherical(double latDeg, double lngDeg, double radius) {
    final latRad = latDeg * math.pi / 180.0;
    final lngRad = lngDeg * math.pi / 180.0;

    // Unit Cartesian on sphere
    final double x0 = radius * math.cos(latRad) * math.sin(lngRad);
    final double y0 = -radius * math.sin(latRad);
    final double z0 = radius * math.cos(latRad) * math.cos(lngRad);

    // Rotate around Y axis (rotY)
    final double x1 = x0 * math.cos(rotY) + z0 * math.sin(rotY);
    final double z1 = -x0 * math.sin(rotY) + z0 * math.cos(rotY);

    // Rotate around X axis (rotX)
    final double y2 = y0 * math.cos(rotX) - z1 * math.sin(rotX);
    final double z2 = y0 * math.sin(rotX) + z1 * math.cos(rotX);

    return _Point3D(x1, y2, z2);
  }

  @override
  bool shouldRepaint(_GlobePainter oldDelegate) {
    return oldDelegate.rotY != rotY ||
        oldDelegate.rotX != rotX ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.selectedHospital.id != selectedHospital.id;
  }
}

class _Point3D {
  final double x;
  final double y;
  final double z;

  const _Point3D(this.x, this.y, this.z);
}
