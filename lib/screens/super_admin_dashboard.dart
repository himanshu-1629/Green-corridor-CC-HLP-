import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int hospitalsCount = 0;
  int ambulancesCount = 0;
  int driversCount = 0;
  int missionsCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSystemStats();
  }

  Future<void> loadSystemStats() async {
    try {
      final hospitals = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('role', 'Hospital Admin');

      final ambulances = await Supabase.instance.client
          .from('ambulances')
          .select('id');

      final drivers = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('role', 'Driver');

      final missions = await Supabase.instance.client
          .from('missions')
          .select('id');

      if (mounted) {
        setState(() {
          hospitalsCount = hospitals.length;
          ambulancesCount = ambulances.length;
          driversCount = drivers.length;
          missionsCount = missions.length;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading stats: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        titleSpacing: 20,
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
              decoration: AppDecorations.iconMedallion(size: 38),
              child: const Icon(Icons.security_rounded, color: AppColors.sky, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Super Admin Command",
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  "National Emergency Preemption Grid Overseer",
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
          IconButton(
            tooltip: "Refresh Stats",
            icon: const Icon(Icons.refresh_rounded, color: AppColors.sky),
            onPressed: loadSystemStats,
          ),
          IconButton(
            tooltip: "Sign Out",
            icon: const Icon(Icons.logout_rounded, color: AppColors.cream),
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.navy),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadSystemStats,
              color: AppColors.navy,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Executive 3D Banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.sky, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navyDark.withValues(alpha: 0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Green Corridor National Network",
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontHeading,
                                      color: AppColors.cream,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.navyDark,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.sky, width: 1.2),
                                    ),
                                    child: const Text(
                                      "ALL NODES ACTIVE",
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontBody,
                                        color: AppColors.sky,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Real-time cross-facility emergency medical logistics telematics & corridor telemetry",
                                style: TextStyle(
                                  fontFamily: AppTypography.fontBody,
                                  color: AppColors.sky,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Metrics Grid with 3D Sculpted Tiles
                        Row(
                          children: [
                            Expanded(
                              child: _metricCard(
                                icon: Icons.local_hospital_rounded,
                                title: "Hospitals",
                                value: "$hospitalsCount",
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _metricCard(
                                icon: Icons.airport_shuttle_rounded,
                                title: "Ambulances",
                                value: "$ambulancesCount",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _metricCard(
                                icon: Icons.person_pin_rounded,
                                title: "Drivers",
                                value: "$driversCount",
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _metricCard(
                                icon: Icons.assignment_turned_in_rounded,
                                title: "All Missions",
                                value: "$missionsCount",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Quick Management Hub
                        const Text(
                          "Super Admin Command Hub",
                          style: TextStyle(
                            fontFamily: AppTypography.fontHeading,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 14),

                        _adminActionTile(
                          icon: Icons.domain_rounded,
                          title: "Registered Medical Facilities",
                          subtitle: "Audit hospital profiles, API access, and registered codes",
                          badge: "$hospitalsCount Active",
                        ),
                        const SizedBox(height: 12),
                        _adminActionTile(
                          icon: Icons.route_rounded,
                          title: "Network Emergency Telemetry",
                          subtitle: "Review live corridor transits, GPS accuracy, and arrival ETAs",
                          badge: "$missionsCount Total",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: AppDecorations.tile3D(elevation: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sky, width: 1.0),
            ),
            child: Icon(icon, color: AppColors.sky, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.fontHeading,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.fontBody,
              fontSize: 13,
              color: AppColors.navyMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.creamLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sky, width: 1.0),
            ),
            child: Icon(icon, color: AppColors.sky, size: 22),
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
                        fontFamily: AppTypography.fontHeading,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.sky, width: 1.0),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontBody,
                          color: AppColors.cream,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.fontBody,
                    fontSize: 13,
                    color: AppColors.navyMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.navy),
        ],
      ),
    );
  }
}