import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MissionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? mission;

  const MissionDetailsScreen({super.key, this.mission});

  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  Map<String, dynamic>? currentMission;
  Map<String, dynamic>? sourceHospital;
  Map<String, dynamic>? destinationHospital;
  Map<String, dynamic>? ambulanceData;
  Map<String, dynamic>? driverData;

  GoogleMapController? mapController;
  Timer? trackingTimer;

  List<LatLng> routePoints = [];
  double? distance; // in meters
  double? duration; // in seconds

  double? ambulanceLat;
  double? ambulanceLng;
  double? sourceLat;
  double? sourceLng;
  double? destLat;
  double? destLng;

  DateTime? lastPingTime;
  bool isLoading = true;
  bool isCalculatingRoute = false;
  bool isCompleting = false;
  int refreshTick = 0;

  @override
  void initState() {
    super.initState();
    currentMission = widget.mission;
    _initMissionTelemetry();
  }

  @override
  void dispose() {
    trackingTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initMissionTelemetry() async {
    await _loadAllMissionData(refreshRoute: true);
    _startLiveTrackingLoop();
  }

  Future<void> _loadAllMissionData({bool refreshRoute = true}) async {
    if (widget.mission == null && currentMission == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final missionId = (currentMission ?? widget.mission)!['id'];

    try {
      // 1. Fresh Mission record
      final freshMission = await Supabase.instance.client
          .from('missions')
          .select()
          .eq('id', missionId)
          .single();

      currentMission = freshMission;

      // 2. Source Hospital (Origin)
      if (freshMission['hospital_id'] != null) {
        try {
          final src = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', freshMission['hospital_id'])
              .single();
          sourceHospital = src;
          sourceLat = (src['latitude'] as num?)?.toDouble() ?? 28.5700;
          sourceLng = (src['longitude'] as num?)?.toDouble() ?? 77.2078;
        } catch (e) {
          debugPrint("Source hospital query error: $e");
        }
      }

      // 3. Destination Hospital
      if (freshMission['destination_hospital_id'] != null) {
        try {
          final dst = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', freshMission['destination_hospital_id'])
              .single();
          destinationHospital = dst;
          destLat = (dst['latitude'] as num?)?.toDouble() ?? 28.5672;
          destLng = (dst['longitude'] as num?)?.toDouble() ?? 77.2100;
        } catch (e) {
          debugPrint("Destination hospital query error: $e");
        }
      }

      // 4. Ambulance & Live GPS Coordinates
      final ambId = freshMission['ambulance_id'];
      if (ambId != null) {
        try {
          final amb = await Supabase.instance.client
              .from('ambulances')
              .select()
              .eq('id', ambId)
              .single();
          ambulanceData = amb;
          final lat = (amb['latitude'] as num?)?.toDouble();
          final lng = (amb['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            ambulanceLat = lat;
            ambulanceLng = lng;
          }
          if (amb['last_updated'] != null) {
            lastPingTime = DateTime.tryParse(amb['last_updated'].toString());
          }
        } catch (e) {
          debugPrint("Ambulance data query error: $e");
        }
      }

      // 5. Driver Details
      final drvId = freshMission['driver_id'];
      if (drvId != null) {
        try {
          final drv = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', drvId)
              .single();
          driverData = drv;
          // Fallback coordinates from driver record if ambulance record has no lat/lng yet
          if (ambulanceLat == null || ambulanceLng == null) {
            final dLat = (drv['latitude'] as num?)?.toDouble();
            final dLng = (drv['longitude'] as num?)?.toDouble();
            if (dLat != null && dLng != null) {
              ambulanceLat = dLat;
              ambulanceLng = dLng;
            }
          }
        } catch (e) {
          debugPrint("Driver data query error: $e");
        }
      }

      if (refreshRoute) {
        await _calculateRoute();
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Init mission telemetry error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _calculateRoute({double? startLat, double? startLng}) async {
    final status = currentMission?['status'] ?? 'In Transit';
    final isTransit = status == 'In Transit';

    // When In Transit, calculate route from the live moving ambulance to destination hospital!
    // When Assigned, preview route from origin hospital to destination hospital.
    final sLat = startLat ?? (isTransit ? ambulanceLat : null) ?? sourceLat ?? ambulanceLat;
    final sLng = startLng ?? (isTransit ? ambulanceLng : null) ?? sourceLng ?? ambulanceLng;
    final dLat = destLat;
    final dLng = destLng;

    if (sLat == null || sLng == null || dLat == null || dLng == null) return;

    try {
      isCalculatingRoute = true;
      final response = await http.get(
        Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car'
          '?start=$sLng,$sLat'
          '&end=$dLng,$dLat',
        ),
        headers: {
          'Authorization':
              'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImEwZjhiYmQwM2U3YzQxNWY5ZTg5ZDIzZDRiMjAzYWI1IiwiaCI6Im11cm11cjY0In0=',
        },
      );

      final data = jsonDecode(response.body);
      if (data['features'] != null && (data['features'] as List).isNotEmpty) {
        final seg = data['features'][0]['properties']['segments'][0];
        distance = (seg['distance'] as num?)?.toDouble();
        duration = (seg['duration'] as num?)?.toDouble();

        final coords = data['features'][0]['geometry']['coordinates'];
        routePoints = coords.map<LatLng>((point) {
          return LatLng(point[1], point[0]);
        }).toList();

        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Route calculation error: $e");
    } finally {
      isCalculatingRoute = false;
    }
  }

  void _startLiveTrackingLoop() {
    trackingTimer?.cancel();
    refreshTick = 0;

    // Periodic live telemetry polling every 3.5 seconds
    trackingTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) async {
      if (!mounted) return;
      final status = currentMission?['status'] ?? '';
      if (status.toLowerCase() == 'completed') {
        timer.cancel();
        return;
      }

      refreshTick++;

      try {
        final missionId = currentMission?['id'];
        if (missionId == null) return;

        // Check if mission status transitioned (e.g. driver clicked "Start Mission" -> 'In Transit')
        final missionRow = await Supabase.instance.client
            .from('missions')
            .select()
            .eq('id', missionId)
            .single();

        final previousStatus = currentMission?['status'];
        final newStatus = missionRow['status'];
        currentMission = missionRow;

        // Query latest ambulance GPS telemetry
        final ambId = missionRow['ambulance_id'];
        if (ambId != null) {
          final amb = await Supabase.instance.client
              .from('ambulances')
              .select()
              .eq('id', ambId)
              .single();

          ambulanceData = amb;
          final newLat = (amb['latitude'] as num?)?.toDouble();
          final newLng = (amb['longitude'] as num?)?.toDouble();

          bool posMoved = false;
          if (newLat != null && newLng != null) {
            if (ambulanceLat == null ||
                (ambulanceLat! - newLat).abs() > 0.00008 ||
                (ambulanceLng! - newLng).abs() > 0.00008) {
              posMoved = true;
            }
            ambulanceLat = newLat;
            ambulanceLng = newLng;
          }

          if (amb['last_updated'] != null) {
            lastPingTime = DateTime.tryParse(amb['last_updated'].toString()) ?? DateTime.now();
          }

          // Recalculate route & ETA if driver started mission, or position moved, or every 5th tick (~17s)
          final justStarted = previousStatus != 'In Transit' && newStatus == 'In Transit';
          if (justStarted || posMoved || refreshTick % 5 == 0) {
            await _calculateRoute(startLat: ambulanceLat, startLng: ambulanceLng);
            if (justStarted) {
              _fitOverviewBounds();
            }
          }

          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint("Live tracking sync loop error: $e");
      }
    });
  }

  void _centerOnAmbulance() {
    if (mapController == null) return;
    if (ambulanceLat != null && ambulanceLng != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(ambulanceLat!, ambulanceLng!),
            zoom: 16.5,
            tilt: 30,
          ),
        ),
      );
    } else if (destLat != null && destLng != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(destLat!, destLng!),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _fitOverviewBounds() {
    if (mapController == null) return;
    final pts = <LatLng>[];
    if (ambulanceLat != null && ambulanceLng != null) {
      pts.add(LatLng(ambulanceLat!, ambulanceLng!));
    } else if (sourceLat != null && sourceLng != null) {
      pts.add(LatLng(sourceLat!, sourceLng!));
    }
    if (destLat != null && destLng != null) {
      pts.add(LatLng(destLat!, destLng!));
    }

    if (pts.length < 2) {
      if (pts.isNotEmpty) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pts.first, zoom: 15.0),
          ),
        );
      }
      return;
    }

    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    if ((maxLat - minLat).abs() < 0.005) {
      minLat -= 0.005;
      maxLat += 0.005;
    }
    if ((maxLng - minLng).abs() < 0.005) {
      minLng -= 0.005;
      maxLng += 0.005;
    }

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        55.0,
      ),
    );
  }

  String _formatDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins < 1) return "< 1 min";
    if (mins < 60) return "$mins min";
    final hours = mins ~/ 60;
    final remMins = mins % 60;
    if (remMins == 0) return "${hours}h";
    return "${hours}h ${remMins}m";
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.round()} m";
    }
    return "${(meters / 1000).toStringAsFixed(1)} km";
  }

  String _getLastPingLabel() {
    if (lastPingTime == null) return "Connected";
    final diff = DateTime.now().difference(lastPingTime!).inSeconds;
    if (diff < 5) return "Just now";
    if (diff < 60) return "${diff}s ago";
    return "${(diff / 60).round()}m ago";
  }


  Future<void> _completeMission() async {
    if (currentMission == null && widget.mission == null) return;
    final missionToComplete = currentMission ?? widget.mission!;


    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isIncoming = missionToComplete['destination_hospital_id'] == currentUserId;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isIncoming ? "Confirm Transfer Receipt?" : "Confirm Arrival & Complete?",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          isIncoming
              ? "Confirm that this emergency medical transfer was successfully received at your facility. This will mark the mission Completed and free up the ambulance and driver."
              : "This will mark the mission as Completed and immediately release the assigned ambulance and driver back to Available status.",
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
            child: const Text("Complete Mission"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isCompleting = true);

    try {
      final missionId = missionToComplete['id'];

      // 1. Complete mission record
      await Supabase.instance.client
          .from('missions')
          .update({'status': 'Completed'})
          .eq('id', missionId);

      // Note: Ambulance and Driver remain unavailable until the driver
      // performs the return journey and marks Available at their origin base.

      trackingTimer?.cancel();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          content: Text(
            isIncoming
                ? "Transfer Confirmed! Mission Completed. Driver notified to return to base."
                : "Mission Completed! Driver will return unit to base.",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error completing mission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text("Error: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionId = currentMission != null
        ? "MIS-${currentMission!['id'].toString().substring(0, 6).toUpperCase()}"
        : "MIS-2001";
    final status = currentMission?['status'] ?? "In Transit";
    final type = currentMission?['patient_name'] ?? "Kidney Transport";
    final pickup = currentMission?['pickup_location'] ?? "Origin Facility";
    final destination = currentMission?['destination'] ?? "Destination Facility";
    final priority = currentMission?['priority'] ?? "Urgent";
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isIncoming = currentMission?['destination_hospital_id'] == currentUserId;
    final isCompleted = status.toLowerCase() == 'completed';
    final isTransit = status == 'In Transit';
    final isAssigned = status == 'Assigned';

    // Center coordinate for map initialization
    final initialMapCenter = LatLng(
      ambulanceLat ?? destLat ?? 28.5672,
      ambulanceLng ?? destLng ?? 77.2100,
    );

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
                color: isTransit ? AppColors.emerald : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isTransit ? Icons.radar_rounded : Icons.local_hospital_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncoming ? "Incoming Transfer Corridor" : "Mission Dispatch Details",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  "Real-Time Telemetry & Route Preemption",
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
            tooltip: "Refresh Telemetry",
            icon: const Icon(Icons.refresh_rounded, color: AppColors.slate700),
            onPressed: () => _loadAllMissionData(refreshRoute: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Proximity Alert Banner (<500m)
                  if (isTransit && distance != null && distance! <= 500)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "🚨 AMBULANCE WITHIN 500M • PREPARE RECEIVING BAY",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "Vehicle ${ambulanceData?['vehicle_number'] ?? ambulanceData?['ambulance_code'] ?? ambulanceData?['plate_number'] ?? ''} is approaching ${destinationHospital?['name'] ?? destination}. Organ handover imminent (${distance!.toStringAsFixed(0)} m remaining).",
                                  style: const TextStyle(
                                    color: AppColors.slate700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Top Mission Briefing Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: AppDecorations.cardElevated(radius: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              missionId,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.forStatusBg(status),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.forStatus(status).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.forStatus(status),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mission Payload Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Priority: $priority • Destination: $destination",
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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


                  // LIVE RADAR & GPS TRACKING MAP (Destination Cockpit)
                  _sectionTitle(
                    isIncoming
                        ? "Live Incoming Radar & Telemetry"
                        : "Corridor Real-Time Tracking",
                  ),
                  Container(
                    height: 360,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.slate200),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: initialMapCenter,
                            zoom: 14.5,
                          ),
                          onMapCreated: (controller) {
                            mapController = controller;
                            _fitOverviewBounds();
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          markers: {
                            // 1. Destination Hospital Marker (Red)
                            if (destLat != null && destLng != null)
                              Marker(
                                markerId: const MarkerId('destination_hospital'),
                                position: LatLng(destLat!, destLng!),
                                infoWindow: InfoWindow(
                                  title: destinationHospital?['name'] ?? destination,
                                  snippet: "Destination Receiving Hospital",
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed,
                                ),
                              ),

                            // 2. Origin Hospital Marker (Azure)
                            if (sourceLat != null && sourceLng != null)
                              Marker(
                                markerId: const MarkerId('source_hospital'),
                                position: LatLng(sourceLat!, sourceLng!),
                                infoWindow: InfoWindow(
                                  title: sourceHospital?['name'] ?? pickup,
                                  snippet: "Origin Pickup Facility",
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueAzure,
                                ),
                              ),

                            // 3. Live Ambulance Marker (Orange)
                            if (ambulanceLat != null && ambulanceLng != null)
                              Marker(
                                markerId: const MarkerId('ambulance_live'),
                                position: LatLng(ambulanceLat!, ambulanceLng!),
                                infoWindow: InfoWindow(
                                  title: "Ambulance ${ambulanceData?['vehicle_number'] ?? ambulanceData?['ambulance_code'] ?? ambulanceData?['plate_number'] ?? ''} (LIVE GPS)",
                                  snippet: isTransit
                                      ? "In Transit to destination"
                                      : "Standing by at facility",
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueOrange,
                                ),
                              ),
                          },
                          polylines: {
                            // Electric Blue corridor route (#2563EB)
                            if (routePoints.isNotEmpty)
                              Polyline(
                                polylineId: const PolylineId('corridor_route'),
                                points: routePoints,
                                color: AppColors.info, // Vibrant Blue (#2563EB)
                                width: 5,
                              ),
                          },
                        ),

                        // Top-Left: Live Satellite Status HUD
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.slate900.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTransit
                                    ? AppColors.emerald.withValues(alpha: 0.5)
                                    : AppColors.amber.withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDark.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: isTransit
                                        ? AppColors.emerald
                                        : (isAssigned ? AppColors.amber : AppColors.slate400),
                                    shape: BoxShape.circle,
                                    boxShadow: isTransit
                                        ? [
                                            BoxShadow(
                                              color: AppColors.emerald.withValues(alpha: 0.8),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isTransit
                                          ? "LIVE GPS RADAR"
                                          : (isAssigned ? "AWAITING DRIVER" : "TRANSFER ENDED"),
                                      style: TextStyle(
                                        color: isTransit
                                            ? AppColors.emerald
                                            : (isAssigned ? AppColors.amber : Colors.white70),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      "Ping: ${_getLastPingLabel()}",
                                      style: const TextStyle(
                                        color: AppColors.slate400,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top-Right: Live ETA & Remaining Distance Cockpit
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.slate900.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.info.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDark.withValues(alpha: 0.25),
                                  blurRadius: 10,
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
                                    color: AppColors.info.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.timer_rounded,
                                    color: AppColors.info,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      duration != null
                                          ? "ETA: ${_formatDuration(duration!)}"
                                          : (isCalculatingRoute ? "Calculating..." : "ETA: Standby"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      distance != null
                                          ? "${_formatDistance(distance!)} remaining"
                                          : (isAssigned ? "Awaiting Departure" : "Corridor Ready"),
                                      style: const TextStyle(
                                        color: AppColors.slate300,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom-Right: Camera Viewport Controls
                        Positioned(
                          bottom: 14,
                          right: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Focus Ambulance
                              FloatingActionButton.small(
                                heroTag: "focus_ambulance_btn",
                                tooltip: "Track Ambulance Live",
                                backgroundColor: AppColors.slate900.withValues(alpha: 0.9),
                                foregroundColor: AppColors.emerald,
                                elevation: 4,
                                onPressed: _centerOnAmbulance,
                                child: const Icon(Icons.my_location_rounded, size: 20),
                              ),
                              const SizedBox(width: 8),
                              // Full Corridor Overview
                              FloatingActionButton.small(
                                heroTag: "fit_overview_btn",
                                tooltip: "Corridor Overview",
                                backgroundColor: AppColors.slate900.withValues(alpha: 0.9),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                onPressed: _fitOverviewBounds,
                                child: const Icon(Icons.fullscreen_rounded, size: 22),
                              ),
                            ],
                          ),
                        ),

                        // Bottom-Left: Live Driver / Vehicle Telemetry Pill
                        if (ambulanceData != null || driverData != null)
                          Positioned(
                            bottom: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.slate900.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.slate700),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.airport_shuttle_rounded,
                                    size: 14,
                                    color: AppColors.amber,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${ambulanceData?['vehicle_number'] ?? ambulanceData?['ambulance_code'] ?? ambulanceData?['plate_number'] ?? 'Ambulance'} • ${driverData?['name'] ?? 'Assigned Driver'}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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

                  // Corridor Route Timeline Card
                  _sectionTitle("Corridor Route"),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppDecorations.card(radius: 20),
                    child: Column(
                      children: [
                        _routeStop(
                          isOrigin: true,
                          title: "Origin / Pickup Point",
                          facility: pickup,
                          isLast: false,
                        ),
                        _routeStop(
                          isOrigin: false,
                          title: "Destination Facility",
                          facility: destination,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fleet & Personnel Briefing Card
                  _sectionTitle("Assigned Fleet & Personnel"),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: AppDecorations.card(radius: 20),
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.airport_shuttle_rounded,
                          label: "Ambulance Vehicle",
                          value: ambulanceData != null
                              ? "${ambulanceData!['vehicle_number'] ?? ambulanceData!['ambulance_code'] ?? ambulanceData!['plate_number'] ?? ''} (${ambulanceData!['vehicle_name'] ?? ambulanceData!['model'] ?? 'Unit'})"
                              : (currentMission?['ambulance_id'] != null ? "Unit Assigned" : "Not Assigned"),
                        ),
                        const Divider(height: 24, color: AppColors.slate100),
                        _infoRow(
                          icon: Icons.person_pin_rounded,
                          label: "Transport Driver",
                          value: driverData != null
                              ? (driverData!['name'] ?? 'Dispatched Driver')
                              : (currentMission?['driver_id'] != null ? "Driver Dispatched" : "Unassigned"),
                        ),
                        const Divider(height: 24, color: AppColors.slate100),
                        _infoRow(
                          icon: Icons.sensors_rounded,
                          label: "Live Telemetry Protocol",
                          value: isTransit
                              ? "Active GPS Stream (3.5s Sync)"
                              : (isAssigned ? "Awaiting Driver Start" : "Transit Concluded"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Complete Mission CTA (If not already completed)
                  if (!isCompleted) ...[
                    Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppGradients.emerald,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isCompleting ? null : _completeMission,
                        icon: isCompleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          isIncoming
                              ? "CONFIRM RECEIVED (DESTINATION HOSPITAL)"
                              : "CONFIRM ARRIVAL & COMPLETE MISSION",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Back Button
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.slate200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Return to Mission Center",
                        style: TextStyle(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.slate900,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _routeStop({
    required bool isOrigin,
    required String title,
    required String facility,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isOrigin ? AppColors.infoLight : AppColors.emeraldLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOrigin ? Icons.radio_button_checked_rounded : Icons.location_on_rounded,
                size: 16,
                color: isOrigin ? AppColors.info : AppColors.emerald,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.slate200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.slate500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                facility,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.slate500),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }
}