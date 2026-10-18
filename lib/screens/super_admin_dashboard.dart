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
              child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text("Super Admin Command"),
          ],
        ),
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Refresh Stats",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: loadSystemStats,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadSystemStats,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppGradients.dark,
                        borderRadius: BorderRadius.circular(22),
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
                            children: [
                              const Text(
                                "Green Corridor Network",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  "ALL SYSTEMS ACTIVE",
                                  style: TextStyle(
                                    color: AppColors.emerald,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Real-time cross-facility emergency medical logistics telematics",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metrics Grid
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            icon: Icons.local_hospital_rounded,
                            title: "Hospitals",
                            value: "$hospitalsCount",
                            color: AppColors.primary,
                            bgColor: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _metricCard(
                            icon: Icons.airport_shuttle_rounded,
                            title: "Ambulances",
                            value: "$ambulancesCount",
                            color: AppColors.emerald,
                            bgColor: AppColors.emeraldLight,
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
                            color: AppColors.info,
                            bgColor: AppColors.infoLight,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _metricCard(
                            icon: Icons.assignment_turned_in_rounded,
                            title: "All Missions",
                            value: "$missionsCount",
                            color: AppColors.warning,
                            bgColor: AppColors.warningLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Quick Management Hub
                    const Text(
                      "Super Admin Hub",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
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
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.card(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
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
      decoration: AppDecorations.card(radius: 18),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: AppColors.primary,
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
                  style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
        ],
      ),
    );
  }
}