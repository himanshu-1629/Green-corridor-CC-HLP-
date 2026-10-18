import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  String? selectedMissionType = "Organ Transport";
  String? hospitalName;
  double? hospitalLat;
  double? hospitalLng;
  double? selectedLat;
  double? selectedLng;
  double? routeDistance;
  double? routeDuration;

  final List<Map<String, dynamic>> missionTypeOptions = [
    {"type": "Organ Transport", "icon": Icons.favorite_rounded},
    {"type": "Patient Transfer", "icon": Icons.personal_injury_rounded},
    {"type": "Blood Transport", "icon": Icons.bloodtype_rounded},
    {"type": "Body Transfer", "icon": Icons.airline_seat_flat_rounded},
    {"type": "Medical Equipment", "icon": Icons.medical_services_rounded},
  ];

  final List<String> organs = ["Heart", "Liver", "Kidney", "Lungs", "Pancreas"];
  GoogleMapController? mapController;
  String? selectedOrgan;
  String? selectedDriverId;
  List<Map<String, dynamic>> ambulances = [];
  String? selectedAmbulanceId;
  Set<Marker> markers = {};
  List<LatLng> routePoints = [];
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> hospitals = [];

  String? selectedHospitalId;
  final destinationController = TextEditingController();
  final timeLimitController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadAmbulances();
    loadDrivers();
  }

  Future<void> loadAmbulances() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final currentHospital = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', currentUser.id)
        .single();

    setState(() {
      hospitalLat = (currentHospital['latitude'] as num?)?.toDouble();
      hospitalLng = (currentHospital['longitude'] as num?)?.toDouble();
      hospitalName = currentHospital['name'];
    });

    await loadHospitals();

    if (hospitalLat != null && hospitalLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(hospitalLat!, hospitalLng!),
              zoom: 16,
            ),
          ),
        );
      });
    }

    final allAmbulanceData = await Supabase.instance.client
        .from('ambulances')
        .select()
        .eq('hospital_id', currentUser.id);

    final List<Map<String, dynamic>> ambulanceList =
        List<Map<String, dynamic>>.from(allAmbulanceData);

    final availableAmbs =
        ambulanceList.where((a) => a['is_available'] == true).toList();

    if (mounted) {
      setState(() {
        ambulances = availableAmbs;
      });
    }
  }

  Future<void> getRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car'
          '?start=$startLng,$startLat'
          '&end=$endLng,$endLat',
        ),
        headers: {
          'Authorization':
              'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImEwZjhiYmQwM2U3YzQxNWY5ZTg5ZDIzZDRiMjAzYWI1IiwiaCI6Im11cm11cjY0In0=',
        },
      );

      final data = jsonDecode(response.body);
      routeDistance =
          data['features'][0]['properties']['segments'][0]['distance'];
      routeDuration =
          data['features'][0]['properties']['segments'][0]['duration'];

      final coords = data['features'][0]['geometry']['coordinates'];

      routePoints = coords.map<LatLng>((point) {
        return LatLng(point[1], point[0]);
      }).toList();

      setState(() {});
    } catch (e) {
      debugPrint("Route calculation error: $e");
    }
  }

  Future<void> createMission() async {
    if (selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primary,
          content: Text("Please select a destination hospital"),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final user = Supabase.instance.client.auth.currentUser;
      if (selectedDriverId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'is_available': false})
            .eq('id', selectedDriverId!);
      }
      if (selectedAmbulanceId != null) {
        await Supabase.instance.client
            .from('ambulances')
            .update({'is_available': false})
            .eq('id', selectedAmbulanceId!);
      }

      await Supabase.instance.client.from('missions').insert({
        'patient_name': selectedOrgan ?? selectedMissionType ?? 'Mission',
        'pickup_location': hospitalName,
        'destination': destinationController.text,
        'destination_hospital_id': selectedHospitalId,
        'ambulance_id': selectedAmbulanceId,
        'priority': timeLimitController.text.trim().isEmpty
            ? "Urgent"
            : timeLimitController.text.trim(),
        'hospital_id': user?.id,
        'driver_id': selectedDriverId,
        'status': selectedDriverId == null ? 'Pending' : 'Assigned',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          content: Text("Emergency Mission Dispatched Successfully!"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadDrivers() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final allDriverData = await Supabase.instance.client
        .from('users')
        .select()
        .eq('role', 'Driver')
        .eq('hospital_id', currentUser.id);

    final List<Map<String, dynamic>> driverList =
        List<Map<String, dynamic>>.from(allDriverData);

    final availableDrivers =
        driverList.where((d) => d['is_available'] == true).toList();

    if (mounted) {
      setState(() {
        drivers = availableDrivers;
      });
    }
  }

  Future<void> loadHospitals() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('role', 'Hospital Admin')
        .neq('id', currentUser.id);

    final hospitalList = List<Map<String, dynamic>>.from(data);
    Set<Marker> hospitalMarkers = {};

    for (final hospital in hospitalList) {
      if (hospital['latitude'] == null || hospital['longitude'] == null) {
        continue;
      }

      hospitalMarkers.add(
        Marker(
          markerId: MarkerId(hospital['id']),
          position: LatLng(
            (hospital['latitude'] as num).toDouble(),
            (hospital['longitude'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(
            title: hospital['name'],
            snippet: "Code: ${hospital['hospital_code']}",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selectedHospitalId == hospital['id']
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          onTap: () async {
            setState(() {
              selectedHospitalId = hospital['id'];
              destinationController.text =
                  "${hospital['name']} (${hospital['hospital_code']})";
              selectedLat = (hospital['latitude'] as num).toDouble();
              selectedLng = (hospital['longitude'] as num).toDouble();
            });

            if (hospitalLat != null && hospitalLng != null) {
              await getRoute(
                hospitalLat!,
                hospitalLng!,
                selectedLat!,
                selectedLng!,
              );
            }

            await loadHospitals();
          },
        ),
      );
    }

    if (hospitalLat != null && hospitalLng != null) {
      hospitalMarkers.add(
        Marker(
          markerId: const MarkerId('current_hospital'),
          position: LatLng(hospitalLat!, hospitalLng!),
          infoWindow: InfoWindow(
            title: hospitalName ?? "Origin Hospital",
            snippet: "Origin / Pickup Point",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    setState(() {
      hospitals = hospitalList;
      markers = hospitalMarkers;
    });
  }

  @override
  void dispose() {
    destinationController.dispose();
    timeLimitController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Emergency Mission"),
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Mission Type
            _sectionHeader("1. Mission Category", Icons.category_rounded),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: missionTypeOptions.map((opt) {
                final isSelected = selectedMissionType == opt["type"];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        opt["icon"] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.slate700,
                      ),
                      const SizedBox(width: 6),
                      Text(opt["type"] as String),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.slate800,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.slate200,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      selectedMissionType = opt["type"] as String;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Section 1.1: Organ Type (if Organ Transport)
            if (selectedMissionType == "Organ Transport") ...[
              _sectionHeader("Organ for Transit", Icons.favorite_rounded),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: organs.map((organ) {
                  final isSelected = selectedOrgan == organ;
                  return ChoiceChip(
                    label: Text(organ),
                    selected: isSelected,
                    selectedColor: AppColors.emerald,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.slate800,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.emerald : AppColors.slate200,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedOrgan = selected ? organ : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Section 2: Destination Hospital
            _sectionHeader("2. Destination Facility", Icons.local_hospital_rounded),
            const SizedBox(height: 12),
            RawAutocomplete<Map<String, dynamic>>(
              textEditingController: destinationController,
              focusNode: FocusNode(),
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) {
                  return hospitals;
                }
                return hospitals.where((hospital) {
                  final query = value.text.toLowerCase();
                  return hospital['name'].toString().toLowerCase().contains(query) ||
                      (hospital['hospital_code'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(query);
                });
              },
              displayStringForOption: (hospital) =>
                  "${hospital['name']} (${hospital['hospital_code']})",
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: AppDecorations.input(
                    labelText: "Destination Hospital",
                    hintText: "Search hospital name or code...",
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.slate400,
                    ),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 380,
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: AppDecorations.card(radius: 16),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final hospital = options.elementAt(index);
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              hospital['name'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "Code: ${hospital['hospital_code'] ?? 'N/A'}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => onSelected(hospital),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (hospital) async {
                destinationController.text =
                    "${hospital['name']} (${hospital['hospital_code']})";
                setState(() {
                  selectedHospitalId = hospital['id'];
                  selectedLat = (hospital['latitude'] as num).toDouble();
                  selectedLng = (hospital['longitude'] as num).toDouble();
                });

                if (hospitalLat != null && hospitalLng != null) {
                  await getRoute(
                    hospitalLat!,
                    hospitalLng!,
                    selectedLat!,
                    selectedLng!,
                  );
                }

                await loadHospitals();

                mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(selectedLat!, selectedLng!),
                      zoom: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Map Viewport with HUD Overlay
            Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.slate200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.slate900.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (hospitalLat != null && hospitalLng != null)
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(hospitalLat!, hospitalLng!),
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => mapController = controller,
                      markers: markers,
                      polylines: {
                        if (routePoints.isNotEmpty)
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: routePoints,
                            color: AppColors.info,
                            width: 5,
                          ),
                      },
                    )
                  else
                    const Center(child: CircularProgressIndicator()),

                  // Floating Route HUD
                  if (routeDistance != null && routeDuration != null)
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate900.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.straighten_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${(routeDistance! / 1000).toStringAsFixed(1)} km",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: AppColors.emerald,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${(routeDuration! / 60).toStringAsFixed(0)} min",
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Fleet & Driver Assignment
            _sectionHeader("3. Vehicle & Personnel", Icons.minor_crash_rounded),
            const SizedBox(height: 12),

            // Ambulance Select
            DropdownButtonFormField<String>(
              initialValue: selectedAmbulanceId,
              decoration: AppDecorations.input(
                labelText: "Assign Ambulance",
                prefixIcon: const Icon(
                  Icons.airport_shuttle_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
              ),
              items: ambulances.map((ambulance) {
                return DropdownMenuItem<String>(
                  value: ambulance['id'],
                  child: Text(
                    "${ambulance['vehicle_name']} (${ambulance['vehicle_number'] ?? 'Emergency'})",
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedAmbulanceId = value),
            ),
            const SizedBox(height: 14),

            // Driver Select
            DropdownButtonFormField<String>(
              initialValue: selectedDriverId,
              decoration: AppDecorations.input(
                labelText: "Assign Driver",
                prefixIcon: const Icon(
                  Icons.person_pin_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
              ),
              items: drivers.map((driver) {
                return DropdownMenuItem<String>(
                  value: driver['id'],
                  child: Text(
                    "${driver['name']} (${driver['driver_code'] ?? 'Driver'})",
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedDriverId = value),
            ),
            const SizedBox(height: 14),

            // Priority / Time Limit
            TextField(
              controller: timeLimitController,
              decoration: AppDecorations.input(
                labelText: "Mission Urgency / ETA Goal",
                hintText: "e.g. Critical - Under 30 Mins",
                prefixIcon: const Icon(
                  Icons.alarm_on_rounded,
                  color: AppColors.slate400,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Dispatch CTA
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppGradients.emergency,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isLoading ? null : createMission,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "DISPATCH GREEN CORRIDOR MISSION",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
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

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
