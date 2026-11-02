import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'mission_details_screen.dart';

class MissionCenterScreen extends StatefulWidget {
  const MissionCenterScreen({super.key});

  @override
  State<MissionCenterScreen> createState() => _MissionCenterScreenState();
}

class _MissionCenterScreenState extends State<MissionCenterScreen> {
  List<Map<String, dynamic>> outgoingMissions = [];
  List<Map<String, dynamic>> incomingMissions = [];
  bool isLoading = true;
  List<Map<String, dynamic>> availableDrivers = [];
  String? selectedDriverId;

  @override
  void initState() {
    super.initState();
    loadMissions();
    loadDrivers();
  }

  Future<void> loadMissions() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final outgoing = await Supabase.instance.client
          .from('missions')
          .select()
          .eq('hospital_id', currentUser.id)
          .order('created_at', ascending: false);

      final incoming = await Supabase.instance.client
          .from('missions')
          .select()
          .eq('destination_hospital_id', currentUser.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          outgoingMissions = List<Map<String, dynamic>>.from(outgoing);
          incomingMissions = List<Map<String, dynamic>>.from(incoming);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading missions: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loadDrivers() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'Driver')
          .eq('hospital_id', currentUser.id)
          .eq('is_available', true);

      if (mounted) {
        setState(() {
          availableDrivers = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error loading drivers: $e");
    }
  }

  Future<void> assignDriver(String missionId) async {
    if (selectedDriverId == null) return;

    try {
      await Supabase.instance.client.from('missions').update({
        'driver_id': selectedDriverId,
        'status': 'Assigned',
      }).eq('id', missionId);

      await Supabase.instance.client.from('users').update({
        'is_available': false,
      }).eq('id', selectedDriverId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          content: Text("Driver assigned successfully!"),
        ),
      );

      await loadMissions();
      await loadDrivers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text("Failed to assign driver: $e"),
        ),
      );
    }
  }

  Future<void> _confirmAndCompleteMission(Map<String, dynamic> mission) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Confirm Transfer Receipt?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          "Confirm that this emergency medical transfer was successfully received at your facility. This will mark the mission Completed and immediately release the assigned ambulance and driver back to Available status.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm Received"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final missionId = mission['id'];

      await Supabase.instance.client
          .from('missions')
          .update({'status': 'Completed'})
          .eq('id', missionId);

      // Note: Ambulance and Driver remain unavailable until the driver
      // performs the return journey and marks Available back at origin base.

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          content: Text("Transfer Confirmed! Mission Completed. Driver notified to return to base."),
        ),
      );

      await loadMissions();
      await loadDrivers();
    } catch (e) {
      debugPrint("Error completing incoming mission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text("Error: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 20,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.slate900,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mission Dispatch Center",
                    style: AppFonts.neueMontreal(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    "Real-Time Corridor Tracking & Ingestion",
                    style: AppFonts.neueMontreal(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.slate200, width: 1)),
              ),
              child: TabBar(
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.slate500,
                labelStyle: AppFonts.neueMontreal(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: AppFonts.neueMontreal(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.outbox_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text("Outgoing (${outgoingMissions.length})"),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.move_to_inbox_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text("Incoming (${incomingMissions.length})"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: TabBarView(
                    children: [
                      _missionList(outgoingMissions, isOutgoing: true),
                      _missionList(incomingMissions, isOutgoing: false),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _missionList(List<Map<String, dynamic>> list, {required bool isOutgoing}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.slate100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOutgoing ? Icons.outbox_rounded : Icons.inbox_rounded,
                  size: 40,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isOutgoing ? "No Outgoing Missions" : "No Incoming Missions",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isOutgoing
                    ? "Dispatch your first emergency transport mission."
                    : "No incoming emergency transfers currently en route.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadMissions,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final mission = list[index];
          final missionId = mission['id']?.toString().substring(0, 8).toUpperCase() ?? "ID";
          final status = mission['status'] ?? "Pending";
          final payload = mission['patient_name'] ?? "Emergency Transfer";
          final pickup = mission['pickup_location'] ?? "Facility";
          final destination = mission['destination'] ?? "Destination Facility";
          final hasDriver = mission['driver_id'] != null;

          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MissionDetailsScreen(mission: mission),
                ),
              );
              loadMissions();
              loadDrivers();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.card(radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.emergency_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "MIS-$missionId",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.forStatusBg(status),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.forStatus(status).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.forStatus(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Payload Title
                  Text(
                    payload,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Route Flow
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickup,
                          style: const TextStyle(fontSize: 13, color: AppColors.slate600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.slate400),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.emerald),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Driver Assignment status / CTA
                  if (!hasDriver && isOutgoing) ...[
                    const Divider(height: 20, color: AppColors.slate100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Driver: Unassigned",
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          onPressed: () => _showAssignDriverDialog(mission['id']),
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                          label: const Text(
                            "Assign Driver",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ] else if (!isOutgoing && status.toLowerCase() != 'completed') ...[
                    const Divider(height: 20, color: AppColors.slate100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.airport_shuttle_rounded, size: 15, color: AppColors.slate500),
                            const SizedBox(width: 6),
                            Text(
                              status == 'In Transit' ? "En Route to You" : "Transfer Scheduled",
                              style: const TextStyle(
                                color: AppColors.slate600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _confirmAndCompleteMission(mission),
                          icon: const Icon(Icons.check_circle_rounded, size: 15),
                          label: const Text(
                            "Confirm Received",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Driver Dispatched",
                          style: TextStyle(
                            color: AppColors.emeraldDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAssignDriverDialog(String missionId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Assign Transport Driver",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: availableDrivers.isEmpty
              ? const Text("No drivers currently marked as available in your fleet.")
              : DropdownButtonFormField<String>(
                  decoration: AppDecorations.input(labelText: "Select Driver"),
                  items: availableDrivers.map((driver) {
                    return DropdownMenuItem<String>(
                      value: driver['id'],
                      child: Text("${driver['name']} (${driver['driver_code'] ?? 'Driver'})"),
                    );
                  }).toList(),
                  onChanged: (val) => selectedDriverId = val,
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            if (availableDrivers.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  assignDriver(missionId);
                },
                child: const Text("Confirm Assignment"),
              ),
          ],
        );
      },
    );
  }
}