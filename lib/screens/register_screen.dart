import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../theme/app_theme.dart';

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

  String selectedRole = "Hospital Admin";
  bool isLoading = false;
  bool isLocating = false;
  bool obscurePassword = true;

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    setState(() {
      isLocating = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition();
      latitudeController.text = position.latitude.toStringAsFixed(6);
      longitudeController.text = position.longitude.toStringAsFixed(6);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLocating = false;
        });
      }
    }
  }

  Future<void> registerUser() async {
    try {
      if (selectedRole == "Hospital Admin") {
        if (addressController.text.trim().isEmpty ||
            latitudeController.text.trim().isEmpty ||
            longitudeController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please enter hospital address and GPS coordinates"),
            ),
          );
          return;
        }

        if (double.tryParse(latitudeController.text.trim()) == null ||
            double.tryParse(longitudeController.text.trim()) == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Latitude and Longitude must be valid numbers"),
            ),
          );
          return;
        }
      }

      setState(() {
        isLoading = true;
      });

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception("Signup failed. Check details or email format.");
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
        } else if (words.length == 2) {
          prefix = words[0].substring(0, min(2, words[0].length)).toUpperCase() +
              words[1][0].toUpperCase();
        } else {
          prefix = words[0][0].toUpperCase() +
              words[1][0].toUpperCase() +
              words[2][0].toUpperCase();
        }

        final hospitals = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('role', 'Hospital Admin');

        final nextNumber = hospitals.length + 1;
        hospitalCode = '$prefix${nextNumber.toString().padLeft(3, '0')}';
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
          content: Text("Account Created Successfully! Please login."),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHospital = selectedRole == "Hospital Admin";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: AppColors.slate900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(32),
            decoration: AppDecorations.cardElevated(radius: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Text(
                  "Join Green Corridor",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Register your healthcare facility or join as a citizen",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 28),

                // Role Segmented Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _roleOption(
                          title: "Hospital Admin",
                          icon: Icons.local_hospital_rounded,
                          isSelected: isHospital,
                          onTap: () => setState(() => selectedRole = "Hospital Admin"),
                        ),
                      ),
                      Expanded(
                        child: _roleOption(
                          title: "Citizen",
                          icon: Icons.person_rounded,
                          isSelected: !isHospital,
                          onTap: () => setState(() => selectedRole = "Citizen"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name / Hospital Name
                TextField(
                  controller: nameController,
                  decoration: AppDecorations.input(
                    labelText: isHospital ? "Hospital / Facility Name" : "Full Name",
                    hintText: isHospital ? "e.g. Apollo Hospital" : "e.g. John Doe",
                    prefixIcon: Icon(
                      isHospital ? Icons.domain_rounded : Icons.person_outline_rounded,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AppDecorations.input(
                    labelText: "Email Address",
                    hintText: "contact@domain.com",
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Phone
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: AppDecorations.input(
                    labelText: "Contact Phone Number",
                    hintText: "+91 98765 43210",
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: AppDecorations.input(
                    labelText: "Account Password",
                    hintText: "••••••••",
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.slate400,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.slate400,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                // Hospital Specific Fields
                if (isHospital) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        "Hospital Geolocation",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: addressController,
                    decoration: AppDecorations.input(
                      labelText: "Complete Hospital Address",
                      hintText: "Street, Area, City, PIN",
                      prefixIcon: const Icon(
                        Icons.place_outlined,
                        color: AppColors.slate400,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detect GPS Button
                  InkWell(
                    onTap: isLocating ? null : getCurrentLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLocating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.emeraldDark),
                              ),
                            )
                          else
                            const Icon(Icons.my_location_rounded, size: 18, color: AppColors.emeraldDark),
                          const SizedBox(width: 8),
                          Text(
                            isLocating ? "Fetching Coordinates..." : "Fetch Current GPS Coordinates",
                            style: const TextStyle(
                              color: AppColors.emeraldDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latitudeController,
                          readOnly: true,
                          decoration: AppDecorations.input(
                            labelText: "Latitude",
                            prefixIcon: const Icon(Icons.north_rounded, size: 16, color: AppColors.slate400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: longitudeController,
                          readOnly: true,
                          decoration: AppDecorations.input(
                            labelText: "Longitude",
                            prefixIcon: const Icon(Icons.east_rounded, size: 16, color: AppColors.slate400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Submit Button
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppGradients.emergency,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading ? null : registerUser,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "CREATE ACCOUNT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.slate900.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.slate500,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.slate900 : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}