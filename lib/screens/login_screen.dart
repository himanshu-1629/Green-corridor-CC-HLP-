
import 'driver_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'hospital_dashboard.dart';
import 'package:flutter/material.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = "Hospital Admin";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),

              padding: const EdgeInsets.all(30),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Icon(
                    Icons.lock_outline,
                    size: 70,
                    color: Color(0xFFE53935),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Welcome",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Secure access for authorized personnel",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  DropdownButtonFormField(
                    value: selectedRole,

                    decoration: InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    items: const [

                      DropdownMenuItem(
                        value: "Hospital Admin",
                        child: Text("Hospital Admin"),
                      ),

                      DropdownMenuItem(
                        value: "Driver",
                        child: Text("Driver"),
                      ),

                      DropdownMenuItem(
                        value: "Super Admin",
                        child: Text("Super Admin"),
                      ),
                    ],

                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    obscureText: true,

                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      onPressed: () {

  if (selectedRole == "Hospital Admin") {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const HospitalDashboard(),
      ),
    );

  } else if (selectedRole == "Driver") {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverDashboard(),
      ),
    );

  } else {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SuperAdminDashboard(),
      ),
    );
  }
},

                      child: const Text(
                        "LOGIN",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}