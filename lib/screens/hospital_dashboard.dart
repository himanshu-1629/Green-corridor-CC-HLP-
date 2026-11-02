import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'create_mission_screen.dart';
import 'login_screen.dart';
import 'manage_ambulances_screen.dart';
import 'manage_drivers_screen.dart';
import 'mission_center_screen.dart';

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard>
    with SingleTickerProviderStateMixin {
  String hospitalName = "Metro Trauma Resuscitation Center";
  String hospitalCode = "MTRC-01";
  String hospitalAddress = "Ring Road Medical Enclave, New Delhi";
  int ambulanceCount = 4;
  int activeMissionCount = 2;
  int driverCount = 6;
  bool isLoading = true;

  // Real-Time Hospital Emergency State
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _patient1EtaSeconds = 222; // 03:42
  int _patient2EtaSeconds = 495; // 08:15
  int _heartRate = 122;
  int _spo2 = 94;
  final String _bp = "88/56";
  final int _gcs = 10;

  // Clinical Bay Readiness Flags
  bool _traumaBay1Ready = true;
  bool _ot3SterileReady = true;
  bool _bloodBankOposMatched = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _startSimulatedClinicalTelemetry();
    loadDashboardData();
  }

  void _startSimulatedClinicalTelemetry() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_patient1EtaSeconds > 0) _patient1EtaSeconds--;
        if (_patient2EtaSeconds > 0) _patient2EtaSeconds--;

        // Subtle realistic vitals fluctuation
        if (_patient1EtaSeconds % 4 == 0) {
          _heartRate = 120 + (_patient1EtaSeconds % 6);
          _spo2 = 93 + (_patient1EtaSeconds % 3);
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatEta(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')} min';
  }

  Future<void> loadDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final ambulances = await Supabase.instance.client
          .from('ambulances')
          .select('id')
          .eq('hospital_id', user.id);

      final missions = await Supabase.instance.client
          .from('missions')
          .select('id')
          .eq('hospital_id', user.id)
          .neq('status', 'Completed');

      final drivers = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('role', 'Driver')
          .eq('hospital_id', user.id);

      if (mounted) {
        setState(() {
          if (userData != null) {
            hospitalName = userData['name'] ?? hospitalName;
            hospitalCode = userData['hospital_code'] ?? hospitalCode;
            hospitalAddress = userData['address'] ?? hospitalAddress;
          }
          if (ambulances.isNotEmpty) ambulanceCount = ambulances.length;
          if (missions.isNotEmpty) activeMissionCount = missions.length;
          if (drivers.isNotEmpty) driverCount = drivers.length;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading hospital dashboard data: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF8),
      appBar: _buildClinicalAppBar(context),
      body: RefreshIndicator(
        onRefresh: loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 20,
            vertical: 24,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HOSPITAL EMERGENCY HEADER & LEVEL-1 TRAUMA BADGE
                  _buildHospitalFacilityBanner(isDesktop),
                  const SizedBox(height: 20),

                  // 2. CLINICAL RESOURCE & TRAUMA BAY READINESS STRIP
                  _buildClinicalBayReadinessStrip(isDesktop),
                  const SizedBox(height: 28),

                  // 3. SECTION TITLE: LIVE INBOUND EMERGENCY PATIENT STREAMS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.monitor_heart_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Live Inbound Emergency Patient Streams",
                                style: AppFonts.neueMontreal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.slate900,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                "Real-time in-cabin vitals telemetry & green corridor preemption status",
                                style: AppFonts.neueMontreal(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5 + (_pulseController.value * 0.5),
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.6),
                                        blurRadius: 6 * _pulseController.value,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "2 CRITICAL EN-ROUTE",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. HERO INCOMING PATIENT CARD (STEMI CODE RED)
                  _buildIncomingPatientHeroCard(isDesktop),
                  const SizedBox(height: 16),

                  // 5. SECONDARY INCOMING CARD (DONOR ORGAN TRANSIT)
                  _buildIncomingOrganTransferCard(isDesktop),
                  const SizedBox(height: 32),

                  // 6. EMERGENCY DISPATCH CALLOUT (CODE RED GREEN CORRIDOR)
                  _buildEmergencyDispatchBanner(),
                  const SizedBox(height: 32),

                  // 7. HOSPITAL FACILITY OPERATIONAL METRICS
                  Text(
                    "Facility Fleet & Preemption Operational Health",
                    style: AppFonts.neueMontreal(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMetricsGrid(isDesktop),
                  const SizedBox(height: 32),

                  // 8. HOSPITAL OPERATIONS & RESUSCITATION FLEET
                  Text(
                    "Hospital Emergency Management Hub",
                    style: AppFonts.neueMontreal(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _actionTile(
                    icon: Icons.alt_route_rounded,
                    title: "Active Mission Command Center",
                    subtitle: "Inspect arterial corridor green waves, signal preemption status, and telemetry maps",
                    badgeText: "$activeMissionCount Active Preemptions",
                    badgeColor: AppColors.emerald,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MissionCenterScreen()),
                      ).then((_) => loadDashboardData());
                    },
                  ),
                  const SizedBox(height: 12),

                  _actionTile(
                    icon: Icons.airport_shuttle_rounded,
                    title: "Hospital Ambulance Fleet & Telematics",
                    subtitle: "Manage emergency vehicles, inspect C-V2X transceivers, and configure onboard GPS units",
                    badgeText: "$ambulanceCount Ambulances Registered",
                    badgeColor: AppColors.info,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageAmbulancesScreen()),
                      ).then((_) => loadDashboardData());
                    },
                  ),
                  const SizedBox(height: 12),

                  _actionTile(
                    icon: Icons.badge_rounded,
                    title: "Emergency Transport Drivers & Paramedic Roster",
                    subtitle: "Certified emergency drivers on duty, response shift logs, and active standby schedules",
                    badgeText: "$driverCount Certified Drivers",
                    badgeColor: AppColors.slate600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageDriversScreen()),
                      ).then((_) => loadDashboardData());
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CLINICAL APP BAR
  // ==========================================
  PreferredSizeWidget _buildClinicalAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 24,
      backgroundColor: AppColors.navy,
      foregroundColor: AppColors.cream,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(color: AppColors.sky, height: 2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: AppDecorations.iconMedallion(size: 40),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.sky,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Hospital Emergency Command Center",
                    style: TextStyle(
                      fontFamily: AppTypography.fontHeading,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.cream,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.sky, width: 1.0),
                    ),
                    child: const Text(
                      "LEVEL-1 ED",
                      style: TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sky,
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                "Trauma Resuscitation & Green Wave Signal Controller",
                style: TextStyle(
                  fontFamily: AppTypography.fontBody,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sky,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Live Grid Status Pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.emeraldLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
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
              const SizedBox(width: 6),
              Text(
                "Signals Interlocked",
                style: AppFonts.neueMontreal(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: "Refresh Hospital Status",
          icon: const Icon(Icons.refresh_rounded, color: AppColors.slate700),
          onPressed: loadDashboardData,
        ),
        IconButton(
          tooltip: "Sign Out",
          icon: const Icon(Icons.logout_rounded, color: AppColors.slate700),
          onPressed: () async {
            await Supabase.instance.client.auth.signOut();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  // ==========================================
  // 1. HOSPITAL FACILITY BANNER
  // ==========================================
  Widget _buildHospitalFacilityBanner(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.navy, // Authoritative Navy Blue #0F357C
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            "FACILITY ID: $hospitalCode",
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.flash_on_rounded, color: Color(0xFFFCA5A5), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "TRAUMA STATUS: CODE RED",
                                style: GoogleFonts.jetBrainsMono(
                                  color: const Color(0xFFFCA5A5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hospitalName,
                      style: AppFonts.neueMontreal(
                        color: Colors.white,
                        fontSize: isDesktop ? 28 : 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hospitalAddress,
                            style: AppFonts.neueMontreal(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Resuscitation Deck Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4)),
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
                      "ER Triage Open",
                      style: AppFonts.neueMontreal(
                        color: AppColors.emerald,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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
  // 2. CLINICAL RESOURCE & BAY READINESS STRIP
  // ==========================================
  Widget _buildClinicalBayReadinessStrip(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _bayStatusItem(
            label: "Trauma Resuscitation Bay 1",
            status: _traumaBay1Ready ? "READY & PRIMED" : "PREPPING",
            isReady: _traumaBay1Ready,
            icon: Icons.single_bed_rounded,
            onToggle: () => setState(() => _traumaBay1Ready = !_traumaBay1Ready),
          ),
          _bayStatusItem(
            label: "Trauma Bay 2",
            status: "OCCUPIED (POST-OP)",
            isReady: false,
            isWarning: true,
            icon: Icons.bed_rounded,
          ),
          _bayStatusItem(
            label: "Emergency OT-3 (Cardio-Thoracic)",
            status: _ot3SterileReady ? "STERILE & STANDBY" : "OCCUPIED",
            isReady: _ot3SterileReady,
            icon: Icons.medical_services_rounded,
            onToggle: () => setState(() => _ot3SterileReady = !_ot3SterileReady),
          ),
          _bayStatusItem(
            label: "Blood Bank O-Negative",
            status: _bloodBankOposMatched ? "4 UNITS MATCHED" : "RESERVE LOW",
            isReady: _bloodBankOposMatched,
            icon: Icons.bloodtype_rounded,
            onToggle: () => setState(() => _bloodBankOposMatched = !_bloodBankOposMatched),
          ),
          _bayStatusItem(
            label: "Ambulance Deck Lane 1",
            status: "CLEAR FOR ARRIVAL",
            isReady: true,
            icon: Icons.local_shipping_rounded,
          ),
        ],
      ),
    );
  }

  Widget _bayStatusItem({
    required String label,
    required String status,
    required bool isReady,
    bool isWarning = false,
    required IconData icon,
    VoidCallback? onToggle,
  }) {
    final color = isReady
        ? AppColors.emerald
        : (isWarning ? AppColors.warning : AppColors.primary);
    final bgColor = isReady
        ? AppColors.emeraldLight
        : (isWarning ? AppColors.warningLight : AppColors.primaryLight);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.neueMontreal(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 4. HERO INCOMING PATIENT CARD (STEMI CODE RED)
  // ==========================================
  Widget _buildIncomingPatientHeroCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert Ribbon Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFFEE2E2), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "CODE RED: ACUTE MYOCARDIAL INFARCTION (STEMI)",
                      style: AppFonts.neueMontreal(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF991B1B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: Color(0xFFDC2626), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "GREEN WAVE ENGAGED",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ambulance & ETA Hero Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.airport_shuttle_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AMBULANCE DL-1C-9824",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              "Patient: Male, 54y • Paramedic Unit 4 (Dr. Sharma) • Dispatch origin: South City",
                              style: AppFonts.neueMontreal(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Countdown Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sky.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "ESTIMATED TIME OF ARRIVAL",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, color: AppColors.emerald, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _formatEta(_patient1EtaSeconds),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.emerald,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(1.2 km)",
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // PATIENT LIVE VITALS STREAM (CRITICAL CARE TELEMETRY)
                Text(
                  "LIVE PATIENT IN-CABIN VITALS TELEMETRY (10 Hz STREAM)",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Vitals Cards Row
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _vitalCard(
                      label: "HEART RATE",
                      value: "$_heartRate",
                      unit: "BPM",
                      statusText: "Sinus Tachycardia",
                      accentColor: const Color(0xFFE11D48),
                      icon: Icons.favorite_rounded,
                      isPulsing: true,
                    ),
                    _vitalCard(
                      label: "OXYGEN SAT.",
                      value: "$_spo2",
                      unit: "% SpO2",
                      statusText: "On 15L O2 Reservoir",
                      accentColor: const Color(0xFF0284C7),
                      icon: Icons.air_rounded,
                    ),
                    _vitalCard(
                      label: "BLOOD PRESSURE",
                      value: _bp,
                      unit: "mmHg",
                      statusText: "MAP 67 (Hypotensive)",
                      accentColor: const Color(0xFFD97706),
                      icon: Icons.speed_rounded,
                    ),
                    _vitalCard(
                      label: "GLASGOW COMA",
                      value: "$_gcs/15",
                      unit: "GCS",
                      statusText: "E3 V3 M4 (Impaired)",
                      accentColor: const Color(0xFF7C3AED),
                      icon: Icons.psychology_rounded,
                    ),
                    _vitalCard(
                      label: "TEMPERATURE",
                      value: "36.8",
                      unit: "°C",
                      statusText: "Normothermic",
                      accentColor: const Color(0xFF059669),
                      icon: Icons.thermostat_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Traffic Corridor Interlock Status
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.traffic_rounded,
                          color: AppColors.emeraldDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Arterial Corridor 4 (5/5 Intersections Preempted Ahead)",
                              style: AppFonts.neueMontreal(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              "CC-HLP Active: Queue cleared in advance • 0 vehicle stops • Green lead time +4.58 s/junc",
                              style: AppFonts.neueMontreal(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("🚨 Trauma Bay 1 Team and Cath Lab alerted!"),
                                  backgroundColor: AppColors.emeraldDark,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.emerald),
                              foregroundColor: AppColors.emeraldDark,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: Text(
                              "Alert Cath Lab",
                              style: AppFonts.neueMontreal(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("🎙️ Connecting secure audio radio channel to Ambulance Unit 4..."),
                                  backgroundColor: AppColors.slate900,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.slate900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.headset_mic_rounded, size: 16),
                            label: Text(
                              "Radio Paramedic",
                              style: AppFonts.neueMontreal(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalCard({
    required String label,
    required String value,
    required String unit,
    required String statusText,
    required Color accentColor,
    required IconData icon,
    bool isPulsing = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 155),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            statusText,
            style: AppFonts.neueMontreal(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. SECONDARY INCOMING CARD (ORGAN TRANSIT)
  // ==========================================
  Widget _buildIncomingOrganTransferCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_outline_rounded,
              color: Color(0xFF0284C7),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "ORGAN TRANSIT: DONOR HEART",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "UNOS #8812 • Recipient prepped in OT-1",
                      style: AppFonts.neueMontreal(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Ambulance MH-02-7711 • Cold Ischemic Time: 1h 42m / Max 4h • En route via West Corridor 2",
                  style: AppFonts.neueMontreal(
                    fontSize: 13,
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "ETA: ${_formatEta(_patient2EtaSeconds)}",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0284C7),
                ),
              ),
              Text(
                "4.1 km out • 4 signals ahead",
                style: AppFonts.neueMontreal(
                  fontSize: 11,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. EMERGENCY DISPATCH CALLOUT
  // ==========================================
  Widget _buildEmergencyDispatchBanner() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateMissionScreen(),
            ),
          ).then((_) => loadDashboardData());
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            gradient: AppGradients.emergency,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dispatch Emergency Green Corridor",
                      style: AppFonts.neueMontreal(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Instant municipal signal preemption for critical donor organ transfer, acute cardiac STEMI, or trauma transit with zero intersection delay.",
                      style: AppFonts.neueMontreal(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Dispatch Corridor",
                      style: AppFonts.neueMontreal(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 7. METRICS GRID
  // ==========================================
  Widget _buildMetricsGrid(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.airport_shuttle_rounded,
            title: "Hospital Ambulances",
            value: "$ambulanceCount Units",
            subtitle: "2 In-Transit • 2 Ready in Depot",
            accentColor: AppColors.primary,
            bgColor: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            icon: Icons.alt_route_rounded,
            title: "Corridors In-Flight",
            value: "$activeMissionCount Active",
            subtitle: "CC-HLP Preemption ON",
            accentColor: AppColors.emerald,
            bgColor: AppColors.emeraldLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            icon: Icons.timelapse_rounded,
            title: "Transit Time Saved",
            value: "-14.6 min",
            subtitle: "vs. Standard Red-Light Delays",
            accentColor: const Color(0xFF0284C7),
            bgColor: const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            icon: Icons.groups_rounded,
            title: "Emergency Staff",
            value: "$driverCount Drivers",
            subtitle: "14 ER Specialists Active",
            accentColor: AppColors.slate700,
            bgColor: AppColors.slate100,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Text(
                value,
                style: AppFonts.neueMontreal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate900,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppFonts.neueMontreal(
              color: AppColors.slate900,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppFonts.neueMontreal(
              color: AppColors.slate500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 8. ACTION TILE
  // ==========================================
  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.slate200),
            boxShadow: [
              BoxShadow(
                color: AppColors.slate900.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.slate800, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppFonts.neueMontreal(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.neueMontreal(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.slate400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}