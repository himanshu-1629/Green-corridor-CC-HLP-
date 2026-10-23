import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/citizen_alert_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';


class CitizenScreen extends StatefulWidget {
  const CitizenScreen({super.key});

  @override
  State<CitizenScreen> createState() => _CitizenScreenState();
}

class _CitizenScreenState extends State<CitizenScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _corridorPollTimer;

  // Citizen Position
  double? _citizenLat;
  double? _citizenLng;
  bool _hasGpsFix = false;
  bool _isGpsLoading = true;

  // Active In-Transit Corridor Data
  Map<String, dynamic>? _activeMission;
  Map<String, dynamic>? _activeAmbulance;
  Map<String, dynamic>? _sourceHospital;
  Map<String, dynamic>? _destinationHospital;
  double? _ambulanceLat;
  double? _ambulanceLng;
  double? _ambulanceSpeed; // km/h
  double? _distanceToAmbulance; // meters direct to ambulance
  double? _distanceToRoute; // meters perpendicular to nearest segment of corridor route
  List<LatLng> _routePoints = [];

  // Audio / Alert Settings
  bool _isMuted = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _inAppNotificationSubscription;
  RealtimeChannel? _realtimeMissionChannel;

  /// User is considered "in between the path" if:
  /// 1. An active ambulance mission is in transit.
  /// 2. Citizen is within 250m lateral distance of the corridor polyline route.
  /// 3. The ambulance has not already passed the citizen (citizen is in front of the ambulance towards destination).
  bool get isUserInCorridorPath {
    if (_citizenLat == null || _citizenLng == null) return false;
    if (_ambulanceLat == null || _ambulanceLng == null) return false;
    if (_routePoints.isEmpty) return false;

    // Must be within 250m of the road/corridor route
    if (_distanceToRoute == null || _distanceToRoute! > 250.0) {
      return false;
    }

    // Must be in between the ambulance and the destination hospital
    if (_destinationHospital != null &&
        _destinationHospital!['latitude'] != null &&
        _destinationHospital!['longitude'] != null) {
      final dLat = (_destinationHospital!['latitude'] as num).toDouble();
      final dLng = (_destinationHospital!['longitude'] as num).toDouble();

      final distAmbToDest = Geolocator.distanceBetween(_ambulanceLat!, _ambulanceLng!, dLat, dLng);
      final distCitizenToDest = Geolocator.distanceBetween(_citizenLat!, _citizenLng!, dLat, dLng);

      // If citizen is further from destination than the ambulance by > 120m, the ambulance has passed the citizen
      if (distCitizenToDest > distAmbToDest + 120.0) {
        return false;
      }
    }

    return true;
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCitizenGpsAndTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionSubscription?.cancel();
    _corridorPollTimer?.cancel();
    _inAppNotificationSubscription?.cancel();
    _realtimeMissionChannel?.unsubscribe();
    _mapController?.dispose();
    super.dispose();
  }

  void _showDriverStartedInAppNotification(Map<String, dynamic> data) {
    if (!mounted) return;

    final plate = data['vehicle_number'] ?? activeAmbulancePlate();
    final dest = data['destination'] ?? _destinationHospital?['name'] ?? 'Emergency Facility';
    final patient = data['patient_name'] ?? data['organ'] ?? 'Emergency Patient';

    // Play proximity siren audio
    CitizenAlertService.triggerProximityAlert(isCritical: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626), // Emergency Red
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emergency_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🚨 DRIVER STARTED JOURNEY!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Ambulance $plate has departed and is actively en route to $dest ($patient). Clear the left lane!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initCitizenGpsAndTracking() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
        );

        if (mounted) {
          setState(() {
            _citizenLat = initialPos.latitude;
            _citizenLng = initialPos.longitude;
            _hasGpsFix = true;
            _isGpsLoading = false;
          });
        }

        // Real-time GPS stream
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 3,
          ),
        ).listen((Position pos) {
          if (!mounted) return;
          setState(() {
            _citizenLat = pos.latitude;
            _citizenLng = pos.longitude;
            _hasGpsFix = true;
          });
          _recalculateDistance();
        });
      } else {
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Citizen GPS init error: $e");
      if (mounted) {
        setState(() {
          _isGpsLoading = false;
        });
      }
    }

    // Initial corridor check and periodic poll every 3 seconds
    await _pollActiveCorridors();
    _corridorPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollActiveCorridors();
    });

    // Realtime in-app push notification stream listener
    _inAppNotificationSubscription = PushNotificationService.onInAppNotification.listen((event) {
      if (!mounted) return;
      if (event['event_type'] == 'driver_started') {
        _pollActiveCorridors();
        _showDriverStartedInAppNotification(event['data'] ?? {});
      }
    });

    // Supabase Realtime channel for instant mission state updates
    try {
      _realtimeMissionChannel = Supabase.instance.client
          .channel('public:missions:citizen_live')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'missions',
            callback: (payload) {
              debugPrint("Realtime missions table change: ${payload.eventType}");
              final newRec = payload.newRecord;
              if (newRec['status'] == 'In Transit') {
                _pollActiveCorridors();
                _showDriverStartedInAppNotification(newRec);
              } else if (newRec['status'] == 'Completed') {
                _pollActiveCorridors();
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("Realtime mission subscribe error: $e");
    }
  }

  Future<void> _pollActiveCorridors() async {
    try {
      // 1. Fetch active missions in transit
      final activeMissions = await Supabase.instance.client
          .from('missions')
          .select()
          .eq('status', 'In Transit')
          .order('created_at', ascending: false);

      if (activeMissions.isEmpty) {
        if (mounted && _activeMission != null) {
          setState(() {
            _activeMission = null;
            _activeAmbulance = null;
            _ambulanceLat = null;
            _ambulanceLng = null;
            _distanceToAmbulance = null;
            _distanceToRoute = null;
            _routePoints = [];
          });
        }
        return;
      }

      // If multiple, pick the one closest to citizen
      Map<String, dynamic>? closestMission;
      Map<String, dynamic>? closestAmbulance;
      double minDistance = double.infinity;

      for (final m in activeMissions) {
        final ambId = m['ambulance_id'];
        if (ambId == null) continue;

        final amb = await Supabase.instance.client
            .from('ambulances')
            .select()
            .eq('id', ambId)
            .maybeSingle();

        if (amb != null && amb['latitude'] != null && amb['longitude'] != null) {
          final aLat = (amb['latitude'] as num).toDouble();
          final aLng = (amb['longitude'] as num).toDouble();

          double dist = 999999;
          if (_citizenLat != null && _citizenLng != null) {
            dist = Geolocator.distanceBetween(_citizenLat!, _citizenLng!, aLat, aLng);
          }

          if (dist < minDistance) {
            minDistance = dist;
            closestMission = m;
            closestAmbulance = amb;
          }
        }
      }

      // Robust fallback: if no ambulance coordinates matched distance, use first active mission
      if (closestMission == null && activeMissions.isNotEmpty) {
        closestMission = activeMissions.first;
        if (closestMission['ambulance_id'] != null) {
          closestAmbulance = await Supabase.instance.client
              .from('ambulances')
              .select()
              .eq('id', closestMission['ambulance_id'])
              .maybeSingle();
        }
      }

      if (closestMission == null) return;

      double? ambLat = (closestAmbulance?['latitude'] as num?)?.toDouble();
      double? ambLng = (closestAmbulance?['longitude'] as num?)?.toDouble();
      final ambSpeed = closestAmbulance?['speed'] != null ? (closestAmbulance!['speed'] as num).toDouble() : null;

      // Fetch hospital details if changed
      if (_sourceHospital == null || _sourceHospital!['id'] != closestMission['hospital_id']) {
        try {
          _sourceHospital = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', closestMission['hospital_id'])
              .maybeSingle();
        } catch (_) {}
      }

      if (_destinationHospital == null || _destinationHospital!['id'] != closestMission['destination_hospital_id']) {
        try {
          _destinationHospital = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', closestMission['destination_hospital_id'])
              .maybeSingle();
        } catch (_) {}
      }

      // Fallback coordinates from source hospital if ambulance telemetry ping hasn't arrived yet
      ambLat ??= (_sourceHospital?['latitude'] as num?)?.toDouble() ?? 12.8437;
      ambLng ??= (_sourceHospital?['longitude'] as num?)?.toDouble() ?? 80.1518;

      // Check if mission just transitioned into In Transit for this citizen session
      final wasInTransit = _activeMission != null && _activeMission!['status'] == 'In Transit';
      final isNowInTransit = closestMission['status'] == 'In Transit';

      if (!wasInTransit && isNowInTransit) {
        _showDriverStartedInAppNotification(closestMission);
      }

      // Fetch polyline route if empty or mission changed
      if (_routePoints.isEmpty && _destinationHospital != null && _destinationHospital!['latitude'] != null) {
        final destLat = (_destinationHospital!['latitude'] as num).toDouble();
        final destLng = (_destinationHospital!['longitude'] as num).toDouble();
        _fetchCorridorRoute(ambLat, ambLng, destLat, destLng);
      }

      if (mounted) {
        setState(() {
          _activeMission = closestMission;
          _activeAmbulance = closestAmbulance;
          _ambulanceLat = ambLat;
          _ambulanceLng = ambLng;
          _ambulanceSpeed = ambSpeed;
        });
      }

      _recalculateDistance();
    } catch (e) {
      debugPrint("Citizen corridor poll error: $e");
    }
  }

  /// Calculates perpendicular geodesic distance from point p to line segment [a, b]
  double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final double x = p.longitude;
    final double y = p.latitude;
    final double x1 = a.longitude;
    final double y1 = a.latitude;
    final double x2 = b.longitude;
    final double y2 = b.latitude;

    final double dx = x2 - x1;
    final double dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return Geolocator.distanceBetween(y, x, y1, x1);
    }

    final double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
    final double clampedT = t.clamp(0.0, 1.0);

    final double projX = x1 + clampedT * dx;
    final double projY = y1 + clampedT * dy;

    return Geolocator.distanceBetween(y, x, projY, projX);
  }

  /// Shortest distance from user position to the entire polyline route
  double _calculateDistanceToRoute(LatLng userPos, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;
    if (route.length == 1) {
      return Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        route[0].latitude,
        route[0].longitude,
      );
    }

    double minMeters = double.infinity;
    for (int i = 0; i < route.length - 1; i++) {
      final d = _distanceToSegment(userPos, route[i], route[i + 1]);
      if (d < minMeters) {
        minMeters = d;
      }
    }
    return minMeters;
  }

  void _recalculateDistance() {
    if (_citizenLat == null || _citizenLng == null) return;

    // 1. Calculate distance from citizen to corridor road polyline
    if (_routePoints.isNotEmpty) {
      _distanceToRoute = _calculateDistanceToRoute(
        LatLng(_citizenLat!, _citizenLng!),
        _routePoints,
      );
    } else {
      _distanceToRoute = null;
    }

    if (_ambulanceLat == null || _ambulanceLng == null) {
      _distanceToAmbulance = null;
      if (mounted) setState(() {});
      return;
    }

    // 2. Direct distance to approaching ambulance
    final meters = Geolocator.distanceBetween(
      _citizenLat!,
      _citizenLng!,
      _ambulanceLat!,
      _ambulanceLng!,
    );

    if (mounted) {
      setState(() {
        _distanceToAmbulance = meters;
      });
    }

    // 3. Trigger Proximity Audio Siren ONLY if the citizen is IN BETWEEN THE PATH!
    if (isUserInCorridorPath && meters <= 1000 && !_isMuted) {
      CitizenAlertService.triggerProximityAlert(isCritical: meters <= 500);
    }
  }

  Future<void> _fetchCorridorRoute(double sLat, double sLng, double dLat, double dLng) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$sLng,$sLat;$dLng,$dLat?overview=full&geometries=geojson',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          if (mounted) {
            setState(() {
              _routePoints = coords.map<LatLng>((c) {
                return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
              }).toList();
            });
            _recalculateDistance();
          }
        }
      }
    } catch (e) {
      debugPrint("OSRM corridor polyline fetch error: $e");
    }
  }

  void _focusOnAmbulance() {
    if (_ambulanceLat == null || _ambulanceLng == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_ambulanceLat!, _ambulanceLng!),
          zoom: 16.5,
          tilt: 35,
        ),
      ),
    );
  }

  void _focusOnCitizen() {
    if (_citizenLat == null || _citizenLng == null || _mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_citizenLat!, _citizenLng!),
          zoom: 16.5,
        ),
      ),
    );
  }

  void _fitCorridorBounds() {
    if (_mapController == null) return;

    final points = <LatLng>[];
    if (_citizenLat != null && _citizenLng != null) {
      points.add(LatLng(_citizenLat!, _citizenLng!));
    }
    if (_ambulanceLat != null && _ambulanceLng != null) {
      points.add(LatLng(_ambulanceLat!, _ambulanceLng!));
    }

    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool inPath = isUserInCorridorPath;
    final bool isNearWarning = inPath && _distanceToAmbulance != null && _distanceToAmbulance! <= 1000;
    final bool isNearCritical = inPath && _distanceToAmbulance != null && _distanceToAmbulance! <= 500;
    final bool isCorridorActive = _activeMission != null && _ambulanceLat != null && _ambulanceLng != null;

    final defaultCenter = LatLng(_citizenLat ?? 12.8406, _citizenLng ?? 80.1534);

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
              child: const Icon(
                Icons.satellite_alt_rounded,
                color: AppColors.sky,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Citizen Corridor Radar",
                  style: TextStyle(
                    fontFamily: AppTypography.fontHeading,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                    letterSpacing: -0.3,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.sky,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      inPath
                          ? "In Active Corridor Path"
                          : (_hasGpsFix ? "Live GPS Connected" : "Acquiring GPS..."),
                      style: const TextStyle(
                        fontFamily: AppTypography.fontBody,
                        fontSize: 11,
                        color: AppColors.sky,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Direct Test Siren Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.campaign_rounded, size: 18),
              label: const Text(
                "Test Siren",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              onPressed: () {
                CitizenAlertService.testSiren();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    content: const Text(
                      "🚨 Playing Dual-Tone Emergency Siren Waveform...",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Audio Siren Mute Toggle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _isMuted ? AppColors.slate100 : AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isMuted ? AppColors.slate200 : AppColors.emerald.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              tooltip: _isMuted ? "Unmute Emergency Siren" : "Mute Siren",
              icon: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: _isMuted ? AppColors.slate500 : AppColors.emeraldDark,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _isMuted ? AppColors.slate800 : AppColors.emerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    content: Text(
                      _isMuted ? "Siren audio muted" : "Emergency siren audio active",
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: "Refresh Scan",
            icon: const Icon(Icons.refresh_rounded, color: AppColors.slate700),
            onPressed: _pollActiveCorridors,
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
          const SizedBox(width: 12),
        ],
      ),
      body: _isGpsLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.emerald),
                  const SizedBox(height: 16),
                  Text(
                    "Calibrating Geofence Radar...",
                    style: GoogleFonts.plusJakartaSans(color: AppColors.slate600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. DYNAMIC PROXIMITY ALERT BANNER
                      if (isNearCritical)
                        _buildCriticalAlertBanner()
                      else if (isNearWarning)
                        _buildWarningAlertBanner()
                      else if (inPath)
                        _buildInPathApproachingBanner()
                      else if (isCorridorActive)
                        _buildActiveCorridorTransitBanner()
                      else
                        _buildClearStatusBanner(false),

                      const SizedBox(height: 20),

                      // 2. LIVE INTERACTIVE AMBULANCE & USER MAP
                      _buildLiveRadarMap(defaultCenter, inPath, isCorridorActive),

                      const SizedBox(height: 20),

                      // 3. ACTIVE AMBULANCE TELEMETRY CARD
                      if (inPath || isCorridorActive) _buildActiveAmbulanceCard(),

                      if (inPath || isCorridorActive) const SizedBox(height: 24),

                      // 4. CITIZEN FAST-TRACK CLEARANCE PROTOCOLS
                      Text(
                        "Citizen Fast-Track Protocol",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _guidelineTile(
                        icon: Icons.volume_up_rounded,
                        color: AppColors.primary,
                        title: "Listen for Emergency Sirens",
                        subtitle: "Green Corridor ambulances emit dual-tone sirens and strobe light signals.",
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            CitizenAlertService.testSiren();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                content: const Text(
                                  "🚨 Playing Dual-Tone Emergency Siren Waveform...",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.volume_up_rounded, size: 14),
                          label: const Text(
                            "Play Siren",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _guidelineTile(
                        icon: Icons.directions_car_rounded,
                        color: AppColors.emerald,
                        title: "Yield to the Extreme Left",
                        subtitle: "Safely pull over to clear the center-right fast lane for medical transit.",
                      ),
                      const SizedBox(height: 10),
                      _guidelineTile(
                        icon: Icons.traffic_rounded,
                        color: AppColors.amber,
                        title: "Do Not Tailgate or Block Junctions",
                        subtitle: "Maintain a minimum distance of 150 meters behind transit convoys.",
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCriticalAlertBanner() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EMERGENCY CORRIDOR ON YOUR PATH (<500M)",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Ambulance ${activeAmbulancePlate()} is ${_distanceToAmbulance!.toStringAsFixed(0)} meters away on your road!",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "IMMEDIATE ACTION: Safely pull over to the extreme left lane. Do NOT enter upcoming junctions.",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningAlertBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AMBULANCE WITHIN 1 KM • ON YOUR ROUTE",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Ambulance ${activeAmbulancePlate()} is approaching along your road (${(_distanceToAmbulance! / 1000).toStringAsFixed(2)} km away). Prepare to yield.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInPathApproachingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ACTIVE GREEN CORRIDOR IN PROGRESS",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "An active emergency ambulance is en route along your road (${(_distanceToAmbulance! / 1000).toStringAsFixed(1)} km away). Live GPS unlocked. Stay alert.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCorridorTransitBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 28),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "CONVOY IN TRANSIT",
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "DRIVER STARTED MISSION",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Ambulance ${activeAmbulancePlate()} has departed from ${_sourceHospital?['name'] ?? 'Hospital'} and is en route to ${_destinationHospital?['name'] ?? 'Destination'}.${_distanceToAmbulance != null ? ' (${(_distanceToAmbulance! / 1000).toStringAsFixed(1)} km away)' : ''} Keep roads clear.",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearStatusBanner(bool isCorridorActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Corridors Clear In Your Area",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCorridorActive && _distanceToRoute != null && _distanceToRoute != double.infinity
                      ? "An emergency corridor is active elsewhere in the city (${(_distanceToRoute! / 1000).toStringAsFixed(1)} km from your road). You are outside the corridor path. Traffic normal."
                      : "Geofence active. You will only be alerted and shown live ambulance GPS if an emergency convoy is routed directly through your street.",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRadarMap(LatLng defaultCenter, bool inPath, bool isCorridorActive) {
    final markers = <Marker>{};

    // 1. Citizen Marker (Always shown: "Your Location")
    if (_citizenLat != null && _citizenLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('citizen_location'),
          position: LatLng(_citizenLat!, _citizenLng!),
          infoWindow: const InfoWindow(title: "Your Location (Citizen)"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // 2. Approaching Ambulance Marker (Red if in path, Orange if active corridor elsewhere)
    if (_ambulanceLat != null && _ambulanceLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_ambulance'),
          position: LatLng(_ambulanceLat!, _ambulanceLng!),
          infoWindow: InfoWindow(
            title: "Ambulance ${activeAmbulancePlate()}",
            snippet: _distanceToAmbulance != null
                ? "${_distanceToAmbulance!.toStringAsFixed(0)}m away • In Transit"
                : "In Transit",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            inPath ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    // 3. Destination Hospital Marker (Green Hue)
    if (_destinationHospital != null &&
        _destinationHospital!['latitude'] != null &&
        _destinationHospital!['longitude'] != null) {
      final dLat = (_destinationHospital!['latitude'] as num).toDouble();
      final dLng = (_destinationHospital!['longitude'] as num).toDouble();
      markers.add(
        Marker(
          markerId: const MarkerId('destination_hospital'),
          position: LatLng(dLat, dLng),
          infoWindow: InfoWindow(title: "Target: ${_destinationHospital!['name'] ?? 'Destination'}"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return Container(
      decoration: AppDecorations.card(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: inPath
                            ? AppColors.primary
                            : (_hasGpsFix ? AppColors.emerald : AppColors.amber),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      inPath ? "Live Ambulance Radar (In Path)" : "Citizen Location Radar",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate900),
                    ),
                  ],
                ),
                if (inPath && _distanceToAmbulance != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _distanceToAmbulance! <= 500
                          ? AppColors.primaryLight
                          : _distanceToAmbulance! <= 1000
                              ? AppColors.warningLight
                              : AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _distanceToAmbulance! < 1000
                          ? "ON PATH • ${_distanceToAmbulance!.toStringAsFixed(0)} m"
                          : "ON PATH • ${(_distanceToAmbulance! / 1000).toStringAsFixed(1)} km",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _distanceToAmbulance! <= 500
                            ? AppColors.primary
                            : _distanceToAmbulance! <= 1000
                                ? AppColors.amber
                                : AppColors.info,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "OFF PATH • CLEAR",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Google Map Container
          SizedBox(
            height: 380,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: defaultCenter,
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (inPath) {
                      _fitCorridorBounds();
                    }
                  },
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: markers,
                  polylines: {
                    if (_routePoints.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('citizen_corridor_route'),
                        points: _routePoints,
                        color: inPath ? AppColors.primary : AppColors.info,
                        width: 6,
                      ),
                  },
                ),

                // Floating Map Controls (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      // Focus on Ambulance (available when ambulance is active)
                      if (_ambulanceLat != null && _ambulanceLng != null)
                        _mapActionButton(
                          icon: Icons.airport_shuttle_rounded,
                          tooltip: "Focus on Ambulance",
                          color: inPath ? AppColors.primary : const Color(0xFFD97706),
                          onPressed: _focusOnAmbulance,
                        ),
                      if (_ambulanceLat != null && _ambulanceLng != null) const SizedBox(height: 8),

                      // Recenter on Citizen
                      _mapActionButton(
                        icon: Icons.my_location_rounded,
                        tooltip: "Recenter on My Location",
                        color: AppColors.info,
                        onPressed: _focusOnCitizen,
                      ),
                      const SizedBox(height: 8),

                      // Fit Both in View (available when ambulance is active)
                      if (_ambulanceLat != null && _ambulanceLng != null)
                        _mapActionButton(
                          icon: Icons.crop_free_rounded,
                          tooltip: "Fit Entire Corridor",
                          color: AppColors.slate800,
                          onPressed: _fitCorridorBounds,
                        ),
                    ],
                  ),
                ),

                // Map Legend (Bottom Left)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendDot(AppColors.info, "You"),
                        if (inPath) ...[
                          const SizedBox(width: 8),
                          _legendDot(AppColors.primary, "Ambulance"),
                          const SizedBox(width: 8),
                          _legendDot(AppColors.emerald, "Hospital"),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveAmbulanceCard() {
    final organ = _activeMission?['patient_name'] ?? _activeMission?['organ_type'] ?? "Critical Medical Transport";
    final destName = _destinationHospital?['name'] ?? _activeMission?['destination'] ?? "Emergency Facility";
    final sourceName = _sourceHospital?['name'] ?? _activeMission?['source'] ?? "Dispatch Hospital";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      organ.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_ambulanceSpeed != null && _ambulanceSpeed! > 0)
                Text(
                  "${_ambulanceSpeed!.toStringAsFixed(0)} km/h",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate700),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Live Corridor on Your Road: $sourceName → $destName",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate900),
          ),
          const SizedBox(height: 6),
          Text(
            "Vehicle: ${activeAmbulancePlate()} • Medical emergency convoy approaching along your street.",
            style: const TextStyle(fontSize: 13, color: AppColors.slate600),
          ),

        ],
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate700)),
      ],
    );
  }

  Widget _guidelineTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(radius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.3),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  String activeAmbulancePlate() {
    return _activeAmbulance?['vehicle_number'] ??
        _activeAmbulance?['ambulance_code'] ??
        _activeAmbulance?['plate_number'] ??
        "Unit";
  }
}