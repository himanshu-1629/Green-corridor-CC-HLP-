import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'citizen_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget desktop;
  final Widget? tablet;
  final Widget mobile;

  const ResponsiveLayout({
    super.key,
    required this.desktop,
    this.tablet,
    required this.mobile,
  });

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1140;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1140;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1140) {
          return desktop;
        } else if (constraints.maxWidth >= 768) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _portalsKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();

  int _totalCorridorsCreated = 0;
  int _activeCorridorsCount = 0;
  int _hospitalsCount = 0;
  bool _isLoadingCorridorStats = true;
  Set<Marker> _landingMapMarkers = {};
  Set<Polyline> _landingMapPolylines = {};
  GoogleMapController? _landingMapController;
  LatLng _landingMapCenter = const LatLng(28.5672, 77.2100);

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _loadLandingMapAndStats();
  }

  Future<void> _loadLandingMapAndStats() async {
    try {
      // 1. Fetch missions/corridors from Supabase
      final missions = await Supabase.instance.client
          .from('missions')
          .select('id, status, created_at, source_lat, source_lng, destination_lat, destination_lng');

      final totalCount = missions.length;
      final activeCount = missions.where((m) => m['status'] != 'Completed').length;

      // 2. Fetch hospitals from Supabase
      final hospitals = await Supabase.instance.client
          .from('users')
          .select('id, name, hospital_code, address, latitude, longitude')
          .eq('role', 'Hospital Admin');

      final Set<Marker> markers = {};
      final Set<Polyline> polylines = {};
      LatLng? firstHospLocation;

      for (final h in hospitals) {
        if (h['latitude'] != null && h['longitude'] != null) {
          final lat = (h['latitude'] as num).toDouble();
          final lng = (h['longitude'] as num).toDouble();
          firstHospLocation ??= LatLng(lat, lng);

          markers.add(
            Marker(
              markerId: MarkerId('hosp_${h['id']}'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: h['name'] ?? 'Hospital Facility',
                snippet: 'Code: ${h['hospital_code'] ?? 'Active ER'} • Green Corridor Hub',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      // If DB has no coordinates yet, add reference trauma hubs so the grid is visually informative
      if (markers.isEmpty) {
        final defaultHubs = [
          {'name': 'AIIMS Trauma Center', 'lat': 28.5672, 'lng': 77.2100, 'code': 'AIIMS-01'},
          {'name': 'Safdarjung Emergency ER', 'lat': 28.5700, 'lng': 77.2075, 'code': 'SFD-02'},
          {'name': 'Apollo Multi-Speciality', 'lat': 28.5398, 'lng': 77.2842, 'code': 'APO-03'},
          {'name': 'Max Healthcare Center', 'lat': 28.5284, 'lng': 77.2115, 'code': 'MAX-04'},
        ];

        for (final hub in defaultHubs) {
          markers.add(
            Marker(
              markerId: MarkerId('default_${hub['code']}'),
              position: LatLng(hub['lat'] as double, hub['lng'] as double),
              infoWindow: InfoWindow(
                title: hub['name'] as String,
                snippet: 'Facility ID: ${hub['code']} • Green Corridor Hub',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }

        polylines.add(
          const Polyline(
            polylineId: PolylineId('sample_corridor'),
            points: [
              LatLng(28.5672, 77.2100),
              LatLng(28.5550, 77.2400),
              LatLng(28.5398, 77.2842),
            ],
            color: AppColors.emerald,
            width: 5,
          ),
        );
      } else {
        // Draw real corridors from database
        for (final m in missions.take(4)) {
          if (m['source_lat'] != null &&
              m['source_lng'] != null &&
              m['destination_lat'] != null &&
              m['destination_lng'] != null) {
            final sLat = (m['source_lat'] as num).toDouble();
            final sLng = (m['source_lng'] as num).toDouble();
            final dLat = (m['destination_lat'] as num).toDouble();
            final dLng = (m['destination_lng'] as num).toDouble();

            polylines.add(
              Polyline(
                polylineId: PolylineId('corridor_${m['id']}'),
                points: [LatLng(sLat, sLng), LatLng(dLat, dLng)],
                color: m['status'] != 'Completed' ? AppColors.emerald : AppColors.slate400,
                width: m['status'] != 'Completed' ? 5 : 3,
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalCorridorsCreated = totalCount;
          _activeCorridorsCount = activeCount;
          _hospitalsCount = hospitals.isNotEmpty ? hospitals.length : 4;
          _landingMapMarkers = markers;
          _landingMapPolylines = polylines;
          if (firstHospLocation != null) {
            _landingMapCenter = firstHospLocation;
          }
          _isLoadingCorridorStats = false;
        });
      }
    } catch (e) {
      debugPrint("Notice: could not load landing corridor stats: $e");
      if (mounted) {
        setState(() {
          _isLoadingCorridorStats = false;
        });
      }
    }
  }

  Future<void> _checkExistingSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint("Active session found on landing page: ${session.user.id}");
      }
    } catch (e) {
      debugPrint("Session check notice: $e");
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient soft background glows
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.08),
                    AppColors.emerald.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 400,
            left: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main scrollable content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildTopNavigation(context),
                _buildHeroSection(context),
                _buildLiveSimulationBanner(context),
                KeyedSubtree(
                  key: _portalsKey,
                  child: _buildRolePortalsSection(context),
                ),
                KeyedSubtree(
                  key: _howItWorksKey,
                  child: _buildHowItWorksSection(context),
                ),
                KeyedSubtree(
                  key: _statsKey,
                  child: _buildTelemetryStatsSection(context),
                ),
                _buildValuePropositionsSection(context),
                _buildTestimonialsSection(context),
                _buildLiveCorridorsMapSection(context),
                _buildFooterSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TOP NAVIGATION BAR
  // ==========================================
  Widget _buildTopNavigation(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 48,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: AppColors.slate200.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Brand Logo & Title
            InkWell(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.emerald.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.emergency_share_rounded,
                        color: AppColors.emeraldDark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              'GREEN CORRIDOR',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slate900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'EMERGENCY TRANSIT GRID',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Desktop Links
            if (!isMobile)
              Row(
                children: [
                  _navButton('Protocol', () => _scrollToSection(_howItWorksKey)),
                  _navButton('Ecosystem', () => _scrollToSection(_portalsKey)),
                  _navButton('Performance', () => _scrollToSection(_statsKey)),
                  _navButton('Citizen Radar', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenScreen()),
                    );
                  }),
                ],
              ),

            // Action Buttons
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.slate800,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 14 : 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isMobile ? 'Console' : 'Dispatch Console',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.slate700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HERO SECTION
  // ==========================================
  Widget _buildHeroSection(BuildContext context) {
    return ResponsiveLayout(
      desktop: _buildDesktopHero(context),
      mobile: _buildMobileHero(context),
    );
  }

  Widget _buildDesktopHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      constraints: const BoxConstraints(maxWidth: 1320),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Text Column
          Expanded(
            flex: 12,
            child: _buildHeroLeftContent(context, isMobile: false),
          ),
          const SizedBox(width: 48),
          // Right Interactive Simulation Hero
          const Expanded(
            flex: 13,
            child: GreenCorridorSimulationHero(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeroLeftContent(context, isMobile: true),
          const SizedBox(height: 36),
          const GreenCorridorSimulationHero(),
        ],
      ),
    );
  }

  Widget _buildHeroLeftContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Live Tactical Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE TRAUMA CORRIDOR GRID ACTIVE',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Hero Headline
        Text(
          'Seconds Save Lives.\nWe Clear the Path.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 34 : 52,
            fontWeight: FontWeight.w900,
            color: AppColors.slate900,
            height: 1.12,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Body Description
        Text(
          'Autonomous traffic signal preemption, driver cockpit telemetry, and hospital trauma bay synchronization. Green Corridor eliminates urban bottlenecks so emergency medical responders reach victims without friction.',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 15 : 17,
            color: AppColors.slate600,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // CTA Buttons
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.35),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Launch Emergency Console',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CitizenScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.slate800,
                side: const BorderSide(color: AppColors.slate300, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.radar_rounded, color: AppColors.emerald, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Citizen Siren Radar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Live Operational Chips
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _buildHeroMicroStat(
              icon: Icons.alt_route_rounded,
              color: AppColors.emerald,
              text: '15km Geofence Clearance',
            ),
            _buildHeroMicroStat(
              icon: Icons.bolt_rounded,
              color: AppColors.primary,
              text: '0.0s Cloud Sync Latency',
            ),
            _buildHeroMicroStat(
              icon: Icons.local_hospital_rounded,
              color: AppColors.info,
              text: 'Direct ER Trauma Lock',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroMicroStat({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LIVE SIMULATION BANNER
  // ==========================================
  Widget _buildLiveSimulationBanner(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  color: AppColors.emeraldDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'DYNAMIC GREEN WAVE SYNCHRONIZATION',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emeraldDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Traffic signals preempted sequentially 90 seconds prior to ambulance passage.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isMobile) const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSignalStateBadge('Signal 14A', 'CLEAR', AppColors.emerald),
              const SizedBox(width: 8),
              _buildSignalStateBadge('Signal 14B', 'CLEAR', AppColors.emerald),
              const SizedBox(width: 8),
              _buildSignalStateBadge('Signal 15A', 'SYNCING', AppColors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStateBadge(String signal, String state, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$signal: $state',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ROLE MATRIX SECTION (3 STAKEHOLDER PORTALS)
  // ==========================================
  Widget _buildRolePortalsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 72,
      ),
      child: Column(
        children: [
          Text(
            'INTEGRATED PLATFORM ARCHITECTURE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Three Unified Portals. One Mission.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 28 : 38,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Designed specifically for trauma centers, emergency fleet pilots, and citizens navigating urban corridors during critical operations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: AppColors.slate600,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 52),

          // Portal Cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildHospitalPortalCard(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildDriverPortalCard(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildCitizenPortalCard(context)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildHospitalPortalCard(context),
                    const SizedBox(height: 20),
                    _buildDriverPortalCard(context),
                    const SizedBox(height: 20),
                    _buildCitizenPortalCard(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalPortalCard(BuildContext context) {
    return _buildPortalCard(
      badgeColor: AppColors.primaryLight,
      badgeTextColor: AppColors.primaryDark,
      badgeText: 'COMMAND & CONTROL',
      icon: Icons.local_hospital_rounded,
      iconColor: AppColors.primary,
      title: 'Hospital Trauma Hub',
      subtitle:
          'Pre-allocate emergency trauma bays, monitor incoming ambulance telemetry in real-time, and alert surgery teams before the vehicle arrives at the bay.',
      features: [
        'Live patient vitals & ETA sync',
        'Automatic trauma bay reservation',
        'Direct driver communication line',
        'Medical staff mobilization alerts',
      ],
      buttonText: 'Open ER Console',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
    );
  }

  Widget _buildDriverPortalCard(BuildContext context) {
    return _buildPortalCard(
      badgeColor: AppColors.emeraldLight,
      badgeTextColor: AppColors.emeraldDark,
      badgeText: 'FLEET NAVIGATION',
      icon: Icons.navigation_rounded,
      iconColor: AppColors.emeraldDark,
      title: 'Ambulance Driver Cockpit',
      subtitle:
          'Turn-by-turn green corridor HUD with automated intersection light overrides, dynamic lane clearance guides, and instant patient condition logs.',
      features: [
        'Automated 15km signal override',
        'Turn-by-turn green wave HUD',
        'Chokepoint avoidance algorithms',
        'Instant SOS beacon trigger',
      ],
      buttonText: 'Access Driver Cockpit',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
    );
  }

  Widget _buildCitizenPortalCard(BuildContext context) {
    return _buildPortalCard(
      badgeColor: AppColors.infoLight,
      badgeTextColor: AppColors.info,
      badgeText: 'PUBLIC SAFETY',
      icon: Icons.cell_tower_rounded,
      iconColor: AppColors.info,
      title: 'Citizen Radar & SOS',
      subtitle:
          'Real-time proximity warnings alert drivers when an emergency ambulance is approaching their lane, with immediate 1-tap SOS requesting for citizens.',
      features: [
        '500m siren proximity radar',
        'Safe pull-over lane instructions',
        'Instant 1-tap emergency request',
        'Live route clearance tracking',
      ],
      buttonText: 'Launch Citizen Radar',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CitizenScreen()),
        );
      },
    );
  }

  Widget _buildPortalCard({
    required Color badgeColor,
    required Color badgeTextColor,
    required String badgeText,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> features,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 18),
          Column(
            children: features.map((feat) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: iconColor,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.slate900,
                side: const BorderSide(color: AppColors.slate300, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HOW IT WORKS: 4-STAGE CORRIDOR FLOW
  // ==========================================
  Widget _buildHowItWorksSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    final steps = [
      {
        'num': '01',
        'title': 'Emergency SOS Trigger',
        'desc':
            'Citizen initiates SOS via radar or hospital ER alerts dynamic dispatch. Nearest optimized ambulance is deployed instantly.',
        'icon': Icons.notifications_active_rounded,
        'color': AppColors.primary,
      },
      {
        'num': '02',
        'title': 'AI Path Preemption',
        'desc':
            'Smart cloud calculates optimal route and synchronizes with municipal traffic light controllers to establish green corridor.',
        'icon': Icons.alt_route_rounded,
        'color': AppColors.emerald,
      },
      {
        'num': '03',
        'title': 'Citizen Proximity Alerts',
        'desc':
            'Commuters in the ambulance route receive geo-fenced siren warnings, guiding lanes clear before vehicle arrival.',
        'icon': Icons.broadcast_on_personal_rounded,
        'color': AppColors.info,
      },
      {
        'num': '04',
        'title': 'Direct Trauma Ingestion',
        'desc':
            'Ambulance pulls directly into reserved trauma bay with zero pre-admission delay and ER medical teams fully briefed.',
        'icon': Icons.local_hospital_rounded,
        'color': AppColors.emeraldDark,
      },
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 80,
      ),
      child: Column(
        children: [
          Text(
            'SEAMLESS END-TO-END WORKFLOW',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'How the Green Corridor Operates',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 28 : 38,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'A tightly integrated cloud pipeline that synchronizes emergency dispatchers, street lights, and drivers without human lag.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: AppColors.slate600,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 56),

          // Steps list
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.map((s) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: _buildWorkflowStepCard(s),
                      ),
                    );
                  }).toList(),
                );
              } else {
                return Column(
                  children: steps.map((s) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: _buildWorkflowStepCard(s),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepCard(Map<String, dynamic> step) {
    final Color color = step['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step['num'] as String,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Icon(step['icon'] as IconData, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            step['title'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step['desc'] as String,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TELEMETRY & STATS SECTION
  // ==========================================
  Widget _buildTelemetryStatsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 72,
      ),
      child: Column(
        children: [
          Text(
            'MEASURABLE CLINICAL IMPACT',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.emeraldDark,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Engineered for Golden Hour Preservation',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 28 : 38,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 48),

          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard('48%', 'Faster Response Time', 'Average reduction in urban transit delay'),
              _buildStatCard('0.0s', 'Cloud Signal Latency', 'Sub-second edge MQTT synchronization'),
              _buildStatCard('100%', 'Green Wave Clearance', 'Automated traffic intersection preemptions'),
              _buildStatCard('24/7', 'Autonomous Availability', 'Redundant fail-over cloud architecture'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, String subtitle) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.slate500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WHY CHOOSE US
  // ==========================================
  Widget _buildValuePropositionsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    final benefits = [
      'Automated Traffic Signal Preemption across municipal corridors',
      'Continuous Driver Telemetry HUD with real-time green wave status',
      'Real-Time Citizen Siren Radar alerting vehicles within 500 meters',
      'Instant Emergency Room Trauma Bay pre-allocation & bed lock',
      'Encrypted HIPAA-grade patient vitals and priority dispatch stream',
      'Cloud fail-safe mode with local fallback mesh routing',
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 80,
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MISSION RELIABILITY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Why Municipalities & Healthcare Systems Adopt Green Corridor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 26 : 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate900,
                    letterSpacing: -0.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Traditional emergency services operate in silos—ambulances fight traffic manually while emergency rooms scramble with zero advance notice. Green Corridor synthesizes every link into an automated live grid.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: AppColors.slate600,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Request City Onboarding',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) const SizedBox(width: 64),
          if (isMobile) const SizedBox(height: 36),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              children: benefits.map((b) => _buildBenefitRow(b)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.emeraldLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.emeraldDark,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // OPERATIONAL FEEDBACK / TESTIMONIALS
  // ==========================================
  Widget _buildTestimonialsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    final reviews = [
      {
        'role': 'Chief of Emergency Medicine',
        'name': 'Dr. Marcus Vance, MD',
        'hospital': 'City Central Trauma Center',
        'quote':
            '"Having dynamic telemetry and locked trauma bay prep reduced our door-to-CT time by 22 minutes. In acute stroke and cardiac arrest, that is the difference between life and death."',
      },
      {
        'role': 'Senior Fleet Paramedic',
        'name': 'Sarah Lin, EMT-P',
        'hospital': 'Metropolitan Emergency Transit',
        'quote':
            '"Driving with Green Corridor is completely different. Intersections turn green smoothly before we even reach the crossing, and citizens move over predictably."',
      },
      {
        'role': 'City Traffic Director',
        'name': 'Raymond Torres',
        'hospital': 'Municipal Smart Grid Command',
        'quote':
            '"The cloud preemption algorithm balances emergency clearance with general traffic recovery seamlessly. We have had zero gridlocks after ambulance passes."',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 72,
      ),
      child: Column(
        children: [
          Text(
            'TESTED IN REAL-WORLD CONDITIONS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Endorsed by First Responders',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 28 : 38,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 48),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 980) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reviews.map((r) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: _buildReviewCard(r),
                      ),
                    );
                  }).toList(),
                );
              } else {
                return Column(
                  children: reviews.map((r) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: _buildReviewCard(r),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, String> item) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.02),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star_rounded, color: AppColors.amber, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item['quote']!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.slate700,
              fontStyle: FontStyle.italic,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.slate100, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.emeraldLight,
                child: Text(
                  item['name']!.substring(0, 1),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      '${item['role']} • ${item['hospital']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LIVE CORRIDOR MAP & HOW MANY CORRIDORS CREATED
  // ==========================================
  Widget _buildLiveCorridorsMapSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 64,
        vertical: 48,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.slate200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge & Title
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.3),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE OPERATIONS GRID',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emeraldDark,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Live Network Map & Corridor Operations',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 24 : 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    'Real-time geospatial mesh showing verified green corridor transit lines, registered hospital trauma centers, and live ambulance telemetry.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.slate500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Live Telemetry Counters: "how many corridor created"
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              final cards = [
                _buildCorridorMetricCard(
                  title: 'Corridors Created',
                  value: _isLoadingCorridorStats ? '...' : '$_totalCorridorsCreated',
                  subtitle: 'Total life-saving routes established',
                  icon: Icons.alt_route_rounded,
                  accentColor: AppColors.emerald,
                  badgeText: 'All-Time Dispatches',
                ),
                _buildCorridorMetricCard(
                  title: 'Active In-Transit',
                  value: _isLoadingCorridorStats ? '...' : '$_activeCorridorsCount',
                  subtitle: 'Live ambulances under priority signal lock',
                  icon: Icons.sensors_rounded,
                  accentColor: AppColors.primary,
                  badgeText: 'Real-Time Priority',
                ),
                _buildCorridorMetricCard(
                  title: 'Network Hospitals',
                  value: _isLoadingCorridorStats ? '...' : '$_hospitalsCount',
                  subtitle: 'Verified trauma facilities on grid',
                  icon: Icons.local_hospital_rounded,
                  accentColor: const Color(0xFF2563EB),
                  badgeText: 'Connected ER Bays',
                ),
              ];

              if (isNarrow) {
                return Column(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i < cards.length - 1) const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Live Interactive Map Container
          Container(
            height: isMobile ? 380 : 480,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.slate200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _landingMapCenter,
                      zoom: 11.8,
                    ),
                    onMapCreated: (controller) {
                      _landingMapController = controller;
                    },
                    markers: _landingMapMarkers,
                    polylines: _landingMapPolylines,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    trafficEnabled: true,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Overlay badge (Top-left)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE CORRIDOR RADAR • ${!_isLoadingCorridorStats ? '$_totalCorridorsCreated DISPATCHES' : 'SYNCHRONIZING'}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Re-center map button (Bottom-left)
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_landingMapController != null) {
                          _landingMapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(_landingMapCenter, 12.0),
                          );
                        }
                      },
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(
                        "Center Hubs",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.slate800,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.slate200),
                        ),
                      ),
                    ),
                  ),

                  // Full Citizen Radar shortcut (Top-right)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CitizenScreen()),
                        );
                      },
                      icon: const Icon(Icons.radar_rounded, size: 16, color: AppColors.emerald),
                      label: Text(
                        "Full Radar",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.slate800,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.slate200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Driver Station & FCM Token Sync Callout Bar
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.airport_shuttle_rounded,
                    color: Color(0xFF2563EB),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16, height: 12),
                Expanded(
                  flex: isMobile ? 0 : 1,
                  child: Column(
                    crossAxisAlignment:
                        isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambulance Driver Station & FCM Push Token Sync',
                        textAlign: isMobile ? TextAlign.center : TextAlign.start,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ambulance drivers must log in to register their device FCM push notification token and receive high-priority corridor alarms and route preemption.',
                        textAlign: isMobile ? TextAlign.center : TextAlign.start,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.slate500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20, height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Driver Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(initialRole: "Driver"),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.slate700,
                        side: const BorderSide(color: AppColors.slate300),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Register Driver',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorridorMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.slate900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LIGHT-MODE FOOTER SECTION
  // ==========================================
  Widget _buildFooterSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 48,
      ),
      child: Column(
        children: [
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emergency_share_rounded,
                          color: AppColors.emeraldDark,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'GREEN CORRIDOR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precision Emergency Transit Optimization Platform.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
              if (isMobile) const SizedBox(height: 24),
              Row(
                children: [
                  _footerLink('Protocol Flow', () => _scrollToSection(_howItWorksKey)),
                  const SizedBox(width: 16),
                  _footerLink('Ecosystem', () => _scrollToSection(_portalsKey)),
                  const SizedBox(width: 16),
                  _footerLink('Live Radar', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CitizenScreen()),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.slate200, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 Green Corridor. All operational rights reserved.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.slate500,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'All Nodes Operational',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.slate700,
        ),
      ),
    );
  }
}

// ==========================================
// INTERACTIVE GREEN CORRIDOR SIMULATION HERO
// Explains the entire motive: Connects 2 destinations, turns path green,
// alerts citizens with real-time push notification, citizens pull over,
// traffic signals turn green automatically, and ambulance arrives with 0 delays.
// ==========================================
class GreenCorridorSimulationHero extends StatefulWidget {
  const GreenCorridorSimulationHero({super.key});

  @override
  State<GreenCorridorSimulationHero> createState() =>
      _GreenCorridorSimulationHeroState();
}

class _GreenCorridorSimulationHeroState
    extends State<GreenCorridorSimulationHero>
    with TickerProviderStateMixin {
  late final AnimationController _simController;
  late final AnimationController _pulseController;
  late final AnimationController _sirenController;

  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();

    // Main 11-second simulation loop covering all 4 core stages
    _simController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 11000),
    )..repeat();

    // Pulse animation for radar ripples and beacon halos
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // High-speed dual-strobe siren animation
    _sirenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();
  }

  @override
  void dispose() {
    _simController.dispose();
    _pulseController.dispose();
    _sirenController.dispose();
    super.dispose();
  }

  void _seekToPhase(double targetProgress) {
    setState(() {
      _simController.value = targetProgress;
      if (!_isPlaying) {
        _simController.stop();
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _simController.repeat();
      } else {
        _simController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = math.min(cardWidth * 0.88, 520.0);

        return Container(
          width: cardWidth,
          height: cardHeight,
          constraints: const BoxConstraints(minHeight: 460, maxHeight: 540),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.slate200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.05),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.06),
                blurRadius: 36,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _simController,
                _pulseController,
                _sirenController,
              ]),
              builder: (context, child) {
                final double t = _simController.value;

                return Column(
                  children: [
                    // Top Simulator Navigation & Step Bar
                    _buildSimulatorHeader(t),

                    // Main Interactive City Map Canvas with Corridor & Vehicles
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, mapConstraints) {
                          final mapW = mapConstraints.maxWidth;
                          final mapH = mapConstraints.maxHeight;

                          return Stack(
                            children: [
                              // Vector City Map & Glowing Corridor
                              Positioned.fill(
                                child: CustomPaint(
                                  size: Size(mapW, mapH),
                                  painter: _CityMapSimulationPainter(
                                    progress: t,
                                    pulse: _pulseController.value,
                                  ),
                                ),
                              ),

                              // Dynamic Interactive Overlays (Pins, Signals, Citizens, Ambulance)
                              _buildMapOverlayElements(t, mapW, mapH),

                              // Live Motivation Banner at Bottom
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 10,
                                child: _buildMotiveNarrationBanner(t),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SIMULATION HEADER: STEPS & CONTROLS
  // ==========================================
  Widget _buildSimulatorHeader(double t) {
    final int currentStep = t < 0.18
        ? 1
        : t < 0.50
            ? 2
            : t < 0.82
                ? 3
                : 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(bottom: BorderSide(color: AppColors.slate200)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE SATELLITE RADAR • HOW IT WORKS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _togglePlayPause,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 14,
                        color: AppColors.slate700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying ? 'Pause' : 'Play',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Clickable Step Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _stepScrubberPill(1, '1. Route Lock', currentStep == 1, 0.05),
                const SizedBox(width: 6),
                _stepScrubberPill(2, '2. En Route', currentStep == 2, 0.28),
                const SizedBox(width: 6),
                _stepScrubberPill(3, '3. Citizen Alert', currentStep == 3, 0.58),
                const SizedBox(width: 6),
                _stepScrubberPill(4, '4. ER Handoff', currentStep == 4, 0.88),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepScrubberPill(
      int index, String label, bool isActive, double seekPos) {
    return InkWell(
      onTap: () => _seekToPhase(seekPos),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.emerald : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.emerald : AppColors.slate200,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DYNAMIC MAP OVERLAYS (AMBULANCE, CITIZENS, SIGNALS)
  // ==========================================
  Widget _buildMapOverlayElements(double t, double width, double height) {
    // Coordinate Anchors
    final startX = width * 0.12;
    final startY = height * 0.72;
    final corner1X = width * 0.40;
    final corner1Y = height * 0.72;
    final corner2X = width * 0.40;
    final corner2Y = height * 0.28;
    final endX = width * 0.86;
    final endY = height * 0.28;

    final seg1 = (corner1X - startX).abs();
    final seg2 = (corner1Y - corner2Y).abs();
    final seg3 = (endX - corner2X).abs();
    final totalDist = seg1 + seg2 + seg3;

    // Ambulance Trajectory Calculation
    double ambX = startX;
    double ambY = startY;
    double ambAngle = 0.0;

    if (t < 0.14) {
      ambX = startX;
      ambY = startY;
      ambAngle = 0.0;
    } else if (t >= 0.84) {
      ambX = endX;
      ambY = endY;
      ambAngle = 0.0;
    } else {
      final subP = (t - 0.14) / 0.70; // 0.0 to 1.0 movement
      final d = subP * totalDist;

      if (d <= seg1) {
        ambX = startX + d;
        ambY = startY;
        ambAngle = 0.0; // Heading east
      } else if (d <= seg1 + seg2) {
        ambX = corner1X;
        ambY = startY - (d - seg1);
        ambAngle = -math.pi / 2; // Heading north
      } else {
        ambX = corner2X + (d - seg1 - seg2);
        ambY = corner2Y;
        ambAngle = 0.0; // Heading east
      }
    }

    // Citizen 1 (In path on Segment 1)
    final cit1X = width * 0.28;
    double cit1Y = startY;
    bool cit1Alerted = (t >= 0.18 && t <= 0.42);
    // Yields to bottom shoulder when ambulance approaches
    if (t >= 0.22 && t < 0.34) {
      cit1Y = startY + ((t - 0.22) / 0.12) * (height * 0.10);
    } else if (t >= 0.34) {
      cit1Y = startY + (height * 0.10); // Fully pulled over
    }

    // Signal 1 at Corner 1 (Preempts to GREEN at t >= 0.25)
    final bool signal1Green = (t >= 0.25);

    // Citizen 2 (In path on Segment 3)
    final cit2X = width * 0.65;
    double cit2Y = corner2Y;
    bool cit2Alerted = (t >= 0.50 && t <= 0.76);
    // Yields to top shoulder when ambulance approaches
    if (t >= 0.54 && t < 0.66) {
      cit2Y = corner2Y - ((t - 0.54) / 0.12) * (height * 0.10);
    } else if (t >= 0.66) {
      cit2Y = corner2Y - (height * 0.10); // Fully pulled over
    }

    // Signal 2 at Corner 2 (Preempts to GREEN at t >= 0.46)
    final bool signal2Green = (t >= 0.46);

    return Stack(
      children: [
        // 1. Origin Pin: Emergency Incident Location (Point A)
        Positioned(
          left: startX - 22,
          top: startY - 48,
          child: _buildMapPin(
            icon: Icons.emergency_rounded,
            color: AppColors.primary,
            label: 'Incident Site',
            subLabel: 'Point A • SOS Triggered',
          ),
        ),

        // 2. Destination Pin: Apex Trauma ER (Point B)
        Positioned(
          left: endX - 22,
          top: endY - 48,
          child: _buildMapPin(
            icon: Icons.local_hospital_rounded,
            color: AppColors.emerald,
            label: 'Apex Trauma ER',
            subLabel: 'Point B • Ready',
            isDestination: true,
            isReached: t >= 0.84,
          ),
        ),

        // 3. Traffic Signal 1 (Intersection 1)
        Positioned(
          left: corner1X - 16,
          top: corner1Y - 40,
          child: _buildTrafficSignal(signal1Green, 'Crossing 1'),
        ),

        // 4. Traffic Signal 2 (Intersection 2)
        Positioned(
          left: corner2X - 16,
          top: corner2Y - 40,
          child: _buildTrafficSignal(signal2Green, 'Crossing 2'),
        ),

        // 5. Citizen Commuter 1 with Live Push Notification Bubble
        Positioned(
          left: cit1X - 14,
          top: cit1Y - 14,
          child: _buildCitizenCar(
            name: 'Aarav (Commuter)',
            isPulledOver: t >= 0.34,
            isAlerted: cit1Alerted,
          ),
        ),
        if (cit1Alerted)
          Positioned(
            left: math.max(10.0, cit1X - 90),
            top: cit1Y - 76,
            child: _buildPushNotificationPopup(
              title: '⚠️ AMBULANCE IN 300M',
              message: 'Pull to left curb immediately!',
              status: t >= 0.32 ? '✓ YIELDED' : 'MOVING...',
            ),
          ),

        // 6. Citizen Commuter 2 with Live Push Notification Bubble
        Positioned(
          left: cit2X - 14,
          top: cit2Y - 14,
          child: _buildCitizenCar(
            name: 'Priya (Commuter)',
            isPulledOver: t >= 0.66,
            isAlerted: cit2Alerted,
          ),
        ),
        if (cit2Alerted)
          Positioned(
            left: math.max(10.0, cit2X - 95),
            top: cit2Y + 24,
            child: _buildPushNotificationPopup(
              title: '⚠️ GREEN CORRIDOR ACTIVE',
              message: 'Emergency vehicle behind. Yield right.',
              status: t >= 0.64 ? '✓ YIELDED' : 'YIELDING...',
            ),
          ),

        // 7. Moving Ambulance Vehicle with Siren Strobes & Radar Pulse
        Positioned(
          left: ambX - 20,
          top: ambY - 20,
          child: _buildMovingAmbulanceMarker(ambAngle, t >= 0.84),
        ),

        // 8. ER Arrival Success Badge
        if (t >= 0.84)
          Positioned(
            right: 18,
            top: 14,
            child: _buildSuccessDeliveryBadge(),
          ),
      ],
    );
  }

  // Map Location Marker Pin
  Widget _buildMapPin({
    required IconData icon,
    required Color color,
    required String label,
    required String subLabel,
    bool isDestination = false,
    bool isReached = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                subLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: isReached ? 4 : 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ],
    );
  }

  // Traffic Light Indicator
  Widget _buildTrafficSignal(bool isGreen, String label) {
    final activeColor = isGreen ? AppColors.emerald : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.06),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isGreen ? 'GREEN' : 'RED',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }

  // Citizen Commuter Vehicle Marker
  Widget _buildCitizenCar({
    required String name,
    required bool isPulledOver,
    required bool isAlerted,
  }) {
    final statusColor = isPulledOver ? AppColors.emerald : AppColors.slate700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isAlerted
                ? AppColors.primaryLight
                : isPulledOver
                    ? AppColors.emeraldLight
                    : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isAlerted
                  ? AppColors.primary
                  : isPulledOver
                      ? AppColors.emerald
                      : AppColors.slate300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isAlerted ? AppColors.primary : AppColors.slate900)
                    .withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: isAlerted
                ? AppColors.primary
                : isPulledOver
                    ? AppColors.emeraldDark
                    : AppColors.slate700,
            size: 16,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isPulledOver ? '✓ Yielded' : 'Commuter',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  // The Push Notification Alert Bubble
  Widget _buildPushNotificationPopup({
    required String title,
    required String message,
    required String status,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Moving Ambulance Vehicle Marker with Siren Flash
  Widget _buildMovingAmbulanceMarker(double angle, bool hasArrived) {
    final sirenPhase = _sirenController.value;
    final bool redFlash = sirenPhase < 0.5;

    return Transform.rotate(
      angle: angle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Geofence Radar Aura
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (redFlash ? AppColors.primary : AppColors.emerald)
                  .withValues(alpha: 0.15),
            ),
          ),

          // Ambulance Vehicle Body
          Container(
            width: 38,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.slate300, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Red Side Decals
                Positioned(
                  left: 2,
                  right: 2,
                  height: 3,
                  child: Container(color: AppColors.primary),
                ),
                // Flashing Roof Siren Bar
                Container(
                  width: 14,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: redFlash
                          ? [AppColors.primary, const Color(0xFF06B6D4)]
                          : [const Color(0xFF06B6D4), AppColors.primary],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Success Delivery Toast
  Widget _buildSuccessDeliveryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TRAUMA ER ADMISSION SUCCESS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'Zero delays • 4.2 minutes preserved',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Explanatory Motive Ticker at Bottom
  Widget _buildMotiveNarrationBanner(double t) {
    String stepNumber = 'STEP 1';
    String motiveTitle = 'Route Locked & Green Corridor Activated';
    String motiveDesc =
        'System interconnects Incident Location and Apex Hospital, creating a dedicated green fast-track.';
    Color accentColor = AppColors.emerald;

    if (t < 0.18) {
      stepNumber = 'STEP 1: ROUTE LOCK';
      motiveTitle = 'Origin & Hospital Connected on Map';
      motiveDesc =
          'Direct route calculated between emergency site and hospital trauma bay, illuminated as Active Green Corridor.';
      accentColor = AppColors.emerald;
    } else if (t < 0.50) {
      stepNumber = 'STEP 2: CITIZEN PUSH ALERT';
      motiveTitle = 'Proximity Warnings Sent to Drivers';
      motiveDesc =
          'Commuters in the path receive real-time siren notifications on their phones and pull over to clear the lane.';
      accentColor = AppColors.primary;
    } else if (t < 0.82) {
      stepNumber = 'STEP 3: AUTOMATED GREEN WAVE';
      motiveTitle = 'Traffic Signals Overridden Automatically';
      motiveDesc =
          'Intersections turn Green before arrival. Ambulance moves continuously without ever stopping at red lights.';
      accentColor = AppColors.emeraldDark;
    } else {
      stepNumber = 'STEP 4: GOLDEN HOUR SAVED';
      motiveTitle = 'Zero-Delay Trauma Bay Intake';
      motiveDesc =
          'Patient arrives safely inside the critical golden hour with surgery team prepped and zero transit friction.';
      accentColor = AppColors.emerald;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stepNumber,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  motiveTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                Text(
                  motiveDesc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: AppColors.slate600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for stylized city map grid and dynamic glowing green corridor
class _CityMapSimulationPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _CityMapSimulationPainter({
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle City Street Blocks Grid
    final blockPaint = Paint()
      ..color = AppColors.slate100.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Background building blocks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.26, h * 0.52),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, h * 0.38, w * 0.36, h * 0.46),
        const Radius.circular(12),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, h * 0.08, w * 0.36, h * 0.14),
        const Radius.circular(12),
      ),
      blockPaint,
    );

    // 2. Base Road Asphalt Network
    final roadPaint = Paint()
      ..color = AppColors.slate200.withValues(alpha: 0.9)
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final startX = w * 0.12;
    final startY = h * 0.72;
    final corner1X = w * 0.40;
    final corner1Y = h * 0.72;
    final corner2X = w * 0.40;
    final corner2Y = h * 0.28;
    final endX = w * 0.86;
    final endY = h * 0.28;

    final roadPath = Path()
      ..moveTo(startX, startY)
      ..lineTo(corner1X, corner1Y)
      ..lineTo(corner2X, corner2Y)
      ..lineTo(endX, endY);

    // Draw gray asphalt path
    canvas.drawPath(roadPath, roadPaint);

    // 3. Active Green Corridor (Lights up into glowing emerald)
    final bool corridorActive = (progress >= 0.06);

    if (corridorActive) {
      // Outer Radiant Emerald Glow
      final glowPaint = Paint()
        ..color = AppColors.emerald.withValues(alpha: 0.22 + (pulse * 0.10))
        ..strokeWidth = 32.0 + (pulse * 6.0)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawPath(roadPath, glowPaint);

      // Core Vibrant Green Corridor Line
      final corridorPaint = Paint()
        ..color = AppColors.emerald
        ..strokeWidth = 10.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(roadPath, corridorPaint);

      // Animated White/Green Speed Dashes
      final dashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      // Draw dashed lane markings along Segment 1
      _drawDashedLine(
        canvas,
        Offset(startX, startY),
        Offset(corner1X, corner1Y),
        dashPaint,
        dashLen: 8,
        spaceLen: 8,
      );
      // Segment 2
      _drawDashedLine(
        canvas,
        Offset(corner1X, corner1Y),
        Offset(corner2X, corner2Y),
        dashPaint,
        dashLen: 8,
        spaceLen: 8,
      );
      // Segment 3
      _drawDashedLine(
        canvas,
        Offset(corner2X, corner2Y),
        Offset(endX, endY),
        dashPaint,
        dashLen: 8,
        spaceLen: 8,
      );
    } else {
      // Initial dashed route calculation before corridor activates
      final connectingPaint = Paint()
        ..color = AppColors.slate400
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      _drawDashedLine(
        canvas,
        Offset(startX, startY),
        Offset(corner1X, corner1Y),
        connectingPaint,
        dashLen: 6,
        spaceLen: 6,
      );
      _drawDashedLine(
        canvas,
        Offset(corner1X, corner1Y),
        Offset(corner2X, corner2Y),
        connectingPaint,
        dashLen: 6,
        spaceLen: 6,
      );
      _drawDashedLine(
        canvas,
        Offset(corner2X, corner2Y),
        Offset(endX, endY),
        connectingPaint,
        dashLen: 6,
        spaceLen: 6,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint, {
    double dashLen = 8,
    double spaceLen = 8,
  }) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double unitX = dx / dist;
    final double unitY = dy / dist;

    double currentDist = 0.0;
    while (currentDist < dist) {
      final double endDist = math.min(dist, currentDist + dashLen);
      canvas.drawLine(
        Offset(p1.dx + unitX * currentDist, p1.dy + unitY * currentDist),
        Offset(p1.dx + unitX * endDist, p1.dy + unitY * endDist),
        paint,
      );
      currentDist += dashLen + spaceLen;
    }
  }

  @override
  bool shouldRepaint(_CityMapSimulationPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}
