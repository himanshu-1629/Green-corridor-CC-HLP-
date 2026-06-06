import 'package:flutter/material.dart';
import 'mission_details_screen.dart';

class MissionCenterScreen extends StatelessWidget {
  const MissionCenterScreen({super.key});

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

              child: ListView(
                children: [

                  _clickableMission(
                    context,
                    _missionCard(
                      missionId: "MIS1001",
                      type: "Heart Transport",
                      destination: "Sahyadri Hospital",
                      driver: "Rahul Patil",
                      ambulance: "AMB1001",
                      status: "Pending",
                    ),
                  ),

                  const SizedBox(height: 15),

                  _clickableMission(
                    context,
                    _missionCard(
                      missionId: "MIS1002",
                      type: "Blood Transport",
                      destination: "Apollo Hospital",
                      driver: "Amit Sharma",
                      ambulance: "AMB1002",
                      status: "In Transit",
                    ),
                  ),

                  const SizedBox(height: 15),

                  _clickableMission(
                    context,
                    _missionCard(
                      missionId: "MIS1003",
                      type: "Patient Transfer",
                      destination: "Ruby Hall Clinic",
                      driver: "Suresh Patil",
                      ambulance: "AMB1003",
                      status: "Completed",
                    ),
                  ),
                ],
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