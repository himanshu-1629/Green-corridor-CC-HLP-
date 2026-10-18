import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC9hjRrTZQaSWwfIH6te5N9FriSaXmmrzo',
    appId: '1:576803754283:web:fab1fbcd8a7f862e7a756e',
    messagingSenderId: '576803754283',
    projectId: 'green-corridor-web',
    authDomain: 'green-corridor-web.firebaseapp.com',
    storageBucket: 'green-corridor-web.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAet_WFvwTxeRI5jwXDrAEIRRueuDHUMhg',
    appId: '1:576803754283:android:034fb35691e9d60e7a756e',
    messagingSenderId: '576803754283',
    projectId: 'green-corridor-web',
    storageBucket: 'green-corridor-web.firebasestorage.app',
  );
}
