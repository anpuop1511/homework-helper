// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
//
// ⚠️  IMPORTANT: This file is a placeholder.
//
// To generate your real Firebase options, install the FlutterFire CLI and run:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That will overwrite this file with values tied to your Firebase project.
// Until you do, the app will run in offline/guest-only mode because Firebase
// cannot be initialised with placeholder credentials.

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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Replace every 'REPLACE_WITH_...' value with the ones from your Firebase
  // project (Project Settings → General → Your apps).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: 'REPLACE_WITH_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    authDomain: 'REPLACE_WITH_PROJECT_ID.firebaseapp.com',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAnmpl7UtVbtvf6jROV_9xL1j4luv36X9o',
    appId: '1:911283793659:android:aa8131111c319b0a270a5e',
    messagingSenderId: '911283793659',
    projectId: 'hwhelp-9390f',
    storageBucket: 'hwhelp-9390f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: 'REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.homeworkHelper',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_MACOS_API_KEY',
    appId: 'REPLACE_WITH_MACOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_SENDER_ID',
    projectId: 'REPLACE_WITH_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_PROJECT_ID.firebasestorage.app',
    iosBundleId: 'com.example.homeworkHelper',
  );
}