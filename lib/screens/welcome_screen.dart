import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../theme/design_tuning_controller.dart';
import '../widgets/caduceus_3d_emblem.dart';
import '../widgets/city_diorama_3d.dart';
import '../widgets/workflow_step_consoles.dart';
import '../widgets/glass_button.dart';
import '../widgets/tactile_button.dart';
import 'citizen_screen.dart';
import 'hospital_dashboard.dart';
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

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _portalsKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();

  late final AnimationController _scrollBounceController;
  int _selectedEcosystemTab = 0;

  int _totalCorridorsCreated = 0;
  int _activeCorridorsCount = 0;
  int _hospitalsCount = 0;
  bool _isLoadingCorridorStats = true;
  Set<Marker> _landingMapMarkers = {};
  Set<Polyline> _landingMapPolylines = {};
  GoogleMapController? _landingMapController;
  LatLng _landingMapCenter = const LatLng(28.5672, 77.2100);

  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      if (!mounted) return;
      final progress = (_scrollController.offset / 550.0).clamp(0.0, 3.0);
      setState(() {
        _scrollProgress = progress;
      });
    });

    _checkExistingSession();
    _loadLandingMapAndStats();
  }

  Future<void> _loadLandingMapAndStats() async {
    try {
      // 1. Fetch missions/corridors from Supabase
      final missions = await Supabase.instance.client
          .from('missions')
          .select('id, status, created_at, hospital_id, destination_hospital_id, ambulance_id');

      final totalCount = missions.length;
      final activeCount = missions.where((m) => m['status'] != 'Completed').length;

      // 2. Fetch hospitals from Supabase
      final hospitals = await Supabase.instance.client
          .from('users')
          .select('id, name, hospital_code, address, latitude, longitude')
          .eq('role', 'Hospital Admin');

      final Set<Marker> markers = {};
      final Set<Polyline> polylines = {};
      final Map<String, LatLng> hospitalMap = {};
      LatLng? firstHospLocation;

      for (final h in hospitals) {
        if (h['latitude'] != null && h['longitude'] != null) {
          final lat = (h['latitude'] as num).toDouble();
          final lng = (h['longitude'] as num).toDouble();
          final pos = LatLng(lat, lng);
          firstHospLocation ??= pos;
          hospitalMap[h['id'].toString()] = pos;

          markers.add(
            Marker(
              markerId: MarkerId('hosp_${h['id']}'),
              position: pos,
              infoWindow: InfoWindow(
                title: h['name'] ?? 'Hospital Facility',
                snippet: 'Code: ${h['hospital_code'] ?? 'Active ER'} • Green Corridor Hub',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          );
        }
      }

      // Connect corridors between origin & destination hospitals
      for (final m in missions.take(6)) {
        final originId = m['hospital_id']?.toString();
        final destId = m['destination_hospital_id']?.toString();
        if (originId != null &&
            destId != null &&
            hospitalMap.containsKey(originId) &&
            hospitalMap.containsKey(destId)) {
          final start = hospitalMap[originId]!;
          final end = hospitalMap[destId]!;
          polylines.add(
            Polyline(
              polylineId: PolylineId('corridor_${m['id']}'),
              points: [start, end],
              color: m['status'] != 'Completed' ? AppColors.emerald : AppColors.slate400,
              width: m['status'] != 'Completed' ? 5 : 3,
            ),
          );
        }
      }

      // If no corridors connected yet or markers empty, provide baseline reference corridors
      if (polylines.isEmpty && hospitalMap.length >= 2) {
        final hospList = hospitalMap.values.toList();
        for (int i = 0; i < hospList.length - 1; i++) {
          polylines.add(
            Polyline(
              polylineId: PolylineId('hub_corridor_$i'),
              points: [hospList[i], hospList[i + 1]],
              color: AppColors.emerald,
              width: 4,
            ),
          );
        }
      } else if (markers.isEmpty) {
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

  void _showDownloadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.emeraldDark,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Install Mobile App',
                            style: AppFonts.neueMontreal(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Green Corridor Emergency Pilot Suite',
                            style: AppFonts.neueMontreal(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.slate600),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Option 1: Direct APK
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.android_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Android APK',
                                  style: AppFonts.neueMontreal(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.emeraldDark,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'DIRECT',
                                    style: AppFonts.neueMontreal(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Standalone native binary (58 MB)',
                              style: AppFonts.neueMontreal(
                                fontSize: 12,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassButton(
                        onPressed: () {
                          launchUrl(Uri.parse('/app-release.bin'), mode: LaunchMode.externalApplication);
                        },
                        variant: GlassButtonVariant.accent,
                        borderRadius: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        fontSize: 13,
                        label: 'Download',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Option 2: ZIP Archive
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.slate700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.folder_zip_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compressed ZIP',
                              style: AppFonts.neueMontreal(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Contains APK (fast 26 MB package)',
                              style: AppFonts.neueMontreal(
                                fontSize: 12,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassButton(
                        onPressed: () {
                          launchUrl(Uri.parse('/app-release.zip'), mode: LaunchMode.externalApplication);
                        },
                        variant: GlassButtonVariant.secondary,
                        borderRadius: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        fontSize: 13,
                        label: 'Get ZIP',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Option 3: Instant PWA
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.install_mobile_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Install without download (iOS / Android):',
                              style: AppFonts.neueMontreal(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Open this website on mobile Safari or Chrome, tap Share/Options (⋮) -> "Add to Home Screen" to install instantly with live GPS & Siren audio.',
                              style: AppFonts.neueMontreal(
                                fontSize: 11,
                                height: 1.4,
                                color: const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollBounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final bool isDesktop = MediaQuery.of(context).size.width >= 1060;

    // 1. First Landing Viewport: Pure White (#FFFFFF)
    // Caduceus is hidden at scrollOffset == 0.
    // As the hero leaves the viewport (from offset 80px to 450px), opacity gradually increases.
    final double scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final double caduceusReveal = ((scrollOffset - 80.0) / 370.0).clamp(0.0, 1.0);
    // Smooth fade before deep-violet telemetry section
    final double caduceusFade = (1.0 - ((scrollOffset - 2200.0) / 500.0).clamp(0.0, 1.0));
    final double caduceusOpacity = (0.15 * caduceusReveal * caduceusFade).clamp(0.0, 0.15);

    // Initial viewport is pure white: Technical coordinate grid is hidden at top,
    // and emerges smoothly as user scrolls past the hero into the technical documentation.
    final double gridOpacity = ((scrollOffset - 120.0) / 320.0).clamp(0.0, 1.0);

    return ListenableBuilder(
      listenable: DesignTuningController.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white, // Global Page Canvas: Pure White #FFFFFF
          body: Stack(
            children: [
              // 1. Subtle branded background system (reveals on scroll below initial pure-white hero)
              if (gridOpacity > 0.005)
                Positioned.fill(
                  child: Opacity(
                    opacity: gridOpacity,
                    child: CustomPaint(
                      painter: _MedicalGridBackgroundPainter(),
                    ),
                  ),
                ),

              // 2. Persistent 3D Caduceus Background Sculpture revealed on scroll
              // Completely invisible at scroll position 0. Gradually revealed as user scrolls below hero.
              if (caduceusOpacity > 0.005)
                Positioned(
                  top: isDesktop ? 60 : 30,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Opacity(
                        opacity: caduceusOpacity,
                        child: Caduceus3DEmblem(
                          size: isMobile ? 380 : (isDesktop ? 760 : 540),
                          enableInteractiveTilt: false,
                          scrollProgress: _scrollProgress,
                          opacity: caduceusOpacity,
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Main scrollable content
              SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    _buildHeroSection(context),
                    KeyedSubtree(
                      key: _howItWorksKey,
                      child: _buildHowItWorksSection(context),
                    ),
                    KeyedSubtree(
                      key: _portalsKey,
                      child: _buildRolePortalsSection(context),
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
      },
    );
  }

  // ==========================================
  // TOP NAVIGATION BAR
  // ==========================================
  // ==========================================
  // ==========================================
  // TOP NAVIGATION BAR (COMPACT, SKEUOMORPHIC, NEUE MONTREAL)
  // ==========================================
  Widget _buildTopNavigation(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 28,
        vertical: 14,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1180),
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.grey.withValues(alpha: 0.40),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.nearBlack.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Brand Identity
              InkWell(
                onTap: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.emergency_share_rounded,
                          color: AppColors.orange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GREEN CORRIDOR',
                        style: TextStyle(
                          fontFamily: 'NeueMontreal',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.nearBlack,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greyLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.emerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontFamily: 'NeueMontreal',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.nearBlackMuted,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 2. Desktop Navigation Links (balanced spacing, no oversized pills)
              if (!isMobile)
                Row(
                  children: [
                    _buildNavItem(
                      label: 'Overview',
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                    _buildNavItem(
                      label: 'How It Works',
                      onTap: () => _scrollToSection(_howItWorksKey),
                    ),
                    _buildNavItem(
                      label: 'Interfaces',
                      onTap: () => _scrollToSection(_portalsKey),
                    ),
                    _buildNavItem(
                      label: 'Telemetry',
                      onTap: () => _scrollToSection(_statsKey),
                    ),
                    _buildNavItem(
                      label: 'Citizen Siren',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CitizenScreen()),
                        );
                      },
                    ),
                  ],
                ),

              // 3. Right Actions: Sign In + Hospital Portal CTA
              Row(
                children: [
                  if (!isMobile) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.nearBlack,
                        textStyle: const TextStyle(
                          fontFamily: 'NeueMontreal',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Sign In'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TactileButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HospitalDashboard()),
                      );
                    },
                    variant: TactileButtonVariant.primary,
                    borderRadius: 10,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 18,
                      vertical: 10,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    icon: const Icon(Icons.local_hospital_rounded, size: 15, color: Colors.white),
                    label: isMobile ? 'Hospital ER' : 'Hospital Portal',
                  ),
                  if (isMobile) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppColors.nearBlack, size: 22),
                      onPressed: () => _showMobileNavDrawer(context),
                      tooltip: 'Menu',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      hoverColor: AppColors.orange.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'NeueMontreal',
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.nearBlack,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  void _showMobileNavDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GREEN CORRIDOR',
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.nearBlack,
                        letterSpacing: 0.8,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: AppColors.nearBlack),
                  title: const Text('Overview', style: TextStyle(fontFamily: 'NeueMontreal', fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route_outlined, color: AppColors.nearBlack),
                  title: const Text('How It Works', style: TextStyle(fontFamily: 'NeueMontreal', fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollToSection(_howItWorksKey);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: AppColors.nearBlack),
                  title: const Text('Specialized Interfaces', style: TextStyle(fontFamily: 'NeueMontreal', fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollToSection(_portalsKey);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insights_outlined, color: AppColors.nearBlack),
                  title: const Text('Clinical Telemetry', style: TextStyle(fontFamily: 'NeueMontreal', fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _scrollToSection(_statsKey);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cell_tower_rounded, color: AppColors.orange),
                  title: const Text('Citizen Siren App', style: TextStyle(fontFamily: 'NeueMontreal', fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenScreen()));
                  },
                ),
                const SizedBox(height: 12),
                TactileButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  variant: TactileButtonVariant.secondary,
                  borderRadius: 10,
                  label: 'Sign In to Portal',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // ==========================================
  // HERO SECTION: TWO-COLUMN ARCHITECTURE (LEFT CONTENT + RIGHT 3D CITY DIORAMA)
  // WITH SIMULTANEOUS INDEPENDENT 3D CADUCEUS BACKGROUND SCULPTURE
  // ==========================================
  Widget _buildHeroSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1060;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 0,
        bottom: isMobile ? 32 : 56,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Compact Premium Navigation
            _buildTopNavigation(context),

            SizedBox(height: isMobile ? 12 : 24),

            // Foreground Two-Column Hero Architecture
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : (screenWidth >= 1440 ? 64 : 40),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Column: 40% (Headline, Copy, CTAs, Feature Cards)
                          Expanded(
                            flex: 40,
                            child: _buildHeroLeftContent(context, isMobile: false),
                          ),
                          const SizedBox(width: 32),
                          // Right Column: 60% (Dominant, Large Interactive 3D Emergency City Diorama)
                          // Visible immediately in the first viewport!
                          Expanded(
                            flex: 60,
                            child: CityDiorama3D(
                              height: 660,
                              scrollProgress: _scrollProgress,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroLeftContent(context, isMobile: true),
                          const SizedBox(height: 24),
                          CityDiorama3D(
                            height: isMobile ? 380 : 460,
                            scrollProgress: _scrollProgress,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroLeftContent(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Operational Status Indicator Well
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.grey.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.nearBlack.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.5,
                height: 6.5,
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE MEDICAL TRANSIT NETWORK // ARTERIAL CORRIDOR COORDINATION',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nearBlackMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Uppercase Eyebrow
        const Text(
          'SEAMLESS EMERGENCY COORDINATION',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontFamily: 'NeueMontreal',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.orange,
            letterSpacing: 1.8,
          ),
        ),

        const SizedBox(height: 12),

        // Main Headline in Neue Montreal Semibold (Left-aligned, ~2-3 lines on desktop)
        Text(
          'Connecting Lives.\nAcross Every Mile.',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontFamily: 'NeueMontreal',
            fontSize: isMobile ? 32 : 44,
            fontWeight: FontWeight.w600,
            color: AppColors.nearBlack,
            letterSpacing: -0.9,
            height: 1.15,
          ),
        ),

        const SizedBox(height: 16),

        // Concise Supporting Description (Left-aligned)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Coordinating critical medical transportation through a connected platform for hospitals, ambulances, and authorized participants.',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w400,
              color: AppColors.nearBlackMuted,
              height: 1.55,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Dual Tactile Calls to Action (Left-aligned)
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          children: [
            // Primary Action: Orange Tactile CTA
            TactileButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HospitalDashboard()),
                );
              },
              variant: TactileButtonVariant.primary,
              icon: const Icon(Icons.local_hospital_rounded, size: 16, color: Colors.white),
              label: 'Get Started',
              borderRadius: 10,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 30,
                vertical: 15,
              ),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),

            // Secondary Action: Clean White Surface
            TactileButton(
              onPressed: () => _scrollToSection(_howItWorksKey),
              variant: TactileButtonVariant.secondary,
              icon: const Icon(Icons.radar_rounded, size: 16, color: AppColors.brown),
              label: 'Explore Platform',
              borderRadius: 10,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 22 : 26,
                vertical: 15,
              ),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Compact, Lightweight Metric Cards
        Wrap(
          spacing: 12,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          children: [
            _buildMetricCard(
              icon: Icons.alt_route_rounded,
              iconColor: AppColors.orange,
              value: _activeCorridorsCount > 0 ? '$_activeCorridorsCount Active' : 'Transit Grid Ready',
              label: 'Emergency Corridors',
            ),
            _buildMetricCard(
              icon: Icons.local_hospital_rounded,
              iconColor: AppColors.brown,
              value: _hospitalsCount > 0 ? '$_hospitalsCount Facilities' : 'Multi-Facility Link',
              label: 'Connected Trauma Hubs',
            ),
            _buildMetricCard(
              icon: Icons.timer_outlined,
              iconColor: AppColors.nearBlack,
              value: 'Golden Hour Priority',
              label: 'Transit Protocol',
            ),
          ],
        ),
      ],
    );
  }

  // Refined, visually lightweight metric card
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : 220,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.grey.withValues(alpha: 0.28),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.nearBlack.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.nearBlack,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1.5),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.nearBlackMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  // ==========================================
  // ROLE MATRIX SECTION (3 STAKEHOLDER PORTALS)
  // ==========================================
  // DYNAMIC GLASSMORPHISM ECOSYSTEM WORKSTATION
  // ==========================================
  Widget _buildRolePortalsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final tuning = DesignTuningController.instance;

    return Container(
      width: double.infinity,
      color: Colors.transparent, // Seamless continuation of unified canvas
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 18 : 48,
        vertical: tuning.layoutSectionSpacing,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: tuning.layoutContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ecosystem pill banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.greyFaint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.40),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'THREE-TIER SYSTEM ARCHITECTURE',
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.nearBlackMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'One Unified Mission.\nThree Specialized Interfaces.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: AppColors.nearBlack,
                  letterSpacing: -0.6,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: const Text(
                  'Hospital resuscitation teams operate through this dedicated desktop web command center, while ambulance drivers and everyday commuters interact via native mobile apps with real-time acoustic and visual alerts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.nearBlackMuted,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // THE SKEUOMORPHIC TAB BAR
              Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.greyFaint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.grey.withValues(alpha: 0.40),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.nearBlack.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildGlassTabButton(
                        index: 0,
                        icon: Icons.local_hospital_rounded,
                        label: isMobile ? 'Hospital (Web)' : 'Hospital Level-1 Trauma Web Console',
                      ),
                      _buildGlassTabButton(
                        index: 1,
                        icon: Icons.navigation_rounded,
                        label: isMobile ? 'Driver (App)' : 'Ambulance Pilot Cockpit App',
                      ),
                      _buildGlassTabButton(
                        index: 2,
                        icon: Icons.cell_tower_rounded,
                        label: isMobile ? 'Citizen (App)' : 'Citizen Siren Radar App',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // DYNAMIC SKEUOMORPHIC SHOWCASE CARD FOR THE ACTIVE TAB
              _buildActiveTabGlassmorphismCard(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedEcosystemTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedEcosystemTab = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.nearBlack : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.nearBlack.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.orange : AppColors.nearBlackMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.nearBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabGlassmorphismCard(BuildContext context, bool isMobile) {
    if (_selectedEcosystemTab == 0) {
      // TAB 0: HOSPITAL WEB COMMAND PORTAL
      return _buildGlassworkstationCard(
        context: context,
        isMobile: isMobile,
        badgeText: 'CENTRAL WEB PLATFORM (HOSPITAL COMMAND)',
        badgeColor: AppColors.primaryLight,
        badgeTextColor: AppColors.primaryDark,
        title: 'Hospital Level-1 Trauma Command Center',
        subtitle:
            'Dedicated desktop & web workstation for Level-1 trauma triage directors, emergency surgeons, and cath-lab coordinators. Live in-cabin patient telemetry and arterial corridor preemption authority.',
        features: [
          'Live 10 Hz patient vitals (ECG, SpO2, BP, GCS)',
          'Automatic trauma bay & cath-lab pre-allocation',
          'Cold ischemic clock for donor organ transit',
          'Direct green corridor override authorization',
        ],
        buttonText: 'Launch Hospital Web Console →',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HospitalDashboard()),
          );
        },
        previewWidget: _buildHospitalTelemetryLivePreview(),
      );
    } else if (_selectedEcosystemTab == 1) {
      // TAB 1: AMBULANCE DRIVER MOBILE APP
      return _buildGlassworkstationCard(
        context: context,
        isMobile: isMobile,
        badgeText: 'NATIVE MOBILE APP (IN-CABIN COCKPIT)',
        badgeColor: AppColors.emeraldLight,
        badgeTextColor: AppColors.emeraldDark,
        title: 'Ambulance Driver Cockpit Mobile App',
        subtitle:
            'In-cabin heads-up mobile cockpit for emergency vehicle pilots with turn-by-turn preemption routing, queue discharge clearance, and intersection green phase countdowns.',
        features: [
          'Turn-by-turn green wave preemption HUD',
          '15km automated signal light override',
          'Zero hard-braking queue clearance guidance',
          'Instant paramedic patient vitals transmitter',
        ],
        buttonText: 'Download Driver Mobile App',
        onPressed: () => _showDownloadModal(context),
        previewWidget: _buildDriverCockpitLivePreview(),
      );
    } else {
      // TAB 2: CITIZEN SIREN RADAR MOBILE APP
      return _buildGlassworkstationCard(
        context: context,
        isMobile: isMobile,
        badgeText: 'NATIVE MOBILE APP (PUBLIC SAFETY)',
        badgeColor: AppColors.infoLight,
        badgeTextColor: AppColors.info,
        title: 'Citizen Siren Radar Mobile App',
        subtitle:
            'Proactive mobile app for commuters and drivers delivering 800m acoustic & visual siren warnings to yield lanes smoothly before the ambulance arrives.',
        features: [
          '800m acoustic siren proximity radar',
          'Real-time pull-over lane guidance instructions',
          '1-tap emergency SOS dispatch trigger',
          'Civic cooperation karma recognition',
        ],
        buttonText: 'Launch Siren Radar / Download App',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CitizenScreen()),
          );
        },
        previewWidget: _buildCitizenRadarLivePreview(),
      );
    }
  }

  Widget _buildGlassworkstationCard({
    required BuildContext context,
    required bool isMobile,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String subtitle,
    required List<String> features,
    required String buttonText,
    required VoidCallback onPressed,
    required Widget previewWidget,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 22 : 36),
      decoration: AppDecorations.skeuomorphicRaised(
        surfaceColor: Colors.white,
        radius: 28,
      ),
      child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Text & Features
              Expanded(
                flex: isMobile ? 0 : 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: AppDecorations.skeuomorphicInset(radius: 20),
                      child: Text(
                        badgeText,
                        style: AppFonts.neueMontreal(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepViolet,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepViolet,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 14,
                        color: AppColors.deepViolet.withValues(alpha: 0.82),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: AppColors.warmPeach.withValues(alpha: 0.6), height: 1),
                    const SizedBox(height: 20),
                    Column(
                      children: features.map((feat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: AppDecorations.iconMedallion(radius: 8),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.deepViolet,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  feat,
                                  style: TextStyle(
                                    fontFamily: 'NeueMontreal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepViolet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    TactileButton(
                      onPressed: onPressed,
                      variant: TactileButtonVariant.primary,
                      borderRadius: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      fontSize: 14,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.warmPeach),
                      label: buttonText,
                    ),
                  ],
                ),
              ),

              if (!isMobile) const SizedBox(width: 48),
              if (isMobile) const SizedBox(height: 32),

              // Right Column: Live Interactive Glass Preview
              Expanded(
                flex: isMobile ? 0 : 10,
                child: previewWidget,
              ),
            ],
          ),
    );
  }

  // --- PREVIEWS FOR THE 3 TABS ---

  Widget _buildHospitalTelemetryLivePreview() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sky, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE CLINICAL TELEMETRY',
                    style: AppFonts.neueMontreal(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '10 Hz SYNC',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Patient 1 • STEMI Code Red',
            style: AppFonts.neueMontreal(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Ambulance DL-1C-9824 • ETA: 03:42',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 18),
          // Vitals Row
          Row(
            children: [
              Expanded(
                child: _buildTelemetryStatBox(
                  title: 'HEART RATE',
                  value: '122',
                  unit: 'BPM',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryStatBox(
                  title: 'O2 SAT (SpO2)',
                  value: '94%',
                  unit: 'NORMAL',
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTelemetryStatBox(
                  title: 'BLOOD PRESS.',
                  value: '88/56',
                  unit: 'mmHg',
                  color: AppColors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Readiness Pills
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.meeting_room_rounded, color: AppColors.emerald, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Trauma Bay 1:',
                      style: AppFonts.neueMontreal(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  'RESERVED & STERILE',
                  style: AppFonts.neueMontreal(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCockpitLivePreview() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed_rounded, color: AppColors.emerald, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'IN-CABIN PREEMPTION HUD',
                    style: AppFonts.neueMontreal(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emeraldLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Text(
                '68 KM/H',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Arterial Corridor 4 • West Sector',
            style: AppFonts.neueMontreal(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            '3 Intersections Automatically Overridden',
            style: AppFonts.neueMontreal(
              fontSize: 12,
              color: AppColors.emerald,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.traffic_rounded, color: AppColors.emerald, size: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT: SIGNAL 14B (MAIN CHOWK)',
                      style: AppFonts.neueMontreal(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'GREEN LOCKED • 0 HARD-BRAKING PROBABILITY',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldLight,
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

  Widget _buildCitizenRadarLivePreview() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.radar_rounded, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'ACOUSTIC SIREN RADAR',
                    style: AppFonts.neueMontreal(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.infoLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SIREN BEACON',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Emergency Vehicle Approaching',
            style: AppFonts.neueMontreal(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'Distance: 480 meters behind • Moving at 70 km/h',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.turn_right_rounded, color: AppColors.info, size: 28),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTION: YIELD RIGHT LANE SAFELY',
                      style: AppFonts.neueMontreal(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Civic Karma: +50 Points upon clearance',
                      style: AppFonts.neueMontreal(
                        fontSize: 11,
                        color: AppColors.infoLight,
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

  Widget _buildTelemetryStatBox({
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.neueMontreal(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            unit,
            style: AppFonts.neueMontreal(
              fontSize: 8.5,
              color: AppColors.slate400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HOW IT WORKS: 4-STAGE CORRIDOR FLOW WITH INTERACTIVE TILES ANIMATION
  // ==========================================
  Widget _buildHowItWorksSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final tuning = DesignTuningController.instance;

    final steps = [
      {
        'num': '01',
        'title': 'Emergency SOS Trigger',
        'desc':
            'Citizen initiates SOS via radar or hospital ER alerts dynamic dispatch. Nearest optimized ambulance is deployed instantly.',
        'icon': Icons.notifications_active_rounded,
        'color': AppColors.orange,
      },
      {
        'num': '02',
        'title': 'AI Path Preemption',
        'desc':
            'Smart cloud calculates optimal route and synchronizes with municipal traffic light controllers to establish green corridor.',
        'icon': Icons.alt_route_rounded,
        'color': AppColors.orange,
      },
      {
        'num': '03',
        'title': 'Citizen Proximity Alerts',
        'desc':
            'Commuters in the ambulance route receive geo-fenced siren warnings, guiding lanes clear before vehicle arrival.',
        'icon': Icons.broadcast_on_personal_rounded,
        'color': AppColors.brown,
      },
      {
        'num': '04',
        'title': 'Direct Trauma Ingestion',
        'desc':
            'Ambulance pulls directly into reserved trauma bay with zero pre-admission delay and ER medical teams fully briefed.',
        'icon': Icons.local_hospital_rounded,
        'color': AppColors.nearBlack,
      },
    ];

    return Container(
      width: double.infinity,
      color: Colors.transparent, // Seamless continuation of unified canvas and background 3D sculpture
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: tuning.layoutSectionSpacing,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: tuning.layoutContentWidth),
          child: Column(
            children: [
              // Clean brand status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.greyFaint,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.40),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SEAMLESS AUTONOMOUS PIPELINE',
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.nearBlack,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'How the Green Corridor Operates',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: const Text(
                  'A cyber-physical AI pipeline synchronizing emergency vehicles, municipal signals, and civilian motorists with zero latency.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NeueMontreal',
                    fontSize: 15.5,
                    color: AppColors.nearBlackMuted,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // LIVE SATELLITE RADAR SIMULATION HERO
              Container(
                constraints: const BoxConstraints(maxWidth: 1040),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.nearBlack.withValues(alpha: 0.05),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const GreenCorridorSimulationHero(),
              ),

              const SizedBox(height: 60),

              // 4 Workflow Step Animated Tiles below simulation
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 980) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: steps.asMap().entries.map((entry) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            child: AnimatedWorkflowStepTile(
                              step: entry.value,
                              index: entry.key,
                              totalCount: steps.length,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  } else {
                    return Column(
                      children: steps.asMap().entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: AnimatedWorkflowStepTile(
                            step: entry.value,
                            index: entry.key,
                            totalCount: steps.length,
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TELEMETRY & STATS SECTION (DELIBERATE DEEP VIOLET FEATURE SECTION)
  // ==========================================
  Widget _buildTelemetryStatsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final tuning = DesignTuningController.instance;

    return Container(
      width: double.infinity,
      color: AppColors.deepViolet, // Deliberate Deep Violet Feature Section
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: tuning.layoutSectionSpacing,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.deepVioletLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warmPeach.withValues(alpha: 0.45),
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.warmPeach,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MEASURABLE CLINICAL IMPACT',
                  style: AppFonts.neueMontreal(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.softIvory,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Engineered for Golden Hour Preservation',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: AppColors.softIvory,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Real-time urban transit metrics verified across municipal emergency deployments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 15,
                color: AppColors.softIvory.withValues(alpha: 0.85),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),

          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard('48%', 'Faster Response Time', 'Average reduction in urban transit delay', AppColors.warmPeach),
              _buildStatCard('0.0s', 'Cloud Signal Latency', 'Sub-second edge MQTT synchronization', AppColors.warmPeach),
              _buildStatCard('100%', 'Green Wave Clearance', 'Automated traffic intersection preemptions', AppColors.warmPeach),
              _buildStatCard('24/7', 'Autonomous Availability', 'Redundant fail-over cloud architecture', AppColors.warmPeach),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, String subtitle, Color metricColor) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: AppDecorations.skeuomorphicRaised(
        isDarkSurface: true,
        radius: 20,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppColors.warmPeach,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.softIvory,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NeueMontreal',
              fontSize: 12,
              color: AppColors.softIvory.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================

  // ==========================================
  // WHY CHOOSE US
  // ==========================================
  Widget _buildValuePropositionsSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final tuning = DesignTuningController.instance;

    final benefits = [
      'Automated Traffic Signal Preemption across municipal corridors',
      'Continuous Driver Telemetry HUD with real-time green wave status',
      'Real-Time Citizen Siren Radar alerting vehicles within 500 meters',
      'Instant Emergency Room Trauma Bay pre-allocation & bed lock',
      'Encrypted HIPAA-grade patient vitals and priority dispatch stream',
      'Cloud fail-safe mode with local fallback mesh routing',
    ];

    return Container(
      width: double.infinity,
      color: Colors.transparent, // Seamless continuation of unified canvas
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: tuning.layoutSectionSpacing,
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: tuning.layoutContentWidth),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: AppDecorations.skeuomorphicInset(radius: 20),
                      child: Text(
                        'MISSION RELIABILITY',
                        style: AppFonts.neueMontreal(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepViolet,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Why Municipalities & Healthcare Systems Adopt Green Corridor',
                      style: const TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepViolet,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Traditional emergency services operate in silos—ambulances fight traffic manually while emergency rooms scramble with zero advance notice. Green Corridor synthesizes every link into an automated live grid.',
                      style: TextStyle(
                        fontFamily: 'NeueMontreal',
                        fontSize: 15,
                        color: AppColors.deepViolet.withValues(alpha: 0.82),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TactileButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      variant: TactileButtonVariant.primary,
                      borderRadius: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      fontSize: 14,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.warmPeach),
                      label: 'Request City Onboarding',
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
        ),
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: AppDecorations.skeuomorphicRaised(
        surfaceColor: Colors.white,
        radius: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: AppDecorations.iconMedallion(radius: 8),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.deepViolet,
              size: 14,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.deepViolet,
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
    final tuning = DesignTuningController.instance;

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
      width: double.infinity,
      color: Colors.transparent, // Seamless continuation of unified canvas
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: tuning.layoutSectionSpacing,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.sky,
                width: 1.1,
              ),
            ),
            child: Text(
              'TESTED IN REAL-WORLD CONDITIONS',
              style: AppFonts.neueMontreal(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Endorsed by First Responders',
            textAlign: TextAlign.center,
            style: AppFonts.neueMontreal(
              fontSize: isMobile ? 28 : 38,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Feedback from emergency physicians, fleet dispatchers, and smart traffic engineers.',
              textAlign: TextAlign.center,
              style: AppFonts.neueMontreal(
                fontSize: 14,
                color: AppColors.navyMuted,
                height: 1.5,
              ),
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
    final tuning = DesignTuningController.instance;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tuning.tileRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(tuning.tileCardPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: (tuning.glassSurfaceOpacity * 1.5).clamp(0.18, 0.70)),
                AppColors.cream.withValues(alpha: (tuning.glassSurfaceOpacity * 0.8).clamp(0.10, 0.45)),
              ],
            ),
            borderRadius: BorderRadius.circular(tuning.tileRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: tuning.glassBorderOpacity),
              width: 1.3 * tuning.tileHighlightIntensity,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: tuning.glassShadowOpacity * 1.2),
                blurRadius: tuning.glassShadowBlur,
                offset: Offset(0, tuning.tileShadowOffset),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.55),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item['quote']!,
            style: AppFonts.neueMontreal(
              fontSize: 14,
              color: AppColors.navy,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: AppColors.sky.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.skyLight,
                child: Text(
                  item['name']!.substring(0, 1),
                  style: AppFonts.neueMontreal(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
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
                      style: AppFonts.neueMontreal(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      '${item['role']} • ${item['hospital']}',
                      style: AppFonts.neueMontreal(
                        fontSize: 11,
                        color: AppColors.navyMuted,
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
    ),
  ),
);
  }

  // ==========================================
  // LIVE CORRIDOR MAP & HOW MANY CORRIDORS CREATED
  // ==========================================
  Widget _buildLiveCorridorsMapSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final tuning = DesignTuningController.instance;

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
        color: AppColors.cream.withValues(alpha: tuning.glassSurfaceOpacity),
        borderRadius: BorderRadius.circular(tuning.glassCornerRadius),
        border: Border.all(
          color: AppColors.sky.withValues(alpha: tuning.glassBorderOpacity),
          width: 1.5 * tuning.tileHighlightIntensity,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: tuning.glassShadowOpacity),
            blurRadius: tuning.glassShadowBlur,
            offset: Offset(0, tuning.tileShadowOffset),
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
                    color: AppColors.skyLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.sky,
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
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE OPERATIONS GRID',
                        style: AppFonts.neueMontreal(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
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
                  style: AppFonts.neueMontreal(
                    fontSize: isMobile ? 24 : 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    'Real-time geospatial mesh showing verified green corridor transit lines, registered hospital trauma centers, and live ambulance telemetry.',
                    textAlign: TextAlign.center,
                    style: AppFonts.neueMontreal(
                      fontSize: 14,
                      color: AppColors.navyMuted,
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
                  accentColor: AppColors.navy,
                  badgeText: 'All-Time Dispatches',
                ),
                _buildCorridorMetricCard(
                  title: 'Active In-Transit',
                  value: _isLoadingCorridorStats ? '...' : '$_activeCorridorsCount',
                  subtitle: 'Live ambulances under priority signal lock',
                  icon: Icons.sensors_rounded,
                  accentColor: const Color(0xFF0284C7),
                  badgeText: 'Real-Time Priority',
                ),
                _buildCorridorMetricCard(
                  title: 'Network Hospitals',
                  value: _isLoadingCorridorStats ? '...' : '$_hospitalsCount',
                  subtitle: 'Verified trauma facilities on grid',
                  icon: Icons.local_hospital_rounded,
                  accentColor: AppColors.navyLight,
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
              border: Border.all(
                color: AppColors.sky.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
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
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sky),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.15),
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
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE CORRIDOR RADAR • ${!_isLoadingCorridorStats ? '$_totalCorridorsCreated DISPATCHES' : 'SYNCHRONIZING'}',
                            style: AppFonts.neueMontreal(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
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
                    child: GlassButton(
                      onPressed: () {
                        if (_landingMapController != null) {
                          _landingMapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(_landingMapCenter, 12.0),
                          );
                        }
                      },
                      variant: GlassButtonVariant.secondary,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      fontSize: 12,
                      icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.navy),
                      label: "Center Hubs",
                    ),
                  ),

                  // Full Citizen Radar shortcut (Top-right)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GlassButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CitizenScreen()),
                        );
                      },
                      variant: GlassButtonVariant.primary,
                      borderRadius: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      fontSize: 12,
                      icon: const Icon(Icons.radar_rounded, size: 16, color: AppColors.warmPeach),
                      label: "Full Radar",
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
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.sky,
                width: 1.4,
              ),
            ),
            child: Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.airport_shuttle_rounded,
                    color: AppColors.navy,
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
                        style: AppFonts.neueMontreal(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ambulance drivers are registered exclusively by their hospital authority. Once provisioned by your hospital, sign in here to link your device FCM token for live sirens and green wave navigation.',
                        textAlign: isMobile ? TextAlign.center : TextAlign.start,
                        style: AppFonts.neueMontreal(
                          fontSize: 13,
                          color: AppColors.navyMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20, height: 16),
                GlassButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  variant: GlassButtonVariant.primary,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  fontSize: 13,
                  icon: const Icon(Icons.login_rounded, size: 18, color: AppColors.warmPeach),
                  label: 'Driver Sign In (Sync FCM)',
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
        color: AppColors.cream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.sky.withValues(alpha: 0.6),
          width: 1.2,
        ),
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
                  color: AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.navy, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.skyLight.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sky),
                ),
                child: Text(
                  badgeText,
                  style: AppFonts.neueMontreal(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppFonts.neueMontreal(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.neueMontreal(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppFonts.neueMontreal(
              fontSize: 12,
              color: AppColors.navyMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EXECUTIVE NAVY BLUE FOOTER SECTION
  // ==========================================
  Widget _buildFooterSection(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepViolet,
        border: Border(
          top: BorderSide(color: AppColors.warmPeach.withValues(alpha: 0.35), width: 1.5),
        ),
      ),
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
                        decoration: AppDecorations.iconMedallion(isDark: true, radius: 10),
                        child: const Icon(
                          Icons.emergency_share_rounded,
                          color: AppColors.warmPeach,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GREEN CORRIDOR',
                        style: TextStyle(
                          fontFamily: 'NeueMontreal',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.softIvory,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precision Emergency Transit Optimization Platform for Hospital Administrations.',
                    style: TextStyle(
                      fontFamily: 'NeueMontreal',
                      fontSize: 13,
                      color: AppColors.softIvory.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (isMobile) const SizedBox(height: 24),
              Row(
                children: [
                  _footerLink('Protocol Flow', () => _scrollToSection(_howItWorksKey)),
                  const SizedBox(width: 16),
                  _footerLink('Trauma Portals', () => _scrollToSection(_portalsKey)),
                  const SizedBox(width: 16),
                  _footerLink('Corridor Telemetry', () => _scrollToSection(_statsKey)),
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
          Divider(color: AppColors.warmPeach.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 Green Corridor. All operational rights reserved.',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 12,
                  color: AppColors.softIvory.withValues(alpha: 0.75),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.warmPeach,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warmPeach.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'All Nodes Operational',
                    style: TextStyle(
                      fontFamily: 'NeueMontreal',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.softIvory,
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
        style: TextStyle(
          fontFamily: 'NeueMontreal',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.softIvory.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Interactive animated workflow step tile widget with hover elevation and glowing border
class AnimatedWorkflowStepTile extends StatefulWidget {
  final Map<String, dynamic> step;
  final int index;
  final int totalCount;

  const AnimatedWorkflowStepTile({
    super.key,
    required this.step,
    required this.index,
    required this.totalCount,
  });

  @override
  State<AnimatedWorkflowStepTile> createState() =>
      _AnimatedWorkflowStepTileState();
}

class _AnimatedWorkflowStepTileState extends State<AnimatedWorkflowStepTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final step = widget.step;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          0.0,
          _isHovered ? -6.0 : 0.0,
          0.0,
        ),
        padding: const EdgeInsets.all(22),
        decoration: AppDecorations.skeuomorphicRaised(
          surfaceColor: Colors.white,
          isHovered: _isHovered,
          radius: 22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Step Progress Indicator & Bead
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: AppDecorations.skeuomorphicInset(radius: 20),
                      child: Text(
                        'STAGE ${step['num']}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepViolet,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isHovered ? AppColors.mutedBerry : AppColors.warmPeach,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: AppDecorations.iconMedallion(radius: 12),
                  child: Icon(
                    step['icon'] as IconData,
                    color: AppColors.deepViolet,
                    size: 19,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              step['title'] as String,
              style: const TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: AppColors.deepViolet,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step['desc'] as String,
              style: TextStyle(
                fontFamily: 'NeueMontreal',
                fontSize: 13,
                color: AppColors.deepViolet.withValues(alpha: 0.80),
                height: 1.5,
              ),
            ),
            // Live Interactive Telemetry Console for this workflow stage
            WorkflowStepConsole(
              stepNum: step['num'] as String,
              accentColor: AppColors.deepViolet,
            ),
          ],
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
        color: AppColors.greyFaint,
        border: Border(bottom: BorderSide(color: AppColors.grey.withValues(alpha: 0.30))),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE SATELLITE RADAR • HOW IT WORKS',
                    style: TextStyle(
                      fontFamily: 'NeueMontreal',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.nearBlack,
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
                    border: Border.all(color: AppColors.grey.withValues(alpha: 0.40)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 14,
                        color: AppColors.nearBlack,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying ? 'Pause' : 'Play',
                        style: const TextStyle(
                          fontFamily: 'NeueMontreal',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.nearBlack,
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
          color: isActive ? AppColors.orange : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.orange : AppColors.grey.withValues(alpha: 0.40),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NeueMontreal',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppColors.nearBlackMuted,
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
                style: AppFonts.neueMontreal(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                subLabel,
                style: AppFonts.neueMontreal(
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
            style: AppFonts.neueMontreal(
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
            style: AppFonts.neueMontreal(
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
                        style: AppFonts.neueMontreal(
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
                        style: AppFonts.neueMontreal(
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
                  style: AppFonts.neueMontreal(
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
                style: AppFonts.neueMontreal(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'Zero delays • 4.2 minutes preserved',
                style: AppFonts.neueMontreal(
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
              style: AppFonts.neueMontreal(
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
                  style: AppFonts.neueMontreal(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                Text(
                  motiveDesc,
                  style: AppFonts.neueMontreal(
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

/// Extremely subtle, calm medical background system painter
/// Paints a gentle warm radial glow and a faint coordinate grid on white canvas.
class _MedicalGridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft warm radial glow directly behind the centered 3D caduceus
    final glowCenter = Offset(w / 2, 340);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          AppColors.orange.withValues(alpha: 0.04),
          AppColors.brown.withValues(alpha: 0.015),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: math.min(w * 0.7, 560)));
    canvas.drawCircle(glowCenter, math.min(w * 0.7, 560), glowPaint);

    // 2. Extremely subtle coordinate grid (calm, non-distracting)
    final gridPaint = Paint()
      ..color = AppColors.grey.withValues(alpha: 0.04)
      ..strokeWidth = 0.6;

    const double step = 72.0;

    for (double x = 0; x <= w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y <= h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Subtle technical coordinate crosshairs at grid intersections
    final tickPaint = Paint()
      ..color = AppColors.grey.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;
    for (double x = step * 2; x < w; x += step * 2) {
      for (double y = step * 2; y < h; y += step * 2) {
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), tickPaint);
        canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), tickPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

