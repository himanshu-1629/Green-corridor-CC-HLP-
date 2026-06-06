import 'package:flutter/material.dart';

class CreateMissionScreen extends StatefulWidget {
  const CreateMissionScreen({super.key});

  @override
  State<CreateMissionScreen> createState() =>
      _CreateMissionScreenState();
}

class _CreateMissionScreenState
    extends State<CreateMissionScreen> {

  String? selectedMissionType;

  final List<String> missionTypes = [
    "Organ Transport",
    "Patient Transfer",
    "Blood Transport",
    "Body Transfer",
    "Medical Equipment",
  ];

  final List<String> organs = [
    "Heart",
    "Liver",
    "Kidney",
    "Lungs",
    "Pancreas",
  ];

  String? selectedOrgan;

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
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Mission Type",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: missionTypes.map((type) {

                bool selected =
                    selectedMissionType == type;

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

            if (selectedMissionType ==
                "Organ Transport")
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Organ Type",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField(
                    value: selectedOrgan,

                    decoration:
                        const InputDecoration(
                      border:
                          OutlineInputBorder(),
                    ),

                    items: organs.map((organ) {
                      return DropdownMenuItem(
                        value: organ,
                        child: Text(organ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setState(() {
                        selectedOrgan =
                            value.toString();
                      });
                    },
                  ),
                ],
              ),

            const SizedBox(height: 25),

            TextField(
              decoration: InputDecoration(
                labelText:
                    "Destination Hospital",
                hintText:
                    "Search Hospital...",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                labelText:
                    "Time Limit (Minutes)",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                labelText:
                    "Ambulance ID",
                hintText:
                    "Search Ambulance...",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,

              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFE53935),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            15),
                  ),
                ),

                onPressed: () {},

                child: const Text(
                  "CREATE MISSION",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
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