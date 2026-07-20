import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  String? selectedMissionType;
  String? hospitalName;
double? hospitalLat;
double? hospitalLng;
double? selectedLat;
double? selectedLng;
double? routeDistance;
double? routeDuration;
  final List<String> missionTypes = [
    "Organ Transport",
    "Patient Transfer",
    "Blood Transport",
    "Body Transfer",
    "Medical Equipment",
  ];

  final List<String> organs = ["Heart", "Liver", "Kidney", "Lungs", "Pancreas"];
final mapController = MapController();
  String? selectedOrgan;
  String? selectedDriverId;
List<Map<String, dynamic>> ambulances = [];
String? selectedAmbulanceId;
List<Marker> markers = [];
List<LatLng> routePoints = [];
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> hospitals = [];
 
String? selectedHospitalId;
  final destinationController = TextEditingController();
  final timeLimitController = TextEditingController();
  final ambulanceController = TextEditingController();

  bool isLoading = false;
  Future<void> loadAmbulances() async {
  final userId =
      Supabase.instance.client.auth.currentUser!.id;
      final currentUser =
    Supabase.instance.client.auth.currentUser;
final currentHospital =

    await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', currentUser!.id)
        .single();
setState(() {
  hospitalLat =
      (currentHospital['latitude'] as num?)?.toDouble();

  hospitalLng =
      (currentHospital['longitude'] as num?)?.toDouble();
      hospitalName = currentHospital['name'];
});
await loadHospitals();
if (hospitalLat != null &&
    hospitalLng != null) {

  WidgetsBinding.instance.addPostFrameCallback((_) {
    mapController.move(
      LatLng(
        hospitalLat!,
        hospitalLng!,
      ),
      18,
    );
  });
}


  final data = await Supabase.instance.client
      .from('ambulances')
      .select()
      .eq('hospital_id', userId)
      .eq('is_available', true);

  setState(() {
    ambulances =
        List<Map<String, dynamic>>.from(data);
  });
}
Future<void> getRoute(
  double startLat,
  double startLng,
  double endLat,
  double endLng,
) async {

 final response = await http.get(
  Uri.parse(
    'https://api.openrouteservice.org/v2/directions/driving-car'
    '?start=$startLng,$startLat'
    '&end=$endLng,$endLat',
  ),
  headers: {
    'Authorization': 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImEwZjhiYmQwM2U3YzQxNWY5ZTg5ZDIzZDRiMjAzYWI1IiwiaCI6Im11cm11cjY0In0=',
  },
);

  final data = jsonDecode(response.body);
  routeDistance =
    data['features'][0]['properties']
        ['segments'][0]['distance'];

routeDuration =
    data['features'][0]['properties']
        ['segments'][0]['duration'];

  final coords =
      data['features'][0]['geometry']['coordinates'];
final distanceKm =
    (routeDistance! / 1000)
        .toStringAsFixed(1);

final durationMin =
    (routeDuration! / 60)
        .toStringAsFixed(0);
  routePoints =
      coords.map<LatLng>((point) {
    return LatLng(
      point[1],
      point[0],
    );
  }).toList();

  setState(() {});
}
  Future<void> createMission() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = Supabase.instance.client.auth.currentUser;
if (selectedDriverId != null) {
  await Supabase.instance.client
      .from('users')
      .update({
        'is_available': false,
      })
      .eq('id', selectedDriverId!);
}
if (selectedAmbulanceId != null) {
  await Supabase.instance.client
      .from('ambulances')
      .update({
        'is_available': false,
      })
      .eq('id', selectedAmbulanceId!);
}
     await Supabase.instance.client.from('missions').insert({
  'patient_name': selectedOrgan ?? selectedMissionType ?? 'Mission',

 'pickup_location': hospitalName,

  'destination': destinationController.text,

  'destination_hospital_id': selectedHospitalId,
'ambulance_id': selectedAmbulanceId,
  'priority': timeLimitController.text.trim(),

  'hospital_id': user?.id,
  'driver_id': selectedDriverId,
  'status': selectedDriverId == null
      ? 'Pending'
      : 'Assigned',
});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mission Created Successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadDrivers() async {
    final data = await Supabase.instance.client
    .from('users')
    .select()
    .eq('role', 'Driver')
    .eq('is_available', true);

    setState(() {
      drivers = List<Map<String, dynamic>>.from(data);
    });
  }
  Future<void> loadHospitals() async {
  final currentUser =
    Supabase.instance.client.auth.currentUser;

final data = await Supabase.instance.client
    .from('users')
    .select()
    .eq('role', 'Hospital Admin')
    .neq('id', currentUser!.id);
 final hospitalList =
    List<Map<String, dynamic>>.from(data);
print(hospitalList);
print("Hospitals count: ${hospitalList.length}");
List<Marker> hospitalMarkers = [];

for (final hospital in hospitalList) {

  if (hospital['latitude'] == null ||
      hospital['longitude'] == null) {
    continue;
  }
  print(
  "Marker Added: "
  "${hospital['name']}"
);
hospitalMarkers.add(
  Marker(
    point: LatLng(
  (hospital['latitude'] as num).toDouble(),
  (hospital['longitude'] as num).toDouble(),
),

    width: 120,
    height: 120,

    child: GestureDetector(
      onTap: () async {

  setState(() {

    selectedHospitalId =
        hospital['id'];
      destinationController.text =
"${hospital['name']} (${hospital['hospital_code']})";

    selectedLat =
        (hospital['latitude'] as num)
            .toDouble();

    selectedLng =
        (hospital['longitude'] as num)
            .toDouble();
  });
  await loadHospitals();
  await getRoute(
  hospitalLat!,
  hospitalLng!,
  selectedLat!,
  selectedLng!,
);
await loadHospitals();
},

      child: Icon(
  Icons.location_on,

  color:
      selectedHospitalId ==
              hospital['id']
          ? Colors.green
          : Colors.red,

  size:
      selectedHospitalId ==
              hospital['id']
          ? 70
          : 40,
),
    ),
  ),
);
}
if (hospitalLat != null &&
    hospitalLng != null) {

  hospitalMarkers.add(
    Marker(
      point: LatLng(
        hospitalLat!,
        hospitalLng!,
      ),

      width: 20,
      height: 20,

      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
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
void initState() {
  super.initState();
loadAmbulances();
  loadHospitals();
  loadDrivers();
}

  @override
  Widget build(BuildContext context) {
    if (hospitalLat == null || hospitalLng == null) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        title: const Text("Create Mission"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Mission Type",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: missionTypes.map((type) {
                bool selected = selectedMissionType == type;

                return ChoiceChip(
                  label: Text(type),

                  selected: selected,

                  onSelected: (_) {
                    setState(() {
                      selectedMissionType = type;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            if (selectedMissionType == "Organ Transport")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Organ Type",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    value: selectedOrgan,

                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),

                    items: organs.map((organ) {
                      return DropdownMenuItem(value: organ, child: Text(organ));
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedOrgan = value.toString();
                      });
                    },
                  ),
                ],
              ),

            const SizedBox(height: 25),

         const SizedBox(height: 25),



const SizedBox(height: 20),
if (routeDistance != null &&
    routeDuration != null)

  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(12),
    ),

    child: Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,

      children: [

        Text(
          "📏 ${(routeDistance! / 1000).toStringAsFixed(1)} km",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          "⏱ ${(routeDuration! / 60).toStringAsFixed(0)} min",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
SizedBox(
  height: 300,

  child: FlutterMap(
  mapController: mapController,
    options: MapOptions(
    initialCenter: LatLng(
  hospitalLat!,
  hospitalLng!,
),
      initialZoom: 18,
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
        markers: markers,
      ),
    ],
  ),
),

const SizedBox(height: 20),
RawAutocomplete<Map<String, dynamic>>(
  textEditingController: destinationController,

  focusNode: FocusNode(),

  optionsBuilder: (TextEditingValue value) {

    if (value.text.isEmpty) {
      return hospitals;
    }

    return hospitals.where((hospital) {

      final query = value.text.toLowerCase();

      return hospital['name']
              .toString()
              .toLowerCase()
              .contains(query) ||

          (hospital['hospital_code'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query);
    });
  },

  displayStringForOption: (hospital) =>
      "${hospital['name']} (${hospital['hospital_code']})",

  fieldViewBuilder: (
    context,
    controller,
    focusNode,
    onSubmitted,
  ) {

    return TextField(
      controller: controller,
      focusNode: focusNode,

      decoration: InputDecoration(
        labelText: "Destination Hospital",

        hintText:
            "Search Hospital Name / Code",

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  },

  optionsViewBuilder:
      (
        context,
        onSelected,
        options,
      ) {

    return Align(
      alignment: Alignment.topLeft,

      child: Material(
        elevation: 5,

        child: SizedBox(
          width: 350,

          child: ListView.builder(

            shrinkWrap: true,

            itemCount: options.length,

            itemBuilder: (context, index) {

              final hospital =
                  options.elementAt(index);

              return ListTile(

                leading: const Icon(
                  Icons.local_hospital,
                  color: Colors.red,
                ),

                title:
                    Text(hospital['name']),

                subtitle:
                    Text(hospital['hospital_code']),

                onTap: () {
                  onSelected(hospital);
                },
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

      selectedHospitalId =
          hospital['id'];

      selectedLat =
          (hospital['latitude'] as num)
              .toDouble();

      selectedLng =
          (hospital['longitude'] as num)
              .toDouble();
    });

    await getRoute(
      hospitalLat!,
      hospitalLng!,
      selectedLat!,
      selectedLng!,
    );

    await loadHospitals();

    mapController.move(
      LatLng(
        selectedLat!,
        selectedLng!,
      ),
      18,
    );
  },
),
            const SizedBox(height: 20),

            TextField(
              controller: timeLimitController,
              decoration: InputDecoration(
                labelText: "Time Limit (Minutes)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),
            

            DropdownButtonFormField<String>(
              value: selectedDriverId,

              decoration: InputDecoration(
                labelText: "Assign Driver",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              items: drivers.map((driver) {
                return DropdownMenuItem<String>(
                  value: driver['id'],
                  child: Text(driver['name']),
                );
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedDriverId = value;
                });
              },
            ),
            const SizedBox(height: 20),
           DropdownButtonFormField<String>(
  value: selectedAmbulanceId,

  decoration: InputDecoration(
    labelText: "Assign Ambulance",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),

  items: ambulances.map((ambulance) {
    return DropdownMenuItem<String>(
      value: ambulance['id'],
      child: Text(
  ambulance['vehicle_name'],
),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      selectedAmbulanceId = value;
    });
  },
),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                onPressed: isLoading ? null : createMission,

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "CREATE MISSION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
