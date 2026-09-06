// Generated Firebase configuration for the MINOVA project.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const placeholderProjectId = 'REPLACE_WITH_REAL_PROJECT_ID';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured.');
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB_3F9iIjsZpSigjiSwfcdk701Wa5nlbL4',
    appId: '1:385566103457:web:385efab09ddca927fd1de0',
    messagingSenderId: '385566103457',
    projectId: 'minova-ef69c',
    authDomain: 'minova-ef69c.firebaseapp.com',
    storageBucket: 'minova-ef69c.firebasestorage.app',
    measurementId: 'G-PBL6B5886P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA02NGCg3zdflJdhzwvhlGQz3x5hwpWCWQ',
    appId: '1:385566103457:android:22b6fac5cdcaa08dfd1de0',
    messagingSenderId: '385566103457',
    projectId: 'minova-ef69c',
    storageBucket: 'minova-ef69c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJZPKuzOVwsDz4aAKwi380oM4211cCZGo',
    appId: '1:385566103457:ios:8a5ddd9697752a62fd1de0',
    messagingSenderId: '385566103457',
    projectId: 'minova-ef69c',
    storageBucket: 'minova-ef69c.firebasestorage.app',
    iosBundleId: 'com.sih26024.minesafe.minesafe',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBJZPKuzOVwsDz4aAKwi380oM4211cCZGo',
    appId: '1:385566103457:ios:8a5ddd9697752a62fd1de0',
    messagingSenderId: '385566103457',
    projectId: 'minova-ef69c',
    storageBucket: 'minova-ef69c.firebasestorage.app',
    iosBundleId: 'com.sih26024.minesafe.minesafe',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB_3F9iIjsZpSigjiSwfcdk701Wa5nlbL4',
    appId: '1:385566103457:web:962d71c3fafbb74dfd1de0',
    messagingSenderId: '385566103457',
    projectId: 'minova-ef69c',
    authDomain: 'minova-ef69c.firebaseapp.com',
    storageBucket: 'minova-ef69c.firebasestorage.app',
    measurementId: 'G-E0W36LLFCM',
  );
}
