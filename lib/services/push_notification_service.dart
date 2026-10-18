import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../firebase_options.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _emergencyChannel = AndroidNotificationChannel(
  'emergency_corridor_channel',
  '🚨 Emergency Green Corridor Alerts',
  description: 'Urgent sirens when an emergency medical transport approaches your road.',
  importance: Importance.max,
  playSound: true,
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
  final String? routeStr = data['route_points'];
  final String plate = data['vehicle_number'] ?? data['ambulance_code'] ?? data['plate_number'] ?? 'Emergency Unit';
  final String dest = data['destination'] ?? 'Hospital';

  List<LatLng> routePoints = [];
  if (routeStr != null) {
    try {
      final List raw = jsonDecode(routeStr);
      routePoints = raw.map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble())).toList();
    } catch (e) {
      debugPrint("Error parsing route in background push: $e");
    }
  }

  // 1. Silently acquire current phone GPS location
  Position? currentPos;
  try {
    currentPos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 4),
      ),
    );
  } catch (e) {
    debugPrint("Background GPS check error: $e");
  }

  // 2. Check if the user is physically on the corridor path
  bool isInCorridorPath = false;
  if (currentPos != null && routePoints.isNotEmpty) {
    final distToRoute = _calculateDistanceToRoute(
      LatLng(currentPos.latitude, currentPos.longitude),
      routePoints,
    );
    // User must be within 250m lateral distance of the route
    if (distToRoute <= 250.0) {
      isInCorridorPath = true;
    }
  } else if (routePoints.isEmpty) {
    // If no route coordinates provided in payload, default to showing the alert
    isInCorridorPath = true;
  }

  // 3. If in path, trigger loud heads-up emergency notification!
  // If NOT in path, drop silently so people far away are not disturbed.
  if (isInCorridorPath && !kIsWeb) {
    const androidDetails = AndroidNotificationDetails(
      'emergency_corridor_channel',
      '🚨 Emergency Green Corridor Alerts',
      channelDescription: 'Urgent sirens when an emergency medical transport approaches your road.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Green Corridor Alert',
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      "🚨 EMERGENCY CORRIDOR ON YOUR ROAD!",
      "Ambulance $plate is approaching towards $dest. Safely pull over to the left lane immediately!",
      notificationDetails,
      payload: 'corridor_alert',
    );
  } else {
    debugPrint("User is OFF-PATH (${currentPos?.latitude}, ${currentPos?.longitude}). Background push ignored.");
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
    } catch (e) {
      debugPrint("Notification permission request error: $e");
    }

    // 5. Retrieve and save FCM Token
    await refreshAndSaveToken();

    // 6. Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      saveTokenToSupabase(newToken);
    });

    // 7. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.notification?.title}");
      if (!kIsWeb && message.notification != null) {
        _localNotifications.show(
          DateTime.now().millisecond,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'emergency_corridor_channel',
              '🚨 Emergency Green Corridor Alerts',
              importance: Importance.max,
              priority: Priority.high,
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('users').update({
        'fcm_token': token,
      }).eq('id', user.id);
      debugPrint("FCM token successfully registered in Supabase users table.");
    } catch (e) {
      // Graceful catch if the column 'fcm_token' has not yet been added in Supabase
      debugPrint("Notice: could not update 'fcm_token' in users table: $e");
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
