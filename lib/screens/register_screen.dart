import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
final addressController = TextEditingController();

final latitudeController = TextEditingController();

final longitudeController = TextEditingController();
Future<void> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enable location services"),
      ),
    );
    return;
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location permission denied"),
      ),
    );
    return;
  }

  final position = await Geolocator.getCurrentPosition();

 latitudeController.text =
    position.latitude.toStringAsFixed(6);

longitudeController.text =
    position.longitude.toStringAsFixed(6);

  setState(() {});
}
  String selectedRole = "Hospital Admin";

  bool isLoading = false;

  Future<void> registerUser() async {
    try {
      if (selectedRole == "Hospital Admin") {
  if (addressController.text.trim().isEmpty ||
      latitudeController.text.trim().isEmpty ||
      longitudeController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please enter hospital location details",
        ),
      ),
    );
    return;
  }
   if (double.tryParse(latitudeController.text.trim()) == null ||
      double.tryParse(longitudeController.text.trim()) == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Latitude and Longitude must be valid numbers",
        ),
      ),
    );
    return;
  }
}


      setState(() {
        isLoading = true;
      });

      final authResponse =
          await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = authResponse.user?.id;

      if (userId == null) {
        throw Exception("Signup failed");
      }
String? hospitalCode;

if (selectedRole == "Hospital Admin") {
 final words = nameController.text
    .trim()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .toList();

String prefix;

if (words.length == 1) {
  prefix = words[0]
      .substring(0, min(3, words[0].length))
      .toUpperCase()
      .padRight(3, 'X');
}
else if (words.length == 2) {
  prefix =
      words[0]
          .substring(0, min(2, words[0].length))
          .toUpperCase() +
      words[1][0].toUpperCase();
}
else {
  prefix =
      words[0][0].toUpperCase() +
      words[1][0].toUpperCase() +
      words[2][0].toUpperCase();
}

 final hospitals = await Supabase.instance.client
    .from('users')
    .select('id')
    .eq('role', 'Hospital Admin');

final nextNumber = hospitals.length + 1;

hospitalCode =
    '$prefix${nextNumber.toString().padLeft(3, '0')}';
}
     await Supabase.instance.client.from('users').insert({
  'id': userId,
  'name': nameController.text.trim(),
  'email': emailController.text.trim(),
  'phone': phoneController.text.trim(),
  'role': selectedRole,
  'hospital_code': hospitalCode,

  'address': selectedRole == "Hospital Admin"
      ? addressController.text.trim()
      : null,

  'latitude': selectedRole == "Hospital Admin"
      ? double.tryParse(latitudeController.text.trim())
      : null,

  'longitude': selectedRole == "Hospital Admin"
      ? double.tryParse(longitudeController.text.trim())
      : null,
});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Created Successfully"),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const SizedBox(height: 20),
             DropdownButtonFormField(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Role",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Hospital Admin",
                  child: Text("Hospital Admin"),
                ),
                
                DropdownMenuItem(
                  value: "Citizen",
                  child: Text("Citizen"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedRole = value!;
                });
              },
            ),
       const SizedBox(height: 15),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
if (selectedRole == "Hospital Admin") ...[
  const SizedBox(height: 15),

  TextField(
    controller: addressController,
    decoration: const InputDecoration(
      labelText: "Hospital Address",
      border: OutlineInputBorder(),
    ),
  ),
const SizedBox(height: 10),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: getCurrentLocation,
    icon: const Icon(Icons.location_on),
    label: const Text(
      "Use Current Location",
    ),
  ),
),
  const SizedBox(height: 15),

  TextField(
    controller: latitudeController,
      readOnly: true,
    keyboardType: const TextInputType.numberWithOptions(
  decimal: true,
),
    decoration: const InputDecoration(
      labelText: "Latitude",
      border: OutlineInputBorder(),
    ),
  ),

  const SizedBox(height: 15),

  TextField(
    controller: longitudeController,
      readOnly: true,
    keyboardType: const TextInputType.numberWithOptions(
  decimal: true,
),
    decoration: const InputDecoration(
      labelText: "Longitude",
      border: OutlineInputBorder(),
    ),
  ),
],
            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

          

           
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          color: Colors.white,
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