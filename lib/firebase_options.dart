// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAprGfvxL8NTzIFUQq7zLaxDrqWIJIGU78',
    appId: '1:919135155684:web:eac7fd02fe75b1a48a83f1',
    messagingSenderId: '919135155684',
    projectId: 'kafegame',
    authDomain: 'kafegame.firebaseapp.com',
    storageBucket: 'kafegame.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgi0GEqAWJJ797trItPmfBSQGBFPunVLo',
    appId: '1:919135155684:android:2fce493bd682340c8a83f1',
    messagingSenderId: '919135155684',
    projectId: 'kafegame',
    storageBucket: 'kafegame.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAsagMM6ZcqURXKGovy6Lm0kOssPha9b1c',
    appId: '1:919135155684:ios:3cc42262d864f1538a83f1',
    messagingSenderId: '919135155684',
    projectId: 'kafegame',
    storageBucket: 'kafegame.firebasestorage.app',
    iosBundleId: 'com.example.kafeGame',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAsagMM6ZcqURXKGovy6Lm0kOssPha9b1c',
    appId: '1:919135155684:ios:3cc42262d864f1538a83f1',
    messagingSenderId: '919135155684',
    projectId: 'kafegame',
    storageBucket: 'kafegame.firebasestorage.app',
    iosBundleId: 'com.example.kafeGame',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAprGfvxL8NTzIFUQq7zLaxDrqWIJIGU78',
    appId: '1:919135155684:web:623e260f8b461da48a83f1',
    messagingSenderId: '919135155684',
    projectId: 'kafegame',
    authDomain: 'kafegame.firebaseapp.com',
    storageBucket: 'kafegame.firebasestorage.app',
  );

}