import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';
import 'services/push_notification_service.dart';
import 'supabase_options.dart';
import 'theme/app_theme.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Initialize Firebase and background push notification channels
  try {
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint("Push notification init notice: $e");
  }

  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) async {
      debugPrint("AUTH EVENT => ${data.event}");
      if (data.event == AuthChangeEvent.signedIn) {
        await PushNotificationService.refreshAndSaveToken();
      }
    },
  );

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
      home: const AuthGate(),
    );
  }
}