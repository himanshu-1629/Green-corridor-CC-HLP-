import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() =>
      _DriverDashboardState();
}

class _DriverDashboardState
    extends State<DriverDashboard> {
  Map<String, dynamic>? mission;
  Map<String, dynamic>? sourceHospital;
Map<String, dynamic>? destinationHospital;
 final mapController = MapController();
Timer? trackingTimer;
List<LatLng> routePoints = [];

double? sourceLat;
double? sourceLng;

double? destinationLat;
double? destinationLng;

double? distance;
double? duration;
  bool isLoading = true;

  Future<void> loadMission() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      final data = await Supabase.instance.client
    .from('missions')
    .select()
    .eq('driver_id', user!.id)
    .neq('status', 'Completed')
    .order('created_at', ascending: false)
    .limit(1);
if (data.isNotEmpty) {

  mission = data.first;

  sourceHospital =
      await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', mission!['hospital_id'])
          .single();

  destinationHospital =
      await Supabase.instance.client
          .from('users')
          .select()
          .eq(
            'id',
            mission!['destination_hospital_id'],
          )
          .single();

  sourceLat =
      (sourceHospital!['latitude'] as num)
          .toDouble();

  sourceLng =
      (sourceHospital!['longitude'] as num)
          .toDouble();

  destinationLat =
      (destinationHospital!['latitude'] as num)
          .toDouble();

  destinationLng =
      (destinationHospital!['longitude'] as num)
          .toDouble();
          await getRoute();
          if (mission!['status'] == 'In Transit') {
  await startLiveTracking();
}

} else {

  mission = null;
}

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> getRoute() async {

  final response = await http.get(
    Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car'
      '?start=$sourceLng,$sourceLat'
      '&end=$destinationLng,$destinationLat',
    ),
    headers: {
      'Authorization':
          'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImEwZjhiYmQwM2U3YzQxNWY5ZTg5ZDIzZDRiMjAzYWI1IiwiaCI6Im11cm11cjY0In0=',
    },
  );

  final data = jsonDecode(response.body);

  distance =
      data['features'][0]['properties']
          ['segments'][0]['distance'];

  duration =
      data['features'][0]['properties']
          ['segments'][0]['duration'];

  final coords =
      data['features'][0]['geometry']['coordinates'];

  routePoints =
      coords.map<LatLng>((point) {
    return LatLng(
      point[1],
      point[0],
    );
  }).toList();

  setState(() {});
}
Future<void> startLiveTracking() async {

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
trackingTimer?.cancel();
  trackingTimer = Timer.periodic(
    const Duration(seconds: 5),
    (timer) async {

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await Supabase.instance.client
          .from('ambulances')
          .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'last_updated':
                DateTime.now().toIso8601String(),
          })
          .eq(
            'id',
            mission!['ambulance_id'],
          );

      print(
        "Live Location: ${position.latitude}, ${position.longitude}",
      );
    },
  );
}

  @override
  void initState() {
    super.initState();
    loadMission();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Driver Dashboard"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),

      body: mission == null
          ? const Center(
              child: Text(
                "No mission assigned",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),

              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Assigned Mission",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Patient / Organ: ${mission!['patient_name']}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

Text(
  "Pickup : ${sourceHospital!['name']}",
),



                    const SizedBox(height: 10),

                    Text(
                      "Destination: ${mission!['destination']}",
                    ),
const SizedBox(height: 20),

SizedBox(
  height: 300,
  child: FlutterMap(
    mapController: mapController,
    options: MapOptions(
      initialCenter: LatLng(
        sourceLat!,
        sourceLng!,
      ),
      initialZoom: 15,
    ),
    children: [

      TileLayer(
        urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),

      PolylineLayer(
        polylines: [
          if (routePoints.isNotEmpty)
            Polyline(
              points: routePoints,
              color: Colors.blue,
              strokeWidth: 5,
            ),
        ],
      ),

      MarkerLayer(
        markers: [

          Marker(
            point: LatLng(
              sourceLat!,
              sourceLng!,
            ),
            width: 50,
            height: 50,
            child: const Icon(
              Icons.local_hospital,
              color: Colors.blue,
              size: 40,
            ),
          ),

          Marker(
            point: LatLng(
              destinationLat!,
              destinationLng!,
            ),
            width: 50,
            height: 50,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 45,
            ),
          ),
        ],
      ),
    ],
  ),
),
const SizedBox(height: 15),

if (distance != null && duration != null)
  Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceEvenly,
    children: [
      Text(
        "📏 ${(distance! / 1000).toStringAsFixed(1)} km",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        "⏱ ${(duration! / 60).toStringAsFixed(0)} min",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
                    const SizedBox(height: 10),

                    Text(
                      "Priority / Time Limit: ${mission!['priority']}",
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Status: ${mission!['status']}",
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                       onPressed: mission!['status'] == 'Completed'
    ? null
    : () async {
        if (mission!['status'] == 'Assigned') {
          await Supabase.instance.client
              .from('missions')
              .update({
                'status': 'In Transit',
              })
              .eq('id', mission!['id']);
              await startLiveTracking();
        } else {

  trackingTimer?.cancel();

          await Supabase.instance.client
              .from('missions')
              .update({
                'status': 'Completed',
              })
              .eq('id', mission!['id']);
              await Supabase.instance.client
    .from('users')
    .update({
      'is_available': true,
    })
    .eq('id', mission!['driver_id']);
    await Supabase.instance.client
    .from('ambulances')
    .update({
      'is_available': true,
    })
    .eq('id', mission!['ambulance_id']);
        }

        await loadMission();
      },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE53935),
                          foregroundColor:
                              Colors.white,
                        ),

                        child: Text(
  mission!['status'] == 'Assigned'
      ? 'START MISSION'
      : mission!['status'] == 'In Transit'
          ? 'COMPLETE MISSION'
          : 'MISSION COMPLETED',
),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  @override
void dispose() {
  trackingTimer?.cancel();
  super.dispose();
}
}