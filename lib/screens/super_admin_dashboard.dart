import 'package:flutter/material.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "System Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child: _statCard(
                    "Hospitals",
                    "25",
                    Icons.local_hospital,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    "Ambulances",
                    "120",
                    Icons.local_shipping,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                Expanded(
                  child: _statCard(
                    "Drivers",
                    "180",
                    Icons.person,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _statCard(
                    "Missions",
                    "42",
                    Icons.assignment,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _actionCard(
              icon: Icons.local_hospital,
              title: "Manage Hospitals",
              subtitle: "View and manage registered hospitals",
            ),

            const SizedBox(height: 12),

            _actionCard(
              icon: Icons.local_shipping,
              title: "Manage Ambulances",
              subtitle: "View all registered ambulances",
            ),

            const SizedBox(height: 12),

            _actionCard(
              icon: Icons.person,
              title: "Manage Drivers",
              subtitle: "View all registered drivers",
            ),

            const SizedBox(height: 12),

            _actionCard(
              icon: Icons.assignment,
              title: "View Missions",
              subtitle: "Monitor all missions in system",
            ),

            const SizedBox(height: 12),

            _actionCard(
              icon: Icons.verified_user,
              title: "Pending Approvals",
              subtitle: "Approve hospitals and registrations",
            ),

            const SizedBox(height: 12),

            _actionCard(
              icon: Icons.analytics,
              title: "Analytics",
              subtitle: "View platform reports and metrics",
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String count,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),

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
        children: [

          Icon(
            icon,
            size: 35,
            color: const Color(0xFFE53935),
          ),

          const SizedBox(height: 10),

          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(title),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
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

      child: Row(
        children: [

          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.red.withOpacity(0.1),

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

          const Icon(
            Icons.arrow_forward_ios,
            size: 18,
          ),
        ],
      ),
    );
  }
}