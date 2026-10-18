import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class ManageAmbulancesScreen extends StatefulWidget {
  const ManageAmbulancesScreen({super.key});

  @override
  State<ManageAmbulancesScreen> createState() => _ManageAmbulancesScreenState();
}

class _ManageAmbulancesScreenState extends State<ManageAmbulancesScreen> {
  List<Map<String, dynamic>> ambulances = [];
  List<Map<String, dynamic>> filteredAmbulances = [];
  final vehicleNameController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAmbulances();
  }

  Future<void> fetchAmbulances() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Fetch all hospital ambulances
      final data = await Supabase.instance.client
          .from('ambulances')
          .select()
          .eq('hospital_id', userId)
          .order('ambulance_sequence', ascending: true);

      final ambulanceList = List<Map<String, dynamic>>.from(data);

      if (mounted) {
        setState(() {
          ambulances = ambulanceList;
          filteredAmbulances = ambulances;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching ambulances: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterAmbulances(String query) {
    if (query.isEmpty) {
      setState(() => filteredAmbulances = ambulances);
      return;
    }

    final lower = query.toLowerCase();
    setState(() {
      filteredAmbulances = ambulances.where((amb) {
        final name = amb['vehicle_name']?.toString().toLowerCase() ?? '';
        final number = amb['vehicle_number']?.toString().toLowerCase() ?? '';
        final code = amb['ambulance_code']?.toString().toLowerCase() ?? '';
        return name.contains(lower) || number.contains(lower) || code.contains(lower);
      }).toList();
    });
  }

  Future<void> toggleAmbulanceAvailability(String id, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      await Supabase.instance.client
          .from('ambulances')
          .update({'is_available': newStatus})
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newStatus ? AppColors.emerald : AppColors.warning,
          behavior: SnackBarBehavior.floating,
          content: Text(
            newStatus ? "Ambulance marked as Available" : "Ambulance marked as Unavailable",
          ),
        ),
      );

      await fetchAmbulances();
    } catch (e) {
      debugPrint("Error toggling ambulance: $e");
    }
  }

  Future<void> deleteAmbulance(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Decommission Ambulance?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Are you sure you want to remove this vehicle from your emergency fleet?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Decommission"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('ambulances').delete().eq('id', id);
      await fetchAmbulances();
    }
  }

  void _showRegisterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            "Register New Ambulance",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                TextField(
                  controller: vehicleNameController,
                  decoration: AppDecorations.input(
                    labelText: "Vehicle Model / Unit Name",
                    hintText: "e.g. Force Traveler ICU 01",
                    prefixIcon: const Icon(Icons.airport_shuttle_rounded, color: AppColors.slate400, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: vehicleNumberController,
                  decoration: AppDecorations.input(
                    labelText: "Vehicle Registration Number",
                    hintText: "e.g. MH 12 GC 1008",
                    prefixIcon: const Icon(Icons.pin_rounded, color: AppColors.slate400, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                vehicleNameController.clear();
                vehicleNumberController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (vehicleNameController.text.trim().isEmpty ||
                    vehicleNumberController.text.trim().isEmpty) {
                  return;
                }

                try {
                  final userId = Supabase.instance.client.auth.currentUser!.id;
                  final hospital = await Supabase.instance.client
                      .from('users')
                      .select('id, hospital_code')
                      .eq('id', userId)
                      .single();

                  final hospitalId = hospital['id'];
                  final hospitalCode = hospital['hospital_code'] ?? "FAC";

                  final lastAmbulance = await Supabase.instance.client
                      .from('ambulances')
                      .select('ambulance_sequence')
                      .eq('hospital_id', hospitalId)
                      .order('ambulance_sequence', ascending: false)
                      .limit(1);

                  int nextSequence = 1;
                  if (lastAmbulance.isNotEmpty && lastAmbulance.first['ambulance_sequence'] != null) {
                    nextSequence = (lastAmbulance.first['ambulance_sequence'] as int) + 1;
                  }

                  final ambulanceCode = "$hospitalCode-A${nextSequence.toString().padLeft(3, '0')}";

                  await Supabase.instance.client.from('ambulances').insert({
                    'hospital_id': hospitalId,
                    'vehicle_name': vehicleNameController.text.trim(),
                    'vehicle_number': vehicleNumberController.text.trim(),
                    'ambulance_code': ambulanceCode,
                    'ambulance_sequence': nextSequence,
                    'is_available': true,
                  });

                  vehicleNameController.clear();
                  vehicleNumberController.clear();

                  if (!mounted) return;
                  Navigator.pop(context);
                  await fetchAmbulances();
                } catch (e) {
                  debugPrint("Error registering ambulance: $e");
                }
              },
              child: const Text("Register Unit"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    vehicleNameController.dispose();
    vehicleNumberController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.slate900,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.slate200, height: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ambulance Fleet",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  "Hospital Emergency Vehicles & Status",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh & Sync Fleet",
            icon: const Icon(Icons.sync_rounded, color: AppColors.slate700),
            onPressed: fetchAmbulances,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        onPressed: _showRegisterDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          "Add Ambulance",
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: _filterAmbulances,
                    decoration: AppDecorations.input(
                      labelText: "Search Fleet",
                      hintText: "Search by vehicle name, plate or code...",
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate400),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                searchController.clear();
                                _filterAmbulances("");
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Fleet Inventory (${filteredAmbulances.length})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        "${filteredAmbulances.where((a) => a['is_available'] == true).length} Available",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // List of Ambulances
                  Expanded(
                    child: filteredAmbulances.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.airport_shuttle_outlined, size: 48, color: AppColors.slate400),
                                SizedBox(height: 12),
                                Text(
                                  "No ambulances registered yet",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate700),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchAmbulances,
                            color: AppColors.primary,
                            child: ListView.separated(
                              itemCount: filteredAmbulances.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final ambulance = filteredAmbulances[index];
                                final isAvailable = ambulance['is_available'] == true;
                                final code = ambulance['ambulance_code'] ?? "A-00";

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: AppDecorations.card(radius: 18),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isAvailable ? AppColors.emeraldLight : AppColors.warningLight,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.airport_shuttle_rounded,
                                          color: isAvailable ? AppColors.emeraldDark : AppColors.warning,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  ambulance['vehicle_name'] ?? "Ambulance Unit",
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.slate900,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.slate100,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.slate700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Plate: ${ambulance['vehicle_number'] ?? 'N/A'}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.slate500,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Interactive Toggle Button
                                      InkWell(
                                        onTap: () => toggleAmbulanceAvailability(ambulance['id'], isAvailable),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isAvailable ? AppColors.emeraldLight : AppColors.warningLight,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: (isAvailable ? AppColors.emerald : AppColors.warning).withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isAvailable ? Icons.check_circle_rounded : Icons.replay_rounded,
                                                size: 14,
                                                color: isAvailable ? AppColors.emeraldDark : AppColors.warning,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isAvailable ? "Available" : "Free Up Unit",
                                                style: TextStyle(
                                                  color: isAvailable ? AppColors.emeraldDark : AppColors.warning,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate400, size: 20),
                                        onPressed: () => deleteAmbulance(ambulance['id']),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}