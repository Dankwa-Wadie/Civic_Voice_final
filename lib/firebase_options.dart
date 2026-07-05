// File generated manually based on Firebase project config
// Target platform options for Web and Android.

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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBY_nflwOBrMDqnlkUHNKHOyX3AVsw0ZbA',
    appId: '1:1019872630585:web:cda87c733740314df5bae8',
    messagingSenderId: '1019872630585',
    projectId: 'civicvoice-4e96f',
    authDomain: 'civicvoice-4e96f.firebaseapp.com',
    storageBucket: 'civicvoice-4e96f.firebasestorage.app',
    measurementId: 'G-RTM8GD3EXZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-jifhinm7t9439ZxiIzEXjG9o6dKFY1Y',
    appId: '1:1019872630585:android:e35b9a0694e80e2ef5bae8',
    messagingSenderId: '1019872630585',
    projectId: 'civicvoice-4e96f',
    storageBucket: 'civicvoice-4e96f.firebasestorage.app',
  );
}
