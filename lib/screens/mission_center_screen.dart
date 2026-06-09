import 'package:flutter/material.dart';
import 'mission_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class MissionCenterScreen extends StatefulWidget {
  const MissionCenterScreen({super.key});

  @override
  State<MissionCenterScreen> createState() =>
      _MissionCenterScreenState();
}

class _MissionCenterScreenState
    extends State<MissionCenterScreen> {
      List missions = [];
bool isLoading = true;
List drivers = [];
String? selectedDriverId;
Future<void> loadMissions() async {
  final data = await Supabase.instance.client
      .from('missions')
      .select()
      .order('created_at', ascending: false);

  setState(() {
    missions = data;
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
    drivers = data;
  });
}

@override
void initState() {
  super.initState();
  loadMissions();
  loadDrivers();
}
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),

        appBar: AppBar(
          title: const Text("Mission Center"),
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,

          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.outbox),
                text: "Outgoing",
              ),
              Tab(
                icon: Icon(Icons.inbox),
                text: "Incoming",
              ),
            ],
          ),
        ),

        body: TabBarView(
          children: [

            // OUTGOING MISSIONS
            Padding(
  padding: const EdgeInsets.all(20),

  child: isLoading
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : ListView.builder(
          itemCount: missions.length,
          itemBuilder: (context, index) {

            final mission = missions[index];

            return Padding(
  padding: const EdgeInsets.only(
    bottom: 15,
  ),

  child: Column(
    children: [

      _missionCard(
        missionId:
            mission['id']
                .toString()
                .substring(0, 8),

        type:
            mission['patient_name']
                .toString(),

        destination:
            mission['destination']
                .toString(),

        driver:
            mission['driver_id'] == null
                ? 'Not Assigned'
                : 'Assigned',

        ambulance:
            mission['pickup_location']
                .toString(),

        status:
            mission['status']
                .toString(),
      ),

      if (mission['driver_id'] == null)
        Padding(
          padding: const EdgeInsets.only(top: 10),

          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: const Text(
                      "Assign Driver",
                    ),

                    content:
                        DropdownButtonFormField<String>(
                      items: drivers.map((driver) {
                        return DropdownMenuItem<String>(
                          value: driver['id'],
                          child: Text(
                            driver['name'],
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        selectedDriverId = value;
                      },
                    ),

                    actions: [
                      TextButton(
                        onPressed: () async {

                          await Supabase.instance.client
                              .from('missions')
                              .update({
                            'driver_id':
                                selectedDriverId,

                            'status':
                                'Assigned',
                          })
                          
                              .eq(
                            'id',
                            mission['id'],
                          );await Supabase.instance.client
    .from('missions')
    .update({
      'driver_id': selectedDriverId,
      'status': 'Assigned',
    })
    .eq('id', mission['id']);
                          

                          Navigator.pop(context);

                          loadMissions();
                        },

                        child:
                            const Text("Assign"),
                      ),
                    ],
                  );
                },
              );
            },

            child: const Text(
              "ASSIGN DRIVER",
            ),
          ),
        ),
    ],
  ),
);
          },
        ),
),

            // INCOMING MISSIONS
            Padding(
              padding: const EdgeInsets.all(20),

              child: ListView(
                children: [

                  _clickableMission(
                    context,
                    _incomingMissionCard(
                      missionId: "MIS2001",
                      type: "Kidney Transport",
                      source: "Apollo Hospital",
                      driver: "Rahul Patil",
                      eta: "25 mins",
                      status: "Incoming",
                    ),
                  ),

                  const SizedBox(height: 15),

                  _clickableMission(
                    context,
                    _incomingMissionCard(
                      missionId: "MIS2002",
                      type: "Patient Transfer",
                      source: "AIIMS Delhi",
                      driver: "Amit Sharma",
                      eta: "40 mins",
                      status: "Incoming",
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

  static Widget _clickableMission(
    BuildContext context,
    Widget child,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MissionDetailsScreen(),
          ),
        );
      },

      child: child,
    );
  }

  static Widget _missionCard({
    required String missionId,
    required String type,
    required String destination,
    required String driver,
    required String ambulance,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Text(
                missionId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              _statusChip(status),
            ],
          ),

          const SizedBox(height: 15),

          Text("Mission Type: $type"),
          const SizedBox(height: 5),

          Text("Destination: $destination"),
          const SizedBox(height: 5),

          Text("Driver: $driver"),
          const SizedBox(height: 5),

          Text("Ambulance: $ambulance"),
        ],
      ),
    );
  }

  static Widget _incomingMissionCard({
    required String missionId,
    required String type,
    required String source,
    required String driver,
    required String eta,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            missionId,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text("Mission Type: $type"),
          const SizedBox(height: 5),

          Text("Source Hospital: $source"),
          const SizedBox(height: 5),

          Text("Driver: $driver"),
          const SizedBox(height: 5),

          Text("ETA: $eta"),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              status,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case "Pending":
        color = Colors.orange;
        break;

      case "In Transit":
        color = Colors.blue;
        break;

      case "Completed":
        color = Colors.green;
        break;

      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}