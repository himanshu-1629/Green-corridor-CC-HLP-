import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';
import '../services/citizen_alert_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  Map<String, dynamic>? mission;
  Map<String, dynamic>? sourceHospital;
  Map<String, dynamic>? destinationHospital;
  Map<String, dynamic>? ambulanceData;
  GoogleMapController? mapController;
  Timer? trackingTimer;
  StreamSubscription<Position>? positionStreamSubscription;
  List<LatLng> routePoints = [];

  double? sourceLat;
  double? sourceLng;
  double? destinationLat;
  double? destinationLng;
  double? currentDriverLat;
  double? currentDriverLng;
  double? currentSpeed = 0.0;
  double? currentHeading = 0.0;
  bool isAutoFollowing = true;
  bool isProgrammaticCameraMove = false;

  double? distance;
  double? duration;
  bool isLoading = true;

  // Return Journey & Full-screen Navigation state
  bool isReturnJourney = false;
  bool isReturnNavigating = false;
  bool isFullScreenNav = false;
  DateTime? _lastRouteFetchTime;

  bool get isNearTarget {
    if (currentDriverLat == null || currentDriverLng == null) return false;
    final tLat = isReturnJourney ? sourceLat : destinationLat;
    final tLng = isReturnJourney ? sourceLng : destinationLng;
    if (tLat == null || tLng == null) return false;

    if (distance != null && distance! <= 500) return true;

    final directMeters = Geolocator.distanceBetween(
      currentDriverLat!,
      currentDriverLng!,
      tLat,
      tLng,
    );
    if (directMeters <= 500) return true;

    return false;
  }

  Future<void> _launchExternalGoogleMaps() async {
    final targetLat = isReturnJourney ? sourceLat : destinationLat;
    final targetLng = isReturnJourney ? sourceLng : destinationLng;
    if (targetLat == null || targetLng == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$targetLat,$targetLng&travelmode=driving',
    );

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint("External Google Maps launch error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            content: Text("Could not launch Google Maps: $e"),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadMission();
  }

  @override
  void dispose() {
    trackingTimer?.cancel();
    positionStreamSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> loadMission() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Acquire fresh real-device GPS location
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
          );
          currentDriverLat = pos.latitude;
          currentDriverLng = pos.longitude;
          if (pos.speed > 0) currentSpeed = pos.speed * 3.6;
          if (pos.heading > 0) currentHeading = pos.heading;
        }
      } catch (e) {
        debugPrint("Initial GPS acquire error in loadMission: $e");
      }

      // 1. Refresh & ensure device FCM token is stored for dispatch push notifications
      try {
        await PushNotificationService.refreshAndSaveToken();
      } catch (e) {
        debugPrint("Notice: could not refresh FCM token in DriverDashboard: $e");
      }

      // 2. Fetch driver profile from users table
      final driverProfile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();

      final bool isDriverAvailable = driverProfile['is_available'] == true;

      // 2. Check for active uncompleted mission
      final activeMissionData = await Supabase.instance.client
          .from('missions')
          .select()
          .eq('driver_id', user.id)
          .neq('status', 'Completed')
          .order('created_at', ascending: false)
          .limit(1);

      if (activeMissionData.isNotEmpty) {
        // ACTIVE FORWARD MISSION
        mission = activeMissionData.first;
        isReturnJourney = false;
        isReturnNavigating = false;

        sourceHospital = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', mission!['hospital_id'])
            .single();

        destinationHospital = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', mission!['destination_hospital_id'])
            .single();

        sourceLat = (sourceHospital!['latitude'] as num).toDouble();
        sourceLng = (sourceHospital!['longitude'] as num).toDouble();
        destinationLat = (destinationHospital!['latitude'] as num).toDouble();
        destinationLng = (destinationHospital!['longitude'] as num).toDouble();

        if (mission!['ambulance_id'] != null) {
          try {
            ambulanceData = await Supabase.instance.client
                .from('ambulances')
                .select()
                .eq('id', mission!['ambulance_id'])
                .single();
          } catch (_) {}
        }

        // If In Transit, calculate route starting from the driver's real current location!
        if (mission!['status'] == 'In Transit' && currentDriverLat != null && currentDriverLng != null) {
          await getRoute(
            startLat: currentDriverLat,
            startLng: currentDriverLng,
            targetLat: destinationLat,
            targetLng: destinationLng,
          );
        } else {
          await getRoute();
        }

        if (mission!['status'] == 'In Transit') {
          await startLiveTracking();
        }
      } else if (!isDriverAvailable) {
        // NO ACTIVE UNCOMPLETED MISSION, BUT DRIVER IS STILL UNAVAILABLE (RETURN JOURNEY STATE)
        final completedData = await Supabase.instance.client
            .from('missions')
            .select()
            .eq('driver_id', user.id)
            .order('created_at', ascending: false)
            .limit(1);

        if (completedData.isNotEmpty) {
          mission = completedData.first;
          isReturnJourney = true;

          sourceHospital = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', mission!['hospital_id'])
              .single();

          destinationHospital = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', mission!['destination_hospital_id'])
              .single();

          sourceLat = (sourceHospital!['latitude'] as num).toDouble();
          sourceLng = (sourceHospital!['longitude'] as num).toDouble();
          destinationLat = (destinationHospital!['latitude'] as num).toDouble();
          destinationLng = (destinationHospital!['longitude'] as num).toDouble();

          if (mission!['ambulance_id'] != null) {
            try {
              ambulanceData = await Supabase.instance.client
                  .from('ambulances')
                  .select()
                  .eq('id', mission!['ambulance_id'])
                  .single();
            } catch (_) {}
          }

          // Calculate reverse route: Target is Home Base Hospital (sourceLat, sourceLng)
          await getRoute(
            startLat: currentDriverLat ?? destinationLat,
            startLng: currentDriverLng ?? destinationLng,
            targetLat: sourceLat,
            targetLng: sourceLng,
          );

          if (isReturnNavigating) {
            await startLiveTracking();
          }
        } else {
          mission = null;
          isReturnJourney = false;
        }
      } else {
        // DRIVER IS FULLY AVAILABLE AT BASE
        mission = null;
        isReturnJourney = false;
        isReturnNavigating = false;
        trackingTimer?.cancel();
        positionStreamSubscription?.cancel();
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading mission: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> getRoute({
    double? startLat,
    double? startLng,
    double? targetLat,
    double? targetLng,
  }) async {
    final double? defaultStartLat = isReturnJourney
        ? (currentDriverLat ?? destinationLat)
        : (currentDriverLat ?? sourceLat);
    final double? defaultStartLng = isReturnJourney
        ? (currentDriverLng ?? destinationLng)
        : (currentDriverLng ?? sourceLng);

    final double? defaultTargetLat = isReturnJourney ? sourceLat : destinationLat;
    final double? defaultTargetLng = isReturnJourney ? sourceLng : destinationLng;

    final sLat = startLat ?? defaultStartLat;
    final sLng = startLng ?? defaultStartLng;
    final dLat = targetLat ?? defaultTargetLat;
    final dLng = targetLng ?? defaultTargetLng;

    if (sLat == null || sLng == null || dLat == null || dLng == null) return;

    bool routeSuccess = false;

    // 1. Try OSRM first (real-world optimized road routing, high-density geometry)
    try {
      final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$sLng,$sLat;$dLng,$dLat?overview=full&geometries=geojson&steps=true',
      );
      final osrmResp = await http.get(osrmUrl).timeout(const Duration(seconds: 4));
      if (osrmResp.statusCode == 200) {
        final data = jsonDecode(osrmResp.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final r = data['routes'][0];
          distance = (r['distance'] as num?)?.toDouble();
          duration = (r['duration'] as num?)?.toDouble();
          final coords = r['geometry']['coordinates'] as List;
          routePoints = coords.map<LatLng>((p) {
            return LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
          }).toList();
          routeSuccess = true;
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      debugPrint("OSRM routing attempt: $e");
    }

    // 2. Fallback to OpenRouteService if OSRM is unreachable
    if (!routeSuccess) {
      try {
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
        ).timeout(const Duration(seconds: 5));

        final data = jsonDecode(response.body);
        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          distance = (data['features'][0]['properties']['segments'][0]['distance'] as num?)?.toDouble();
          duration = (data['features'][0]['properties']['segments'][0]['duration'] as num?)?.toDouble();

          final coords = data['features'][0]['geometry']['coordinates'];
          routePoints = coords.map<LatLng>((point) {
            return LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble());
          }).toList();

          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint("OpenRouteService fallback error: $e");
      }
    }
  }

  int _findClosestRouteIndex(double lat, double lng) {
    if (routePoints.isEmpty) return 0;
    int closest = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < routePoints.length; i++) {
      final d = (routePoints[i].latitude - lat).abs() + (routePoints[i].longitude - lng).abs();
      if (d < minDistance) {
        minDistance = d;
        closest = i;
      }
    }
    return closest;
  }

  void _recalculateRemainingRouteMetrics() {
    final tLat = isReturnJourney ? sourceLat : destinationLat;
    final tLng = isReturnJourney ? sourceLng : destinationLng;
    if (tLat == null || tLng == null) return;

    if (currentDriverLat != null && currentDriverLng != null) {
      if (routePoints.isNotEmpty) {
        int closestIdx = _findClosestRouteIndex(currentDriverLat!, currentDriverLng!);
        double remainingMeters = Geolocator.distanceBetween(
          currentDriverLat!,
          currentDriverLng!,
          routePoints[closestIdx].latitude,
          routePoints[closestIdx].longitude,
        );
        for (int i = closestIdx; i < routePoints.length - 1; i++) {
          remainingMeters += Geolocator.distanceBetween(
            routePoints[i].latitude,
            routePoints[i].longitude,
            routePoints[i + 1].latitude,
            routePoints[i + 1].longitude,
          );
        }
        distance = remainingMeters;
        duration = remainingMeters / 13.88; // ~50 km/h emergency speed
      } else {
        double direct = Geolocator.distanceBetween(
          currentDriverLat!,
          currentDriverLng!,
          tLat,
          tLng,
        );
        distance = direct;
        duration = direct / 13.88;
      }
    }
    if (mounted) setState(() {});
  }

  void _animateCameraToDriver({bool isTight = false}) {
    if (!isAutoFollowing || mapController == null || currentDriverLat == null || currentDriverLng == null) return;

    isProgrammaticCameraMove = true;
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(currentDriverLat!, currentDriverLng!),
          zoom: (isFullScreenNav || isTight) ? 18.2 : 17.5,
          tilt: isFullScreenNav ? 50.0 : 45.0, // 3D cockpit tilt
          bearing: (currentHeading != null && currentHeading! > 0) ? currentHeading! : 0.0,
        ),
      ),
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        isProgrammaticCameraMove = false;
      });
    });
  }

  Future<void> startLiveTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    trackingTimer?.cancel();
    positionStreamSubscription?.cancel();
    isAutoFollowing = true;

    // 1. Initial Immediate Fix & Route from real current device location
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
      _updatePositionFromDevice(initialPos);
      await getRoute(
        startLat: initialPos.latitude,
        startLng: initialPos.longitude,
        targetLat: isReturnJourney ? sourceLat : destinationLat,
        targetLng: isReturnJourney ? sourceLng : destinationLng,
      );
    } catch (e) {
      debugPrint("Initial GPS acquire error: $e");
    }

    // 2. High-precision REAL GPS position stream (distanceFilter: 1 meter)
    // Real location updates ONLY - no artificial simulation moving on its own!
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );

    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updatePositionFromDevice(position);
    });

    // 3. Periodic sync timer for Supabase database (every 3 seconds)
    trackingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) async {
        try {
          if (currentDriverLat != null &&
              currentDriverLng != null &&
              mission?['ambulance_id'] != null) {
            await Supabase.instance.client.from('ambulances').update({
              'latitude': currentDriverLat,
              'longitude': currentDriverLng,
              'last_updated': DateTime.now().toIso8601String(),
            }).eq('id', mission!['ambulance_id']);
          }

          if (currentDriverLat != null &&
              currentDriverLng != null &&
              mission?['driver_id'] != null) {
            await Supabase.instance.client.from('users').update({
              'latitude': currentDriverLat,
              'longitude': currentDriverLng,
            }).eq('id', mission!['driver_id']);
          }

          // Check if destination hospital completed the mission while driver is in transit
          if (!isReturnJourney && mission?['id'] != null) {
            final fresh = await Supabase.instance.client
                .from('missions')
                .select('status')
                .eq('id', mission!['id'])
                .single();
            if (fresh['status'] == 'Completed') {
              if (mounted) {
                setState(() {
                  isReturnJourney = true;
                });
                await getRoute(
                  startLat: currentDriverLat ?? destinationLat,
                  startLng: currentDriverLng ?? destinationLng,
                  targetLat: sourceLat,
                  targetLng: sourceLng,
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Live tracking sync error: $e");
        }
      },
    );
  }

  void _updatePositionFromDevice(Position position) {
    if (!mounted) return;

    setState(() {
      currentDriverLat = position.latitude;
      currentDriverLng = position.longitude;
      currentSpeed = position.speed > 0 ? (position.speed * 3.6) : 0.0;
      if (position.heading > 0) {
        currentHeading = position.heading;
      }
    });

    _animateCameraToDriver();
    _recalculateRemainingRouteMetrics();

    // Dynamically recalculate route from driver's real location if not already starting from here
    final now = DateTime.now();
    final canFetch = _lastRouteFetchTime == null || now.difference(_lastRouteFetchTime!).inSeconds >= 10;
    if (canFetch) {
      bool needRefresh = false;
      if (routePoints.isEmpty) {
        needRefresh = true;
      } else {
        final distFromStart = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          routePoints.first.latitude,
          routePoints.first.longitude,
        );
        if (distFromStart > 100) {
          needRefresh = true;
        }
      }

      if (needRefresh) {
        _lastRouteFetchTime = now;
        final targetLat = isReturnJourney ? sourceLat : destinationLat;
        final targetLng = isReturnJourney ? sourceLng : destinationLng;
        if (targetLat != null && targetLng != null) {
          getRoute(
            startLat: position.latitude,
            startLng: position.longitude,
            targetLat: targetLat,
            targetLng: targetLng,
          );
        }
      }
    }
  }

  Future<void> _handleMissionAction() async {
    if (mission == null) return;

    final currentStatus = (mission!['status'] ?? '').toString();
    final isReadyToStart = currentStatus != 'In Transit' && currentStatus != 'Completed';

    try {
      if (isReadyToStart) {
        final user = Supabase.instance.client.auth.currentUser;
        await Supabase.instance.client
            .from('missions')
            .update({
              'status': 'In Transit',
              if (user != null) 'driver_id': user.id,
            })
            .eq('id', mission!['id']);

        // BROADCAST EMERGENCY SIREN ALERT TO ALL CITIZENS (DRIVER IN TRANSIT)
        final ambPlate = ambulanceData?['vehicle_number'] ??
            ambulanceData?['ambulance_code'] ??
            ambulanceData?['plate_number'] ??
            'Emergency Unit';
        final destName = destinationHospital?['name'] ??
            mission?['destination'] ??
            'Hospital';
        final organName = mission?['patient_name'] ?? 'Emergency Patient';

        PushNotificationService.broadcastMissionAlert(
          missionId: mission!['id'].toString(),
          destination: destName,
          organOrPatient: organName,
          ambulancePlate: ambPlate,
          driverId: mission!['driver_id']?.toString() ?? user?.id,
          routePoints: routePoints,
          eventType: 'driver_started',
        );

        if (mounted) {
          setState(() {
            mission!['status'] = 'In Transit';
            isFullScreenNav = true; // Auto-expand full-screen navigation on mission start!
            isAutoFollowing = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.emerald,
              behavior: SnackBarBehavior.floating,
              content: Text("Emergency corridor active! Convoy started & siren broadcast sent."),
            ),
          );
        }

        await startLiveTracking();
      } else if (currentStatus == 'In Transit') {
        await _confirmAndCompleteMission();
      }
    } catch (e) {
      debugPrint("Error updating mission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            content: Text("Error updating mission: $e"),
          ),
        );
      }
    }
  }

  Future<void> _confirmAndCompleteMission() async {
    final destName = destinationHospital?['name'] ?? mission?['destination'] ?? "Destination Facility";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Confirm Handover?",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          "Confirm that you have safely arrived at $destName and completed organ delivery?\n\nThis will mark the corridor mission Completed. You can then begin your return journey back to home base.",
          style: const TextStyle(fontSize: 14, color: AppColors.slate700, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Driving", style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm & Complete Mission", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final missionId = mission!['id'];

      await Supabase.instance.client
          .from('missions')
          .update({'status': 'Completed'})
          .eq('id', missionId);

      // Close full-screen map and transition to Return Journey overview
      setState(() {
        isFullScreenNav = false;
        isReturnJourney = true;
        isReturnNavigating = false;
        currentSpeed = 0.0;
      });

      await getRoute(
        startLat: currentDriverLat ?? destinationLat,
        startLng: currentDriverLng ?? destinationLng,
        targetLat: sourceLat,
        targetLng: sourceLng,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            content: Text(
              "Transfer completed at $destName! Return navigation ready.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error completing mission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            content: Text("Error completing mission: $e"),
          ),
        );
      }
    }
  }

  Future<void> _startReturnJourney() async {
    setState(() {
      isReturnNavigating = true;
      isFullScreenNav = true; // Auto-expand full-screen navigation for return trip!
      isAutoFollowing = true;
    });

    await startLiveTracking();
    await getRoute(
      startLat: currentDriverLat ?? destinationLat,
      startLng: currentDriverLng ?? destinationLng,
      targetLat: sourceLat,
      targetLng: sourceLng,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.info,
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Return navigation active! Guiding back to ${sourceHospital?['name'] ?? 'Home Base'}.",
          ),
        ),
      );
    }
  }

  Future<void> _markReturnedToBase() async {
    final hospitalName = sourceHospital?['name'] ?? "Home Base Hospital";
    final ambulancePlate = ambulanceData?['vehicle_number'] ??
        ambulanceData?['ambulance_code'] ??
        ambulanceData?['plate_number'] ??
        "Ambulance Unit";

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_rounded, color: AppColors.info, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Confirm Return to Base?",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          "Confirm that you and vehicle ($ambulancePlate) have safely returned to $hospitalName.\n\nThis will mark you and the ambulance Available for new emergency dispatches.",
          style: const TextStyle(fontSize: 14, color: AppColors.slate700, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Keep Navigating", style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm & Mark Available", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('users')
            .update({'is_available': true})
            .eq('id', user.id);
      }

      final ambId = mission?['ambulance_id'];
      if (ambId != null) {
        await Supabase.instance.client
            .from('ambulances')
            .update({'is_available': true})
            .eq('id', ambId);
      }

      trackingTimer?.cancel();
      positionStreamSubscription?.cancel();

      setState(() {
        isFullScreenNav = false;
        isReturnJourney = false;
        isReturnNavigating = false;
        mission = null;
        currentSpeed = 0.0;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          content: Text("Welcome back to $hospitalName! Unit marked Available."),
        ),
      );

      await loadMission();
    } catch (e) {
      debugPrint("Error marking returned to base: $e");
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

  Widget _buildFullScreenNavView() {
    final targetName = isReturnJourney
        ? (sourceHospital?['name'] ?? "Home Base Hospital")
        : (destinationHospital?['name'] ?? mission?['destination'] ?? "Destination Facility");

    return Stack(
      children: [
        // 1. Full-screen 3D Google Map
        if (sourceLat != null && sourceLng != null)
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                currentDriverLat ?? (isReturnJourney ? destinationLat! : sourceLat!),
                currentDriverLng ?? (isReturnJourney ? destinationLng! : sourceLng!),
              ),
              zoom: 18.2,
              tilt: 50.0,
              bearing: (currentHeading != null && currentHeading! > 0) ? currentHeading! : 0.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              _animateCameraToDriver(isTight: true);
            },
            onCameraMoveStarted: () {
              if (!isProgrammaticCameraMove && isAutoFollowing) {
                setState(() => isAutoFollowing = false);
              }
            },
            trafficEnabled: true,
            compassEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: {
              // Origin Base Hospital
              Marker(
                markerId: const MarkerId('source'),
                position: LatLng(sourceLat!, sourceLng!),
                infoWindow: InfoWindow(
                  title: isReturnJourney
                      ? "${sourceHospital?['name'] ?? 'Home Base'} (Target Base)"
                      : (sourceHospital?['name'] ?? "Pickup"),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  isReturnJourney ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
                ),
              ),
              // Destination Facility
              if (destinationLat != null && destinationLng != null)
                Marker(
                  markerId: const MarkerId('destination'),
                  position: LatLng(destinationLat!, destinationLng!),
                  infoWindow: InfoWindow(
                    title: isReturnJourney
                        ? "${destinationHospital?['name'] ?? 'Destination'} (Departed)"
                        : (destinationHospital?['name'] ?? "Destination"),
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    isReturnJourney ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
                  ),
                ),
              // Live Moving Ambulance (3D Flat)
              if (currentDriverLat != null && currentDriverLng != null)
                Marker(
                  markerId: const MarkerId('ambulance'),
                  position: LatLng(currentDriverLat!, currentDriverLng!),
                  rotation: currentHeading ?? 0.0,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  infoWindow: const InfoWindow(title: "Ambulance Unit (In Transit)"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                ),
            },
            polylines: {
              if (routePoints.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('route_fullscreen'),
                  points: routePoints,
                  color: AppColors.info, // Vibrant Electric Blue (#2563EB)
                  width: 7,
                ),
            },
          )
        else
          const Center(child: CircularProgressIndicator()),

        // 2. Top Floating Navigation HUD
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.sky,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDark.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Speedometer chip with pulsing indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (currentSpeed != null && currentSpeed! > 0)
                            ? AppColors.sky
                            : AppColors.navyLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: (currentSpeed != null && currentSpeed! > 0)
                                ? AppColors.emerald
                                : AppColors.slate400,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${currentSpeed?.toStringAsFixed(0) ?? '0'} km/h",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Destination Name & ETA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isReturnJourney ? "RETURNING TO BASE" : "TRANSIT TO DESTINATION",
                          style: TextStyle(
                            color: isReturnJourney ? AppColors.info : AppColors.emerald,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          targetName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (distance != null && duration != null)
                          Text(
                            "${(distance! / 1000).toStringAsFixed(1)} km • ~${(duration! / 60).toStringAsFixed(0)} min left",
                            style: const TextStyle(
                              color: AppColors.slate300,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 1-Tap Google Maps Button
                  Tooltip(
                    message: "Open in Native Google Maps",
                    child: InkWell(
                      onTap: _launchExternalGoogleMaps,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "MAPS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Siren Audio Blast Button
                  Tooltip(
                    message: "Sound Emergency Siren",
                    child: InkWell(
                      onTap: () {
                        CitizenAlertService.testSiren();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            content: const Text(
                              "🚨 Sounding Emergency Siren...",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "SIREN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Exit Fullscreen Button
                  Tooltip(
                    message: "Minimize Map View",
                    child: InkWell(
                      onTap: () => setState(() => isFullScreenNav = false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fullscreen_exit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Re-Center GPS Floating Action Button
        Positioned(
          bottom: isNearTarget ? 170 : 100,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: "recenter_fullscreen",
            tooltip: isAutoFollowing ? "Following GPS" : "Re-center Camera on GPS",
            backgroundColor: isAutoFollowing ? AppColors.emerald : AppColors.slate900,
            foregroundColor: Colors.white,
            elevation: 6,
            onPressed: () {
              setState(() => isAutoFollowing = true);
              _animateCameraToDriver(isTight: true);
            },
            child: Icon(
              isAutoFollowing ? Icons.navigation_rounded : Icons.my_location_rounded,
              size: 20,
            ),
          ),
        ),

        // 4. Bottom Floating Action Card
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: _buildBottomNavCard(targetName),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavCard(String targetName) {
    if (isNearTarget) {
      // PROXIMITY ARRIVAL CARD (<500m)
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.slate900.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isReturnJourney ? AppColors.info : AppColors.emerald,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isReturnJourney ? AppColors.info : AppColors.emerald).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isReturnJourney ? AppColors.info : AppColors.emerald).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isReturnJourney ? AppColors.info : AppColors.emerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isReturnJourney
                            ? "APPROACHING HOME BASE (<500M)"
                            : "APPROACHING DESTINATION (<500M)",
                        style: TextStyle(
                          color: isReturnJourney ? AppColors.info : AppColors.emerald,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (distance != null)
                  Text(
                    "${distance!.toStringAsFixed(0)} m away",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              targetName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReturnJourney ? AppColors.info : AppColors.emerald,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isReturnJourney ? _markReturnedToBase : _confirmAndCompleteMission,
                icon: Icon(
                  isReturnJourney ? Icons.home_rounded : Icons.check_circle_rounded,
                  size: 22,
                ),
                label: Text(
                  isReturnJourney ? "REACHED BASE & MARK AVAILABLE" : "CONFIRM ARRIVAL & COMPLETE MISSION",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // STANDARD EN ROUTE BOTTOM CARD (>500m)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate700),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isReturnJourney ? AppColors.info : AppColors.emerald).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isReturnJourney ? Icons.u_turn_left_rounded : Icons.navigation_rounded,
              color: isReturnJourney ? AppColors.info : AppColors.emerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isReturnJourney ? "Return Transit Active" : "Emergency Corridor Active",
                  style: TextStyle(
                    color: isReturnJourney ? AppColors.info : AppColors.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  targetName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: isReturnJourney ? _markReturnedToBase : _confirmAndCompleteMission,
            child: Text(
              isReturnJourney ? "End Early" : "Arrived?",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasMission = mission != null;
    final status = mission?['status'] ?? "Standby";
    final isTransit = status == 'In Transit';

    // Full-screen 3D cockpit navigation mode
    if (isFullScreenNav && (isTransit || isReturnNavigating)) {
      return Scaffold(
        backgroundColor: AppColors.navyDark,
        body: _buildFullScreenNavView(),
      );
    }

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
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isReturnJourney
                    ? AppColors.info
                    : (isTransit ? AppColors.emerald : AppColors.primary),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isReturnJourney
                    ? Icons.u_turn_left_rounded
                    : (isTransit ? Icons.sensors_rounded : Icons.airport_shuttle_rounded),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReturnJourney ? "Return Navigation" : "Driver Transit Cockpit",
                  style: const TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  "Green Corridor Active Guidance",
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.35),
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
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "FCM Synced",
                  style: AppFonts.neueMontreal(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Refresh Cockpit",
            icon: const Icon(Icons.refresh_rounded, color: AppColors.slate700),
            onPressed: loadMission,
          ),
          IconButton(
            tooltip: "Sign Out",
            icon: const Icon(Icons.logout_rounded, color: AppColors.slate700),
            onPressed: () async {
              trackingTimer?.cancel();
              positionStreamSubscription?.cancel();
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: !hasMission
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: const BoxDecoration(
                        color: AppColors.slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        size: 56,
                        color: AppColors.slate400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Fleet Unit On Standby",
                      style: AppFonts.neueMontreal(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your unit is parked at base and Available for fast-track dispatches. Keep GPS enabled to receive instant alerts.",
                      textAlign: TextAlign.center,
                      style: AppFonts.neueMontreal(
                        fontSize: 14,
                        color: AppColors.slate500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Mission / Return Journey Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: isReturnJourney
                          ? (isReturnNavigating
                              ? AppGradients.emerald
                              : const LinearGradient(
                                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                ))
                          : (isTransit ? AppGradients.emerald : AppGradients.emergency),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: (isReturnJourney
                                  ? AppColors.info
                                  : (isTransit ? AppColors.emerald : AppColors.primary))
                              .withValues(alpha: 0.3),
                          blurRadius: 18,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isReturnJourney
                                    ? (isReturnNavigating
                                        ? "RETURN JOURNEY • IN TRANSIT"
                                        : "DELIVERY COMPLETED • AT DESTINATION")
                                    : "CORRIDOR: ${status.toUpperCase()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              ambulanceData?['vehicle_number'] ??
                                  ambulanceData?['ambulance_code'] ??
                                  ambulanceData?['plate_number'] ??
                                  (mission?['priority'] ?? "Unit Assigned"),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isReturnJourney
                              ? "Return to ${sourceHospital?['name'] ?? 'Home Base'}"
                              : (mission?['patient_name'] ?? "Emergency Transit"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (isReturnJourney)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Departing from ${destinationHospital?['name'] ?? 'Destination Hospital'}",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Route Stops Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: AppDecorations.card(radius: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              isReturnJourney
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_checked_rounded,
                              color: isReturnJourney ? AppColors.primary : AppColors.info,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isReturnJourney
                                    ? "Departing: ${destinationHospital?['name'] ?? 'Destination'}"
                                    : "Pickup: ${sourceHospital?['name'] ?? 'Facility'}",
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 18,
                              child: VerticalDivider(color: AppColors.slate200, width: 2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: isReturnJourney ? AppColors.emerald : AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isReturnJourney
                                    ? "Target Base: ${sourceHospital?['name'] ?? 'Home Base'}"
                                    : "Destination: ${mission!['destination']}",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Full-screen Cockpit Banner (when In Transit or Return Navigating)
                  if (isTransit || isReturnNavigating)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        onTap: () {
                          setState(() => isFullScreenNav = true);
                          _animateCameraToDriver(isTight: true);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isReturnNavigating
                                  ? AppColors.info
                                  : AppColors.emerald,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isReturnNavigating ? AppColors.info : AppColors.emerald)
                                    .withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isReturnNavigating ? AppColors.info : AppColors.emerald)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.fullscreen_rounded,
                                  color: isReturnNavigating ? AppColors.info : AppColors.emerald,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "EXPAND 3D FULL-SCREEN COCKPIT",
                                      style: TextStyle(
                                        color: isReturnNavigating ? AppColors.info : AppColors.emerald,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Text(
                                      "Full map coverage with tight GPS tracking & turn HUD",
                                      style: TextStyle(
                                        color: AppColors.slate300,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Map Viewport with 3D Navigation Cockpit
                  Container(
                    height: (isTransit || isReturnNavigating) ? 440 : 340,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: (isTransit || isReturnNavigating)
                            ? AppColors.emerald.withValues(alpha: 0.4)
                            : AppColors.slate200,
                        width: (isTransit || isReturnNavigating) ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isTransit || isReturnNavigating)
                              ? AppColors.emerald.withValues(alpha: 0.15)
                              : AppColors.slate900.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if (sourceLat != null && sourceLng != null)
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                currentDriverLat ?? (isReturnJourney ? destinationLat! : sourceLat!),
                                currentDriverLng ?? (isReturnJourney ? destinationLng! : sourceLng!),
                              ),
                              zoom: (isTransit || isReturnNavigating) ? 17.8 : 15,
                              tilt: (isTransit || isReturnNavigating) ? 45.0 : 0.0,
                            ),
                            onMapCreated: (controller) {
                              mapController = controller;
                              if ((isTransit || isReturnNavigating) &&
                                  currentDriverLat != null &&
                                  currentDriverLng != null) {
                                _animateCameraToDriver();
                              }
                            },
                            onCameraMoveStarted: () {
                              if (!isProgrammaticCameraMove && isAutoFollowing) {
                                setState(() => isAutoFollowing = false);
                              }
                            },
                            trafficEnabled: true,
                            compassEnabled: true,
                            markers: {
                              // Origin Base Hospital
                              Marker(
                                markerId: const MarkerId('source'),
                                position: LatLng(sourceLat!, sourceLng!),
                                infoWindow: InfoWindow(
                                  title: isReturnJourney
                                      ? "${sourceHospital?['name'] ?? 'Home Base'} (Target Base)"
                                      : (sourceHospital?['name'] ?? "Pickup"),
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  isReturnJourney ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
                                ),
                              ),
                              // Destination Facility
                              if (destinationLat != null && destinationLng != null)
                                Marker(
                                  markerId: const MarkerId('destination'),
                                  position: LatLng(destinationLat!, destinationLng!),
                                  infoWindow: InfoWindow(
                                    title: isReturnJourney
                                        ? "${destinationHospital?['name'] ?? 'Destination'} (Departed)"
                                        : (destinationHospital?['name'] ?? "Destination"),
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    isReturnJourney ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
                                  ),
                                ),
                              // Live Ambulance GPS marker (flat on 3D road)
                              if (currentDriverLat != null && currentDriverLng != null)
                                Marker(
                                  markerId: const MarkerId('ambulance'),
                                  position: LatLng(currentDriverLat!, currentDriverLng!),
                                  rotation: currentHeading ?? 0.0,
                                  anchor: const Offset(0.5, 0.5),
                                  flat: true,
                                  infoWindow: const InfoWindow(title: "Ambulance Unit (In Transit)"),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                                ),
                            },
                            polylines: {
                              if (routePoints.isNotEmpty)
                                Polyline(
                                  polylineId: const PolylineId('route'),
                                  points: routePoints,
                                  color: AppColors.info, // Electric Blue (#2563EB)
                                  width: 6,
                                ),
                            },
                          )
                        else
                          const Center(child: CircularProgressIndicator()),

                        // Live Speed HUD (Top Left)
                        if (isTransit || isReturnNavigating)
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.slate900.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
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
                                    "${currentSpeed?.toStringAsFixed(0) ?? '0'} km/h",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isReturnNavigating ? "RETURN RUN" : "LIVE 3D GPS",
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Floating Metrics & Controls HUD (Top Right)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (distance != null && duration != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate900.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.straighten_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${(distance! / 1000).toStringAsFixed(1)} km",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.emerald),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${(duration! / 60).toStringAsFixed(0)} min",
                                        style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isTransit || isReturnNavigating) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: "Expand 3D Cockpit",
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => isFullScreenNav = true);
                                      _animateCameraToDriver(isTight: true);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate900.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (isReturnNavigating ? AppColors.info : AppColors.emerald).withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.fullscreen_rounded,
                                        color: isReturnNavigating ? AppColors.info : AppColors.emerald,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Re-center / Lock to GPS Button (Bottom Right)
                        if (isTransit || isReturnNavigating)
                          Positioned(
                            bottom: 14,
                            right: 14,
                            child: FloatingActionButton.extended(
                              heroTag: 'recenter_gps',
                              onPressed: () {
                                setState(() => isAutoFollowing = true);
                                _animateCameraToDriver();
                              },
                              backgroundColor: isAutoFollowing ? AppColors.emerald : AppColors.slate900,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              icon: Icon(
                                isAutoFollowing ? Icons.navigation_rounded : Icons.my_location_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isAutoFollowing ? "TRACKING" : "RE-CENTER",
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TACTICAL ACTION CTA BUTTONS
                  if (isReturnJourney) ...[
                    if (!isReturnNavigating) ...[
                      // 1. Start Return Journey button
                      Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _startReturnJourney,
                          icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                          label: const Text(
                            "START RETURN JOURNEY TO BASE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. Fallback: Already back at base
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.slate300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _markReturnedToBase,
                          icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.slate700),
                          label: const Text(
                            "Already at Base? Mark Available",
                            style: TextStyle(
                              color: AppColors.slate700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // In return transit -> Reached base button
                      Container(
                        height: 56,
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _markReturnedToBase,
                          icon: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                          label: const Text(
                            "REACHED BASE & MARK AVAILABLE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    // Standard forward mission button
                    Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isTransit ? AppGradients.emergency : AppGradients.emerald,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (isTransit ? AppColors.primary : AppColors.emerald).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _handleMissionAction,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isTransit ? Icons.check_circle_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              status != 'In Transit' && status != 'Completed'
                                  ? "START MISSION (FULL-SCREEN 3D COCKPIT)"
                                  : isTransit
                                      ? "CONFIRM ARRIVAL & COMPLETE MISSION"
                                      : "MISSION COMPLETED",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
    );
  }
}