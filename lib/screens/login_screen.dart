import 'forgot_password_screen.dart';
import 'driver_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'hospital_dashboard.dart';
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'citizen_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
 Future<void> loginUser() async {
  try {
    setState(() {
      isLoading = true;
    });

    final response =
        await Supabase.instance.client.auth.signInWithPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final userId = response.user?.id;

    if (userId == null) {
      throw Exception("Login failed");
    }

    final userData = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    final role = userData['role'];

    if (!mounted) return;

    if (role == "Hospital Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HospitalDashboard(),
        ),
      );
    } else if (role == "Driver") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DriverDashboard(),
        ),
      );
    } else if (role == "Citizen") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CitizenScreen(),
        ),
      );
    } else if (role == "Super Admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SuperAdminDashboard(),
        ),
      );
    } else {
      throw Exception("Unknown role");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Invalid email or password",
        ),
      ),
    );
  }

  if (mounted) {
    setState(() {
      isLoading = false;
    });
  }
}
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

                  
                  const SizedBox(height: 20),

                  TextField(
  controller: emailController,
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
  controller: passwordController,
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

                      onPressed: isLoading ? null : loginUser,
                      child: isLoading
    ? const CircularProgressIndicator(
        color: Colors.white,
      )
    : const Text(
        "LOGIN",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
                    ),
                  ),
                  
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ForgotPasswordScreen(),
      ),
    );
  },
  child: const Text(
    "Forgot Password?",
  ),
),

const SizedBox(height: 10),
                  TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  },
  child: const Text(
    "Create New Account",
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