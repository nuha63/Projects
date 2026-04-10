// This file provides mock Firebase options for web environment
// It allows the app to compile and run on web without requiring Firebase JS SDK

import 'package:KitchenCraft/features/auth/data/web_firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // Mock Web Firebase configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'mock-api-key-for-web',
    appId: 'mock-app-id-for-web',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-storage-bucket',
  );

  // Mock Android Firebase configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'mock-api-key-for-android',
    appId: 'mock-app-id-for-android',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-storage-bucket',
  );

  // Mock iOS Firebase configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'mock-api-key-for-ios',
    appId: 'mock-app-id-for-ios',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-storage-bucket',
  );

  // Mock macOS Firebase configuration
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'mock-api-key-for-macos',
    appId: 'mock-app-id-for-macos',
    messagingSenderId: 'mock-sender-id',
    projectId: 'mock-project-id',
    storageBucket: 'mock-storage-bucket',
  );
}