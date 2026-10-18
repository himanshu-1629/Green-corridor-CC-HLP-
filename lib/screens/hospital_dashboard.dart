import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'create_mission_screen.dart';
import 'manage_ambulances_screen.dart';
import 'manage_drivers_screen.dart';
import 'mission_center_screen.dart';
import 'login_screen.dart';

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  String hospitalName = "Loading Hospital...";
  String hospitalCode = "...";
  String hospitalAddress = "";
  int ambulanceCount = 0;
  int activeMissionCount = 0;
  int driverCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

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
          hospitalName = userData['name'] ?? "Hospital Facility";
          hospitalCode = userData['hospital_code'] ?? "FAC-01";
          hospitalAddress = userData['address'] ?? "";
          ambulanceCount = ambulances.length;
          activeMissionCount = missions.length;
          driverCount = drivers.length;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text("Hospital Command Center"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Dashboard",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: loadDashboardData,
          ),
          IconButton(
            tooltip: "Sign Out",
            icon: const Icon(Icons.logout_rounded),
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
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboardData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Facility Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppGradients.headerGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.15),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  "CODE: $hospitalCode",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                hospitalName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (hospitalAddress.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.place_outlined,
                                      size: 14,
                                      color: Colors.white.withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        hospitalAddress,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Operational Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.emerald.withValues(alpha: 0.4),
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
                              const SizedBox(width: 6),
                              const Text(
                                "Operational",
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // KPI Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.airport_shuttle_rounded,
                      title: "Ambulances",
                      value: "$ambulanceCount",
                      accentColor: AppColors.primary,
                      bgColor: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard(
                      icon: Icons.alt_route_rounded,
                      title: "Active Missions",
                      value: "$activeMissionCount",
                      accentColor: AppColors.emerald,
                      bgColor: AppColors.emeraldLight,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard(
                      icon: Icons.badge_rounded,
                      title: "Fleet Drivers",
                      value: "$driverCount",
                      accentColor: AppColors.info,
                      bgColor: AppColors.infoLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Primary Emergency Callout (Centered & Full-Card Clickable)
              Material(
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                    decoration: BoxDecoration(
                      gradient: AppGradients.emergency,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Create Emergency Mission",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Fast-track organ, blood, or urgent patient transfer with Green Corridor clearance",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "DISPATCH EMERGENCY MISSION",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Operations Menu
              const Text(
                "Hospital Operations",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),

              _actionTile(
                icon: Icons.assignment_rounded,
                title: "Mission Center",
                subtitle: "Monitor incoming & outgoing live transfer corridors",
                badgeText: activeMissionCount > 0 ? "$activeMissionCount Active" : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MissionCenterScreen()),
                  ).then((_) => loadDashboardData());
                },
              ),
              const SizedBox(height: 12),

              _actionTile(
                icon: Icons.directions_car_filled_rounded,
                title: "Manage Ambulances",
                subtitle: "View fleet status, register and track emergency vehicles",
                badgeText: "$ambulanceCount Vehicles",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageAmbulancesScreen()),
                  ).then((_) => loadDashboardData());
                },
              ),
              const SizedBox(height: 12),

              _actionTile(
                icon: Icons.airline_stops_rounded,
                title: "Manage Drivers",
                subtitle: "Onboard emergency transport drivers and monitor rosters",
                badgeText: "$driverCount Drivers",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageDriversScreen()),
                  ).then((_) => loadDashboardData());
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.slate500,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(radius: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.slate800, size: 22),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.slate400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}