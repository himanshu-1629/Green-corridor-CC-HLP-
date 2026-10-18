import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
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
                _buildCallToActionBanner(context),
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
          // Right 3D Moving Ambulance Vehicle
          const Expanded(
            flex: 13,
            child: MovingAmbulance3DHero(),
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
          const MovingAmbulance3DHero(),
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
  // CALL TO ACTION BANNER
  // ==========================================
  Widget _buildCallToActionBanner(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 64,
        vertical: 48,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 56,
        vertical: 48,
      ),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.emerald, size: 16),
                const SizedBox(width: 6),
                Text(
                  'READY FOR DEPLOYMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Deploy the Green Corridor in Your Hospital or City Fleet',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Join leading healthcare facilities and municipal emergency squads. Sign up now or launch the interactive citizen map.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                color: AppColors.slate300,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Create Hospital / Driver Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.slate600, width: 1.4),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Open Live Citizen Map',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
// 3D MOVING AMBULANCE FIGURE WITH LIVE STROBES & ROAD SPEEDLINES
// ==========================================
class MovingAmbulance3DHero extends StatefulWidget {
  const MovingAmbulance3DHero({super.key});

  @override
  State<MovingAmbulance3DHero> createState() => _MovingAmbulance3DHeroState();
}

class _MovingAmbulance3DHeroState extends State<MovingAmbulance3DHero>
    with TickerProviderStateMixin {
  late final AnimationController _suspensionController;
  late final AnimationController _roadController;
  late final AnimationController _strobeController;

  // Interactive 3D tilt tracking
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Suspension / floating bobbing animation (sinusoidal)
    _suspensionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 2. Road speed line flow (continuous forward velocity)
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // 3. Emergency roof strobe lightbar (dual-phase high-speed emergency pulse)
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _suspensionController.dispose();
    _roadController.dispose();
    _strobeController.dispose();
    super.dispose();
  }

  void _onPointerMove(PointerEvent details, BoxConstraints constraints) {
    final centerX = constraints.maxWidth / 2;
    final centerY = constraints.maxHeight / 2;

    // Normalizing tilt between -0.15 and 0.15 radians
    final dx = (details.localPosition.dx - centerX) / centerX;
    final dy = (details.localPosition.dy - centerY) / centerY;

    setState(() {
      _tiltY = dx * 0.14; // Y rotation on horizontal mouse movement
      _tiltX = -dy * 0.10; // X rotation on vertical mouse movement
    });
  }

  void _onPointerExit(PointerEvent details) {
    setState(() {
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = cardWidth * 0.95;

        return MouseRegion(
          onHover: (e) => _onPointerMove(e, constraints),
          onExit: _onPointerExit,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            constraints: const BoxConstraints(minHeight: 380, maxHeight: 520),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.slate200.withValues(alpha: 0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.slate900.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.05),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Background Grid & Subtle Corridor Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, -0.2),
                          radius: 1.2,
                          colors: [
                            AppColors.emeraldLight.withValues(alpha: 0.35),
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Animated Moving Road Beneath the 3D Ambulance
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _roadController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _MovingCorridorRoadPainter(
                            progress: _roadController.value,
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Dynamic Vehicle Shadow (breathes with suspension)
                  AnimatedBuilder(
                    animation: _suspensionController,
                    builder: (context, child) {
                      final bob = math.sin(_suspensionController.value * math.pi);
                      final shadowScale = 1.0 - (bob * 0.08);
                      final shadowOpacity = 0.16 - (bob * 0.05);

                      return Positioned(
                        bottom: 70 - (bob * 2),
                        child: Transform.scale(
                          scaleX: shadowScale * 1.3,
                          scaleY: shadowScale * 0.45,
                          child: Container(
                            width: 240,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.slate900
                                      .withValues(alpha: shadowOpacity),
                                  blurRadius: 28,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 4. The 3D Ambulance Figure with Interactive 3D Perspective Tilt & Suspension
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _suspensionController,
                      _strobeController,
                    ]),
                    builder: (context, child) {
                      final bobOffset =
                          math.sin(_suspensionController.value * math.pi) * 8.0;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateX(_tiltX)
                          ..rotateY(_tiltY)
                          ..translateByDouble(0.0, -bobOffset, 0.0, 1.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // The 3D Render Asset
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Image.asset(
                                'assets/images/ambulance_3d.png',
                                fit: BoxFit.contain,
                                width: math.min(cardWidth * 0.82, 380),
                                height: math.min(cardHeight * 0.78, 380),
                              ),
                            ),

                            // Dual-Frequency Emergency Roof Strobe Glows
                            _buildStrobeBeaconOverlay(),
                          ],
                        ),
                      );
                    },
                  ),

                  // 5. Floating Tactical Telemetry Chips Anchored around the 3D Ambulance
                  _buildFloatingTelemetryHUD(),

                  // 6. Interactive Hint Pill at Bottom Right
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.slate200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.slate900.withValues(alpha: 0.04),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.view_in_ar_rounded,
                            size: 14,
                            color: AppColors.slate600,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '3D FIGURINE • HOVER TO TILT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Dual-frequency emergency strobe overlay positioned on roof lightbar
  Widget _buildStrobeBeaconOverlay() {
    final v = _strobeController.value;
    // Phase 1 (0.0 to 0.5): Red Flash; Phase 2 (0.5 to 1.0): Cyan Flash
    final bool redActive = (v < 0.22) || (v > 0.30 && v < 0.44);
    final bool cyanActive = (v > 0.50 && v < 0.72) || (v > 0.80 && v < 0.94);

    return Positioned(
      top: 54,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left Red Beacon Strobe
          AnimatedOpacity(
            opacity: redActive ? 0.95 : 0.05,
            duration: const Duration(milliseconds: 70),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right Cyan Beacon Strobe
          AnimatedOpacity(
            opacity: cyanActive ? 0.95 : 0.05,
            duration: const Duration(milliseconds: 70),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF06B6D4),
                    const Color(0xFF06B6D4).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tactical HUD telemetry cards floating around the vehicle
  Widget _buildFloatingTelemetryHUD() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top-Left: Active Mission Unit Tag
          Positioned(
            top: 20,
            left: 20,
            child: _hudCard(
              icon: Icons.emergency_rounded,
              iconColor: AppColors.primary,
              title: 'UNIT-911',
              subtitle: 'PRIORITY 1 DISPATCH',
              badge: 'EMERGENCY',
              badgeColor: AppColors.primary,
            ),
          ),

          // Top-Right: Green Wave Lock
          Positioned(
            top: 20,
            right: 20,
            child: _hudCard(
              icon: Icons.check_circle_rounded,
              iconColor: AppColors.emerald,
              title: 'GREEN WAVE',
              subtitle: '4 SIGNALS LOCKED',
              badge: 'SYNC 100%',
              badgeColor: AppColors.emerald,
            ),
          ),

          // Bottom-Left: Live Speed & Telemetry
          Positioned(
            bottom: 24,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slate900.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    color: AppColors.slate800,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '78 KM/H',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        'ETA: 03:42 MIN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for animated moving green corridor road markings
class _MovingCorridorRoadPainter extends CustomPainter {
  final double progress;

  _MovingCorridorRoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Perspective Road Trapezoid
    final roadPaint = Paint()
      ..color = AppColors.slate100.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final roadPath = Path()
      ..moveTo(size.width * 0.15, size.height)
      ..lineTo(size.width * 0.85, size.height)
      ..lineTo(size.width * 0.70, 0)
      ..lineTo(size.width * 0.30, 0)
      ..close();

    canvas.drawPath(roadPath, roadPaint);

    // 2. Green Corridor Outer Glowing Borders
    final borderPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.15, size.height),
      Offset(size.width * 0.30, 0),
      borderPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.85, size.height),
      Offset(size.width * 0.70, 0),
      borderPaint,
    );

    // 3. Moving Corridor Dashed Speed Lines (drawn with progress offset)
    final stripePaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.75)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const int stripeCount = 6;
    for (int i = 0; i < stripeCount; i++) {
      final double normalized = ((i / stripeCount) + progress) % 1.0;
      // Linear perspective scale from horizon (0) to bottom (1)
      final double y = normalized * size.height;
      final double stripeLen = 10.0 + (normalized * 22.0);

      // Centered along path
      final double x = size.width * 0.50;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(size.height, y + stripeLen)),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MovingCorridorRoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
