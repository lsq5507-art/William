// Generated for little-paw-prod — client config (not Admin secrets).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBSJ9ABKjfIEEvBn9ImXWjYY8WIZ-6ndtY',
    appId: '1:850518379973:web:1bbd0431af2f542241cfac',
    messagingSenderId: '850518379973',
    projectId: 'little-paw-prod',
    authDomain: 'little-paw-prod.firebaseapp.com',
    storageBucket: 'little-paw-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkNzdPGj7DhP0QYRCdYJlI9xd7aZK_amI',
    appId: '1:850518379973:android:79b07817b2121d4641cfac',
    messagingSenderId: '850518379973',
    projectId: 'little-paw-prod',
    storageBucket: 'little-paw-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDg8svLKxSOV8EGDYG7cQXZIawQ1xJzaOM',
    appId: '1:850518379973:ios:424fa272a6d7a75141cfac',
    messagingSenderId: '850518379973',
    projectId: 'little-paw-prod',
    storageBucket: 'little-paw-prod.firebasestorage.app',
    iosBundleId: 'com.littlepaw.littlePaw',
  );
}
