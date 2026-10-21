import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';
import 'citizen_alert_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _emergencyChannel = AndroidNotificationChannel(
  'emergency_corridor_siren_v3',
  '🚨 Emergency Green Corridor Siren',
  description: 'Urgent sirens when an emergency medical transport approaches your road.',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('emergency_siren'),
  enableVibration: true,
  enableLights: true,
);

/// Top-level background isolate handler when app is CLOSED or KILLED.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  debugPrint("Handling background push notification: ${message.messageId}");


  final data = message.data;
  final String? eventType = data['event_type'];
  final String? sound = data['sound'];
  final bool isDriverStart = eventType == 'driver_started' || sound == 'emergency_siren';

  final String? routeStr = data['route_points'];
  final String plate = data['vehicle_number'] ?? data['ambulance_code'] ?? data['plate_number'] ?? 'Emergency Unit';
  final String dest = data['destination'] ?? 'Hospital';
  final String patient = data['patient_name'] ?? data['organ'] ?? 'Emergency Patient';

  List<LatLng> routePoints = [];
  if (routeStr != null) {
    try {
      final List raw = jsonDecode(routeStr);
      routePoints = raw.map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();
    } catch (e) {
      debugPrint("Error parsing route in background push: $e");
    }
  }

  // 1. Silently acquire current phone GPS location if available
  Position? currentPos;
  try {
    currentPos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 3),
      ),
    );
  } catch (e) {
    debugPrint("Background GPS check note: $e");
  }

  // 2. Check distance to route
  bool isOnRoute = false;
  String notificationTitle;
  String notificationBody;

  if (isDriverStart) {
    notificationTitle = "🚨 EMERGENCY GREEN CORRIDOR IN MOTION!";
    notificationBody = "Ambulance $plate has departed transporting $patient and is en route to $dest! Clear the left lane immediately!";

    if (currentPos != null && routePoints.isNotEmpty) {
      final distToRoute = _calculateDistanceToRoute(
        LatLng(currentPos.latitude, currentPos.longitude),
        routePoints,
      );
      if (distToRoute <= 400.0) {
        isOnRoute = true;
        notificationTitle = "🚨 EMERGENCY CORRIDOR ON YOUR ROAD!";
        notificationBody = "Ambulance $plate is approaching towards $dest. Safely pull over to the left lane immediately!";
      } else if (distToRoute < 5000.0) {
        final km = (distToRoute / 1000).toStringAsFixed(1);
        notificationBody = "Ambulance $plate en route to $dest ($km km from your area). Stay alert.";
      }
    }
  } else {
    // Scheduled corridor advisory from hospital
    notificationTitle = message.notification?.title ?? "🚑 Green Corridor Scheduled";
    notificationBody = message.notification?.body ?? "Ambulance $plate is scheduled for urgent transfer to $dest. Stand by for siren alerts when convoy departs.";
  }

  // 3. Heads-up notification & siren playback
  if (!kIsWeb) {
    // Only show manual local notification if FCM didn't already display a notification block
    if (message.notification == null) {
      final androidDetails = AndroidNotificationDetails(
        isDriverStart ? 'emergency_corridor_siren_v3' : 'default',
        isDriverStart ? '🚨 Emergency Green Corridor Siren' : 'Green Corridor Updates',
        channelDescription: isDriverStart
            ? 'Urgent sirens when an emergency medical transport approaches your road.'
            : 'Advisories and updates for scheduled green corridors.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Green Corridor Alert',
        fullScreenIntent: isDriverStart,
        category: isDriverStart ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
        sound: isDriverStart ? const RawResourceAndroidNotificationSound('emergency_siren') : null,
        playSound: true,
        enableVibration: true,
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        DateTime.now().millisecond,
        notificationTitle,
        notificationBody,
        notificationDetails,
        payload: 'corridor_alert',
      );
    }

    // Trigger siren sound ONLY when driver has started convoy!
    if (isDriverStart) {
      try {
        CitizenAlertService.triggerProximityAlert(isCritical: isOnRoute);
      } catch (_) {}
    }
  }
}

class PushNotificationService {
  static Future<void> initialize() async {
    // 1. Initialize Firebase Core
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase Core initialized successfully.");
    } catch (e) {
      debugPrint("Firebase initialize error: $e");
    }

    // 2. Setup Local Notification Channel for Android
    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(initSettings);

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_emergencyChannel);
      }
    }

    // 3. Register Background Handler (Native Android/iOS only, Web uses Service Worker)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    // 4. Request Push Notification Permissions
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint("User notification permission status: ${settings.authorizationStatus}");

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint("Notification permission request error: $e");
    }

    // 5. CRITICAL: Automatically subscribe this device to 'emergency_corridor' topic
    // This guarantees that notifications reach the phone even if app is closed and user isn't logged in!
    try {
      await FirebaseMessaging.instance.subscribeToTopic('emergency_corridor');
      debugPrint("✅ Subscribed to FCM topic: emergency_corridor");
    } catch (e) {
      debugPrint("Notice: could not subscribe to topic: $e");
    }

    // 6. Retrieve and save FCM Token for targeted driver alerts
    await refreshAndSaveToken();

    // 7. Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      saveTokenToSupabase(newToken);
    });

    // 8. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");

      final data = message.data;
      final eventType = data['event_type'];
      final sound = data['sound'];
      final isDriverStart = eventType == 'driver_started' || sound == 'emergency_siren';

      // Trigger siren sound immediately ONLY when driver has started convoy!
      if (isDriverStart) {
        CitizenAlertService.triggerProximityAlert(isCritical: true);
      }

      if (!kIsWeb && message.notification != null) {
        _localNotifications.show(
          DateTime.now().millisecond,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              isDriverStart ? 'emergency_corridor_siren_v3' : 'default',
              isDriverStart ? '🚨 Emergency Green Corridor Siren' : 'Green Corridor Updates',
              importance: Importance.max,
              priority: Priority.high,
              sound: isDriverStart ? const RawResourceAndroidNotificationSound('emergency_siren') : null,
              playSound: true,
              enableVibration: true,
            ),
          ),
        );
      }
    });
  }

  static Future<void> refreshAndSaveToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint("Device FCM Token: $token");
        await saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
    }
  }

  static Future<void> saveTokenToSupabase(String token) async {
    // 1. Always register token in device_tokens table (works for guest citizens and logged-in users alike)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      await Supabase.instance.client.from('device_tokens').upsert({
        'token': token,
        'user_id': user?.id,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint("Device token successfully registered in Supabase device_tokens table.");
    } catch (e) {
      debugPrint("Notice: could not upsert to device_tokens: $e");
    }

    // 2. If user is logged in, also update their record in users table
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('users').update({
          'fcm_token': token,
        }).eq('id', user.id);
        debugPrint("FCM token successfully registered in Supabase users table.");
      } catch (e) {
        debugPrint("Notice: could not update 'fcm_token' in users table: $e");
      }
    }
  }

  /// Broadcast emergency corridor alert via Supabase Edge Function
  static Future<bool> broadcastMissionAlert({
    required String missionId,
    required String destination,
    required String organOrPatient,
    String? ambulancePlate,
    String? driverId,
    List<LatLng>? routePoints,
    String eventType = 'driver_started',
  }) async {
    try {
      final List<List<double>> routeJson = routePoints != null
          ? routePoints.map((p) => [p.latitude, p.longitude]).toList()
          : [];

      final res = await Supabase.instance.client.functions.invoke(
        'send-corridor-alert',
        body: {
          'mission_id': missionId,
          'patient_name': organOrPatient,
          'organ': organOrPatient,
          'destination': destination,
          'ambulance_plate': ambulancePlate ?? 'Emergency Unit',
          'driver_id': driverId,
          'route_points': routeJson,
          'event_type': eventType,
        },
      );
      debugPrint("send-corridor-alert ($eventType) response: ${res.data}");
      return res.status == 200;
    } catch (e) {
      debugPrint("Error broadcasting corridor alert ($eventType): $e");
      return false;
    }
  }
}

// --- HELPER GEODESIC MATH FOR BACKGROUND ISOLATE ---

double _distanceToSegment(LatLng p, LatLng a, LatLng b) {
  final double x = p.longitude;
  final double y = p.latitude;
  final double x1 = a.longitude;
  final double y1 = a.latitude;
  final double x2 = b.longitude;
  final double y2 = b.latitude;

  final double dx = x2 - x1;
  final double dy = y2 - y1;

  if (dx == 0 && dy == 0) {
    return Geolocator.distanceBetween(y, x, y1, x1);
  }

  final double t = ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy);
  final double clampedT = t.clamp(0.0, 1.0);

  final double projX = x1 + clampedT * dx;
  final double projY = y1 + clampedT * dy;

  return Geolocator.distanceBetween(y, x, projY, projX);
}

double _calculateDistanceToRoute(LatLng userPos, List<LatLng> route) {
  if (route.isEmpty) return double.infinity;
  if (route.length == 1) {
    return Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      route[0].latitude,
      route[0].longitude,
    );
  }

  double minMeters = double.infinity;
  for (int i = 0; i < route.length - 1; i++) {
    final d = _distanceToSegment(userPos, route[i], route[i + 1]);
    if (d < minMeters) {
      minMeters = d;
    }
  }
  return minMeters;
}
