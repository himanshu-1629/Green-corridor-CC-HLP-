import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  String? selectedMissionType;

  final List<String> missionTypes = [
    "Organ Transport",
    "Patient Transfer",
    "Blood Transport",
    "Body Transfer",
    "Medical Equipment",
  ];

  final List<String> organs = ["Heart", "Liver", "Kidney", "Lungs", "Pancreas"];

  String? selectedOrgan;
  String? selectedDriverId;

  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> hospitals = [];
String? selectedHospitalId;
  final destinationController = TextEditingController();
  final timeLimitController = TextEditingController();
  final ambulanceController = TextEditingController();

  bool isLoading = false;
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
      await Supabase.instance.client.from('missions').insert({
        'patient_name': selectedOrgan ?? selectedMissionType ?? 'Mission',

        'pickup_location': ambulanceController.text.trim(),

        'destination_hospital_id':
    selectedHospitalId,

        'priority': timeLimitController.text.trim(),

        'hospital_id': user?.id,
        'driver_id': selectedDriverId,
        'status': selectedDriverId == null ? 'Pending' : 'Assigned',
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
  setState(() {
    hospitals =
        List<Map<String, dynamic>>.from(data);
  });
}
@override
void initState() {
  super.initState();

  loadDrivers();
  loadHospitals();
}

  @override
  Widget build(BuildContext context) {
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

           DropdownButtonFormField<String>(
  value: selectedHospitalId,

  decoration: InputDecoration(
    labelText: "Destination Hospital",
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  ),

  items: hospitals.map((hospital) {
    return DropdownMenuItem<String>(
      value: hospital['id'],
      child: Text(
        hospital['name'],
      ),
    );
  }).toList(),

  onChanged: (value) {
    setState(() {
      selectedHospitalId = value;
    });
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
            TextField(
              controller: ambulanceController,
              decoration: InputDecoration(
                labelText: "Ambulance ID",
                hintText: "Search Ambulance...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
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
