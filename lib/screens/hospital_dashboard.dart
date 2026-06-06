import 'package:flutter/material.dart';
import 'create_mission_screen.dart';
import 'manage_ambulances_screen.dart';
import 'manage_drivers_screen.dart';
import 'mission_center_screen.dart';
class HospitalDashboard extends StatelessWidget {
  const HospitalDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        title: const Text(
          "Green Corridor",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text(
                "Ruby Hall Clinic",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Good Evening, Admin 👋",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: [

                  Expanded(
                    child: _statCard(
                      icon: Icons.local_hospital,
                      title: "Ambulances",
                      value: "12",
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: _statCard(
                      icon: Icons.assignment,
                      title: "Missions",
                      value: "3",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              _actionCard(
                icon: Icons.add_circle_outline,
                title: "Create Mission",
                subtitle: "Create a new emergency transport mission",
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const CreateMissionScreen(),
    ),
  );
}
              ),

              const SizedBox(height: 15),

              _actionCard(
                icon: Icons.local_shipping,
                title: "Manage Ambulances",
                subtitle: "Register and manage ambulance fleet",
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const ManageAmbulancesScreen(),
    ),
  );
},
              ),

              const SizedBox(height: 15),

              _actionCard(
                icon: Icons.person_outline,
                title: "Manage Drivers",
                subtitle: "Manage driver information",
                onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const ManageDriversScreen(),
    ),
  );
},
              ),
              const SizedBox(height: 15),
_actionCard(
  icon: Icons.assignment_outlined,
  title: "Mission Center",
  subtitle: "View incoming and outgoing missions",
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MissionCenterScreen(),
      ),
    );
  },
),
              const SizedBox(height: 15),

              _actionCard(
                icon: Icons.analytics_outlined,
                title: "Analytics",
                subtitle: "View reports and statistics",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        children: [

          Icon(
            icon,
            size: 40,
            color: const Color(0xFFE53935),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Row(
          children: [

            CircleAvatar(
              radius: 25,
              backgroundColor:
                  const Color(0xFFE53935).withOpacity(0.1),

              child: Icon(
                icon,
                color: const Color(0xFFE53935),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}