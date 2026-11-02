import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';
import 'services/push_notification_service.dart';
import 'supabase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/dialkit_tuning_panel.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail-safe initialization: App must always render even under intermittent network failure
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e) {
    debugPrint("Supabase initialization notice: $e");
  }

  // Initialize Firebase and background push notification channels safely
  try {
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Push notification init notice: $e");
  }

  try {
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        debugPrint("AUTH EVENT => ${data.event}");
        if (data.event == AuthChangeEvent.signedIn) {
          await PushNotificationService.refreshAndSaveToken();
        }
      },
    );
  } catch (e) {
    debugPrint("Auth listener notice: $e");
  }

  // Global Flutter error widget customization (No ugly red screen, clean brand-safe recovery)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: AppColors.softIvory,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.deepViolet.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mutedBerry, width: 1.5),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.deepViolet,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Green Corridor Grid Active',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.nearBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recovering secure interface. Please refresh if needed.',
                style: TextStyle(
                  fontFamily: 'NeueMontreal',
                  fontSize: 13,
                  color: AppColors.nearBlackMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const GreenCorridorApp());
}

class GreenCorridorApp extends StatelessWidget {
  const GreenCorridorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Green Corridor',
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return DialKitTuningOverlay(child: child ?? const SizedBox.shrink());
      },
      home: const AuthGate(),
    );
  }
}